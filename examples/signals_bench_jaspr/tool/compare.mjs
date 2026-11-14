// Compares the Kelicap and the Jaspr signals benchmarks, in one headless
// Chrome, through the DevTools protocol.
//
// Usage:
//   node tool/compare.mjs speed <Kelicap build> <Jaspr build> [rounds] [rows...]
//   node tool/compare.mjs memory <Kelicap build> <Jaspr build> [runs] [query...]
//   node tool/compare.mjs size <Kelicap build> <Jaspr build>
//
// The builds are release builds of ../signals_bench and of this project, such
// as /tmp/signals_bench and /tmp/signals_bench_jaspr, or of any two apps whose
// page is index.html and whose JavaScript is main.dart.js.
//
// - speed runs both benchmarks alternately, with `?autorun&rows=<rows>`, and
//   prints the median of the rounds of each.
// - memory loads `index.html?<query>` in a new browser context, collects
//   garbage, and prints the median JavaScript heap and the DOM nodes. The
//   default queries are `rows=10000`, `rows=10000&show=fields` and
//   `rows=10000&show=signals`.
// - size prints the size of main.dart.js, raw, gzip -9 and Brotli 11.
//
// Set CHROME to the Chrome executable, if it is not `google-chrome`.
import {spawn} from 'node:child_process';
import {mkdtempSync, readFileSync, rmSync, statSync} from 'node:fs';
import {createServer} from 'node:http';
import {tmpdir} from 'node:os';
import {extname, join, normalize, resolve} from 'node:path';
import {brotliCompressSync, constants, gzipSync} from 'node:zlib';

const [command, kelicapDir, jasprDir, countArg, ...rest] = process.argv.slice(2);
if (!['speed', 'memory', 'size'].includes(command) || !kelicapDir || !jasprDir) {
  console.error(
    'Usage: node tool/compare.mjs speed|memory|size <Kelicap build> <Jaspr build> [rounds] [rows or queries...]',
  );
  process.exit(64);
}
const builds = {Kelicap: resolve(kelicapDir), Jaspr: resolve(jasprDir)};
const names = Object.keys(builds);

const median = (values) => {
  const sorted = [...values].sort((a, b) => a - b);
  return sorted[Math.floor(sorted.length / 2)];
};
const sleep = (ms) => new Promise((done) => setTimeout(done, ms));
const kb = (bytes) => `${(bytes / 1024).toFixed(1)} KB`;

if (command === 'size') {
  console.log('| Framework | Raw | gzip | Brotli |');
  console.log('| --- | --- | --- | --- |');
  for (const [name, dir] of Object.entries(builds)) {
    const js = readFileSync(join(dir, 'main.dart.js'));
    const gzip = gzipSync(js, {level: 9}).length;
    const brotli = brotliCompressSync(js, {
      params: {[constants.BROTLI_PARAM_QUALITY]: 11},
    }).length;
    console.log(`| ${name} | ${kb(js.length)} | ${kb(gzip)} | ${kb(brotli)} |`);
  }
  process.exit(0);
}

const types = {'.html': 'text/html', '.js': 'text/javascript', '.css': 'text/css'};

/** Serves the files of `root` on a free port of 127.0.0.1. */
async function serve(root) {
  const server = createServer((request, response) => {
    const path = normalize(decodeURIComponent(new URL(request.url, 'http://x').pathname));
    const file = join(root, path);
    try {
      if (!file.startsWith(root) || !statSync(file).isFile()) throw new Error();
      response.writeHead(200, {
        'content-type': types[extname(file)] ?? 'application/octet-stream',
      });
      response.end(readFileSync(file));
    } catch {
      response.writeHead(404).end();
    }
  });
  await new Promise((done) => server.listen(0, '127.0.0.1', done));
  return server;
}

/** Starts headless Chrome, and returns it with its debugging port. */
async function startChrome(profile) {
  const port = 9300 + Math.floor(Math.random() * 600);
  const chrome = spawn(
    process.env.CHROME ?? 'google-chrome',
    [
      '--headless=new',
      '--disable-gpu',
      '--no-first-run',
      `--user-data-dir=${profile}`,
      `--remote-debugging-port=${port}`,
      'about:blank',
    ],
    {stdio: 'ignore'},
  );
  // A new profile can take Chrome half a minute to start.
  for (let tries = 0; tries < 600; tries++) {
    try {
      await fetch(`http://127.0.0.1:${port}/json/version`);
      return {chrome, port};
    } catch {
      await sleep(200);
    }
  }
  chrome.kill();
  throw new Error('Chrome did not start');
}

/** Connects to the DevTools WebSocket at `url`, and returns `send`. */
async function connect(url) {
  const ws = new WebSocket(url);
  await new Promise((done) => ws.addEventListener('open', done));
  let id = 0;
  const pending = new Map();
  const errors = [];
  ws.addEventListener('message', ({data}) => {
    const message = JSON.parse(data);
    if (pending.has(message.id)) {
      pending.get(message.id)(message);
      pending.delete(message.id);
    } else if (message.method === 'Runtime.exceptionThrown') {
      const details = message.params.exceptionDetails;
      errors.push(details.exception?.description ?? details.text);
    }
  });
  const send = (method, params = {}, sessionId) =>
    new Promise((done) => {
      pending.set(++id, done);
      ws.send(JSON.stringify({id, method, params, sessionId}));
    });
  const evaluate = async (expression, sessionId) =>
    (await send('Runtime.evaluate', {expression, returnByValue: true}, sessionId))
      .result?.result?.value;
  return {ws, send, evaluate, errors};
}

const servers = {};
for (const [name, dir] of Object.entries(builds)) servers[name] = await serve(dir);
const pageUrl = (name, query) =>
  `http://127.0.0.1:${servers[name].address().port}/index.html?${query}`;
