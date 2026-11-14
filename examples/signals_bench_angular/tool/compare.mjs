// Runs the Kelicap and the Angular signals benchmarks alternately, in one
// headless Chrome, and prints the median of the rounds of each.
//
// Usage:
//   node tool/compare.mjs <Kelicap build> <Angular build> [rounds] [rows...]
//
// <Kelicap build> is the release build of ../signals_bench, such as
// /tmp/signals_bench, and <Angular build> that of this project, dist/browser.
// Set CHROME to the Chrome executable, if it is not `google-chrome`.
import {spawn} from 'node:child_process';
import {mkdtempSync, readFileSync, rmSync, statSync} from 'node:fs';
import {createServer} from 'node:http';
import {tmpdir} from 'node:os';
import {extname, join, normalize, resolve} from 'node:path';

const [kelicapDir, angularDir, roundsArg = '3', ...rowsArgs] =
  process.argv.slice(2);
if (!kelicapDir || !angularDir) {
  console.error(
    'Usage: node tool/compare.mjs <Kelicap build> <Angular build> [rounds] [rows...]',
  );
  process.exit(64);
}
const rounds = Number(roundsArg);
const rowCounts = rowsArgs.length > 0 ? rowsArgs : ['1000', '10000'];
const builds = {Kelicap: resolve(kelicapDir), Angular: resolve(angularDir)};
const scenarios = ['Update one row', 'Update all rows', 'No change'];
const modes = ['fields', 'signals'];

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

const sleep = (ms) => new Promise((done) => setTimeout(done, ms));

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

/**
 * Opens `url` in a new tab, waits for the JSON of its `<pre id="results">`,
 * and returns it, or throws the page's first error.
 */
async function runPage(port, url) {
  const target = await (
    await fetch(`http://127.0.0.1:${port}/json/new?about:blank`, {method: 'PUT'})
  ).json();
  const ws = new WebSocket(target.webSocketDebuggerUrl);
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
  const send = (method, params = {}) =>
    new Promise((done) => {
      pending.set(++id, done);
      ws.send(JSON.stringify({id, method, params}));
    });
  try {
    await send('Runtime.enable');
    await send('Page.navigate', {url});
    for (let waited = 0; waited < 600000; waited += 500) {
      await sleep(500);
      if (errors.length > 0) throw new Error(errors[0]);
      const reply = await send('Runtime.evaluate', {
        expression: `document.querySelector('#results')?.textContent ?? ''`,
        returnByValue: true,
      });
      const text = reply.result?.result?.value;
      if (text) return JSON.parse(text);
    }
    throw new Error(`No results from ${url}`);
  } finally {
    await send('Target.closeTarget', {targetId: target.id});
    ws.close();
  }
}

const median = (values) => {
  const sorted = [...values].sort((a, b) => a - b);
  return sorted[Math.floor(sorted.length / 2)];
};

const servers = {};
for (const [name, dir] of Object.entries(builds)) servers[name] = await serve(dir);
const profile = mkdtempSync(join(tmpdir(), 'signals-bench-chrome-'));
const {chrome, port} = await startChrome(profile);

/** Results by `rows|scenario|mode|framework`: means, and rows checked. */
const results = new Map();
try {
  for (const rows of rowCounts) {
    for (let round = 0; round < rounds; round++) {
      // Alternates the frameworks, so that both see the same machine load.
      for (const [name, server] of Object.entries(servers)) {
        const url = `http://127.0.0.1:${server.address().port}/index.html?autorun&rows=${rows}`;
        for (const result of await runPage(port, url)) {
          const key = [rows, result.scenario, result.mode, name].join('|');
          const entry = results.get(key) ?? {means: [], checked: result.rowsCheckedPerOp};
          entry.means.push(result.meanMs);
          results.set(key, entry);
        }
      }
    }
  }
} finally {
  chrome.kill();
  for (const server of Object.values(servers)) server.close();
  await sleep(500);
  rmSync(profile, {recursive: true, force: true});
}

for (const rows of rowCounts) {
  console.log(
    `\n${rows} rows: the mean time of an operation, in ms, the median of ${rounds} runs, and the rows it checked\n`,
  );
  console.log('| Scenario | Mode | Kelicap | Angular |');
  console.log('| --- | --- | --- | --- |');
  for (const scenario of scenarios) {
    for (const mode of modes) {
      const cells = Object.keys(builds).map((name) => {
        const entry = results.get([rows, scenario, mode, name].join('|'));
        return entry
          ? `${median(entry.means).toFixed(3)} (${Math.round(entry.checked)})`
          : '-';
      });
      console.log(`| ${scenario} | ${mode} | ${cells.join(' | ')} |`);
    }
  }
}
