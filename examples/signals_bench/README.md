# Signals Benchmark

Compares the change detection of the same table of rows, rendered two ways:

- **fields**: each row's value is a plain field, and the rows use the default
  change detection, so every row is checked on every change detection pass.
- **signals**: each row's value is a signal, and the rows and the table use
  OnPush, so a row is checked only when its signal changes.

It times three scenarios:

| Scenario | Each operation |
|---|---|
| Update one row | Sets one row's value |
| Update all rows | Sets the value of every row |
| No change | Changes nothing |

Each operation runs in one `NgZone` turn, which ends with a change detection
pass, so its time is that of the change and of the pass that renders it. Short
operations are timed in batches of 20, as Chrome rounds `performance.now()` to
0.1 ms. Each row's template counts its checks, so the results also show how
many rows each operation checked. A first round warms up the JavaScript
engine, and is not reported.

## Running it

Measure a release build: a development build is slower, and checks every view
twice, for `debugCheckBindings`.

```bash
dart pub get
dart run build_runner build --release -o web:/tmp/signals_bench
cd /tmp/signals_bench
python3 -m http.server 8765
```

Open <http://localhost:8765/>, and select **Run**. The page is unresponsive
while it runs. Add `?rows=10000` to the URL to change the number of rows.

To run it without a window, add `?autorun`, which runs it while the page loads,
and read the results from the `<pre id="results">` element of the page:

```bash
google-chrome --headless=new --dump-dom \
  'http://localhost:8765/index.html?autorun&rows=1000'
```

## Results

On Linux, in headless Chrome, with `kelicap` 2.0.0, the mean time
of an operation, the median of three runs:

| Scenario | 1,000 rows: fields | 1,000 rows: signals | 10,000 rows: fields | 10,000 rows: signals |
|---|---|---|---|---|
| Update one row | 0.15 ms | < 0.01 ms | 1.7 ms | < 0.01 ms |
| Update all rows | 0.60 ms | 0.92 ms | 6.3 ms | 8.2 ms |
| No change | 0.14 ms | < 0.01 ms | 1.8 ms | < 0.01 ms |

Times vary between runs, by up to half for 10,000 rows, so compare the modes
within a row of the table rather than across tables.

Rows checked per operation:

| Scenario | fields | signals |
|---|---|---|
| Update one row | All | 1 |
| Update all rows | All | All |
| No change | All | None |

- **No change**: signals check nothing, where fields check every row, so a
  pass that follows an event that changed nothing costs nothing.
- **Update one row**: signals check only the row, about 30 times faster
  with 1,000 rows, and 250 times with 10,000. The table above it is not
  checked, nor is its `*ngFor`, which would compare every row of its list. The
  `*ngFor` records which of its rows were marked, so change detection goes
  straight to the row, and the time does not grow with the number of rows.
- **Update all rows**: signals are about 1.3 to 1.5 times slower, as each of
  the writes notifies its row, which records that it, and its ancestors, need
  to be checked.

## Compared with Angular 22

[`signals_bench_angular`](../signals_bench_angular) is this benchmark in
Angular 22.2, which runs without zone.js and checks only the views marked for
check. Its README describes how it differs, and how to run both. On Linux, in
headless Chrome, the two run alternately, the median of three runs:

| Scenario | Mode | 1,000 rows: Kelicap | 1,000 rows: Angular | 10,000 rows: Kelicap | 10,000 rows: Angular |
|---|---|---|---|---|---|
| Update one row | fields | 0.15 ms | 0.48 ms | 1.7 ms | 4.6 ms |
| Update one row | signals | 0.005 ms | 0.025 ms | 0.007 ms | 0.28 ms |
| Update all rows | fields | 0.60 ms | 0.83 ms | 6.3 ms | 9.2 ms |
| Update all rows | signals | 0.92 ms | 0.71 ms | 8.2 ms | 8.8 ms |
| No change | fields | 0.14 ms | 0.42 ms | 1.8 ms | 4.7 ms |
| No change | signals | 0.001 ms | 0.003 ms | 0.001 ms | 0.004 ms |

- **Rows checked:** the same in both, in every scenario: signals with OnPush
  check only the row that changed, or none.
- **Fields:** Kelicap is about 1.4 to 3 times faster.
- **One row, with signals:** Kelicap is 5 times faster with 1,000 rows, and
  40 times with 10,000, as its time does not grow with the number of rows.
- **Every row, with signals:** Angular is about 1.3 times faster with 1,000
  rows, and Kelicap about 1.1 times faster with 10,000.

Both benchmarks ran in the same Chrome, alternately, so compare the frameworks
within this table rather than with other runs.
