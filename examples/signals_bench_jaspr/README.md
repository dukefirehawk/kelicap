# Signals Benchmark (Jaspr)

The [Kelicap signals benchmark](../signals_bench), written in
[Jaspr](https://jaspr.site) 0.23, to compare the two frameworks. It renders
the same table of rows two ways, and times the same three scenarios: updating
one row, updating every row, and changing nothing.

It differs from the Kelicap benchmark only where Jaspr does:

- **Fields:** each row is a `StatelessComponent`, which Jaspr rebuilds
  whenever its parent rebuilds, so every row is rebuilt on every pass, as
  every row is checked with Kelicap's default change detection.
- **Signals:** Jaspr has no signals. Each row's value is a `ValueNotifier`,
  Jaspr's observable value, and each row a `StatefulComponent` that listens to
  it and calls `setState`. The table and the rows override `shouldRebuild` to
  skip a rebuild when their input is the same, the equivalent of OnPush.
- **Passes:** Jaspr builds the components marked dirty in a microtask. The
  benchmark's `BenchBinding` runs that build when it is called, so each
  operation is a change, a `setState` of the root, as an event handler of the
  root would make, and the build that renders it: the equivalent of a Kelicap
  `NgZone` turn. Both frameworks check the root component on every pass.
- **Host elements:** Jaspr components have no element of their own. The rows
  and tables render a `<field-row>`, `<signal-row>`, `<field-table>` or
  `<signal-table>` element, to keep the DOM of the Kelicap benchmark.

The code that times the scenarios and reports them, including its use of
`Uri.parse` and `JsonEncoder`, is that of the Kelicap benchmark, so that the
difference in output size is that of the frameworks.

## Running it

```bash
dart pub get
dart run build_runner build --release -o web:/tmp/signals_bench_jaspr
cd /tmp/signals_bench_jaspr
python3 -m http.server 8767
```

Open <http://localhost:8767/>, and select **Run**. It accepts the same
parameters as the Kelicap benchmark: `?rows=` for the number of rows,
`?autorun` to run while the page loads, and `?show=fields` or `?show=signals`
to render a table without running.

## Comparing it with Kelicap

`tool/compare.mjs` runs both benchmarks in one headless Chrome, through the
DevTools protocol. Build the Kelicap benchmark in release mode first:

```bash
(cd ../signals_bench && dart run build_runner build --release -o web:/tmp/signals_bench)
node tool/compare.mjs speed /tmp/signals_bench /tmp/signals_bench_jaspr 3 1000 10000
node tool/compare.mjs memory /tmp/signals_bench /tmp/signals_bench_jaspr 3
node tool/compare.mjs size /tmp/signals_bench /tmp/signals_bench_jaspr
```

- `speed` runs the two benchmarks alternately, the number of rounds given,
  and prints the median of each operation's mean time. With 10,000 rows, a
  round of the Jaspr benchmark takes several minutes.
- `memory` loads each page in a new browser context, collects garbage, and
  prints the median of the JavaScript heap, and the number of DOM nodes.
- `size` prints the size of `main.dart.js`, raw, with gzip and with Brotli.

Set `CHROME` to the Chrome executable if it is not `google-chrome`.

The results are in the Kelicap benchmarks.
They are worth reading with what the benchmark measures in mind: the fields
mode rebuilds every row on every pass, which an app written for Jaspr would
avoid with `const` components and state kept low in the tree.
