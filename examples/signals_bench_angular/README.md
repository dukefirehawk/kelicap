# Signals Benchmark (Angular)

The [Kelicap signals benchmark](../signals_bench), written in Angular 22, to
compare the two frameworks. It renders the same table of rows, from plain
fields with eager change detection, and from signals with OnPush, and times
the same three scenarios: updating one row, updating every row, and changing
nothing.

It differs from the Kelicap benchmark only where Angular 22 does:

- **Change detection:** Angular 22 runs without zone.js by default, and
  `ApplicationRef.tick()` checks only the views marked for check. An event
  handler marks its component's view, so each operation ends with
  `markForCheck()` on the root component and `tick()`, the equivalent of a
  Kelicap `NgZone` turn. Both frameworks check the root component on every
  pass.
- **Strategies:** OnPush is the default in Angular 22, so the field rows, the
  field table and the root component use `ChangeDetectionStrategy.Eager`, the
  old default.
- **Lists:** the tables list their rows with `@for (row of rows; track row)`,
  where Kelicap uses `*ngFor`.

## Running it

It needs Node.js 26 or later, the version in `.nvmrc`. With nvm, run
`nvm install` and `nvm use` in this directory.

```bash
npm ci
npm run build
```

The build is in `dist/browser`. Serve it as static files, such as with
`python3 -m http.server 8766 -d dist/browser`, and open
<http://localhost:8766/>. It accepts the same `?rows=` and `?autorun`
parameters as the Kelicap benchmark.

A development build, `npx ng build --configuration development`, writes to
`dist-dev`. It cannot run the benchmark: Angular's development mode stops an
application that runs thousands of passes in one task, with NG0103.

## Comparing it with Kelicap

`tool/compare.mjs` runs both benchmarks alternately, in one headless Chrome,
through the DevTools protocol, and prints the median of their rounds. Build
the Kelicap benchmark in release mode first:

```bash
(cd ../signals_bench && dart run build_runner build --release -o web:/tmp/signals_bench)
node tool/compare.mjs /tmp/signals_bench dist/browser 3 1000 10000
```

The arguments are the two builds, the number of rounds, and the numbers of
rows. Set `CHROME` to the Chrome executable if it is not `google-chrome`.

The results are in the [Kelicap benchmark's README](../signals_bench/README.md#compared-with-angular-22).