const profile = mkdtempSync(join(tmpdir(), 'signals-bench-chrome-'));
const {chrome, port} = await startChrome(profile);
const {webSocketDebuggerUrl} = await (
  await fetch(`http://127.0.0.1:${port}/json/version`)
).json();
const browser = await connect(webSocketDebuggerUrl);

/**
 * Opens `url` in a new tab of a new browser context, runs `measure` with the
 * tab's session, and closes them, or throws the page's first error.
 */
async function withPage(url, measure) {
  const {send, errors} = browser;
  const {browserContextId} = (await send('Target.createBrowserContext')).result;
  const {targetId} = (
    await send('Target.createTarget', {url: 'about:blank', browserContextId})
  ).result;
  const {sessionId} = (
    await send('Target.attachToTarget', {targetId, flatten: true})
  ).result;
  errors.length = 0;
  try {
    await send('Runtime.enable', {}, sessionId);
    await send('Page.navigate', {url}, sessionId);
    return await measure(sessionId, () => {
      if (errors.length > 0) throw new Error(errors[0]);
    });
  } finally {
    await send('Target.closeTarget', {targetId});
    await send('Target.disposeBrowserContext', {browserContextId});
  }
}

/** Returns the results of a benchmark page, the JSON of `#results`. */
const runBenchmark = (url) =>
  withPage(url, async (sessionId, check) => {
    for (let waited = 0; waited < 1800000; waited += 500) {
      await sleep(500);
      check();
      const text = await browser.evaluate(
        `document.querySelector('#results')?.textContent ?? ''`,
        sessionId,
      );
      if (text) return JSON.parse(text);
    }
    throw new Error(`No results from ${url}`);
  });

/** Returns the JavaScript heap of a page, once loaded, and its DOM nodes. */
const measureMemory = (url) =>
  withPage(url, async (sessionId, check) => {
    for (let waited = 0; ; waited += 200) {
      await sleep(200);
      check();
      const ready = await browser.evaluate(
        `document.readyState === 'complete'`,
        sessionId,
      );
      if (ready) break;
      if (waited > 60000) throw new Error(`${url} did not load`);
    }
    // Lets the app render, and any work it scheduled run.
    await sleep(1000);
    check();
    for (let i = 0; i < 3; i++) {
      await browser.send('HeapProfiler.collectGarbage', {}, sessionId);
    }
    const heap = (await browser.send('Runtime.getHeapUsage', {}, sessionId))
      .result.usedSize;
    const nodes = await browser.evaluate(
      `(() => {
        const walker = document.createTreeWalker(document, NodeFilter.SHOW_ALL);
        let count = 0;
        while (walker.nextNode()) count++;
        return count;
      })()`,
      sessionId,
    );
    return {heap, nodes};
  });

try {
  if (command === 'speed') {
    const rounds = Number(countArg ?? '3');
    const rowCounts = rest.length > 0 ? rest : ['1000', '10000'];
    const scenarios = ['Update one row', 'Update all rows', 'No change'];
    const modes = ['fields', 'signals'];
    /** Results by `rows|scenario|mode|framework`: means, and rows checked. */
    const results = new Map();
    for (const rows of rowCounts) {
      for (let round = 0; round < rounds; round++) {
        // Alternates the frameworks, so that both see the same machine load.
        for (const name of names) {
          for (const result of await runBenchmark(pageUrl(name, `autorun&rows=${rows}`))) {
            const key = [rows, result.scenario, result.mode, name].join('|');
            const entry = results.get(key) ?? {means: [], checked: result.rowsCheckedPerOp};
            entry.means.push(result.meanMs);
            results.set(key, entry);
          }
        }
      }
    }
    for (const rows of rowCounts) {
      console.log(
        `\n${rows} rows: the mean time of an operation, in ms, the median of ${rounds} runs, and the rows it checked\n`,
      );
      console.log(`| Scenario | Mode | ${names.join(' | ')} |`);
      console.log(`| --- | --- |${' --- |'.repeat(names.length)}`);
      for (const scenario of scenarios) {
        for (const mode of modes) {
          const cells = names.map((name) => {
            const entry = results.get([rows, scenario, mode, name].join('|'));
            return entry
              ? `${median(entry.means).toFixed(3)} (${Math.round(entry.checked)})`
              : '-';
          });
          console.log(`| ${scenario} | ${mode} | ${cells.join(' | ')} |`);
        }
      }
    }
  } else {
    const runs = Number(countArg ?? '3');
    const queries =
      rest.length > 0
        ? rest
        : ['rows=10000', 'rows=10000&show=fields', 'rows=10000&show=signals'];
    console.log(
      `\nThe JavaScript heap after garbage collection, the median of ${runs} runs, and the DOM nodes\n`,
    );
    console.log(`| Query | ${names.join(' | ')} |`);
    console.log(`| --- |${' --- |'.repeat(names.length)}`);
    for (const query of queries) {
      const samples = Object.fromEntries(names.map((name) => [name, []]));
      let nodes = {};
      for (let run = 0; run < runs; run++) {
        for (const name of names) {
          const result = await measureMemory(pageUrl(name, query));
          samples[name].push(result.heap);
          nodes[name] = result.nodes;
        }
      }
      const cells = names.map(
        (name) =>
          `${(median(samples[name]) / 1024 / 1024).toFixed(2)} MB, ${nodes[name]} nodes`,
      );
      console.log(`| \`${query}\` | ${cells.join(' | ')} |`);
    }
  }
} finally {
  browser.ws.close();
  chrome.kill();
  for (const server of Object.values(servers)) server.close();
  await sleep(500);
  rmSync(profile, {recursive: true, force: true});
}
