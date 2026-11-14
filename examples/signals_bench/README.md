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

On Linux, in headless Chrome, with `kelicap` 1.2.0 (unreleased), the mean time
of an operation, the median of three runs:

| Scenario | 1,000 rows: fields | 1,000 rows: signals | 10,000 rows: fields | 10,000 rows: signals |
|---|---|---|---|---|
| Update one row | 0.29 ms | 0.01 ms | 2.8 ms | 0.24 ms |
| Update all rows | 0.87 ms | 1.4 ms | 7.7 ms | 14 ms |
| No change | 0.28 ms | < 0.01 ms | 1.6–2.8 ms | < 0.01 ms |

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
- **Update one row**: signals check only the row, about 10 to 30 times faster.
  The table above it is not checked, nor is its `*ngFor`, which would compare
  every row of its list: change detection only goes through the table's rows
  to find the one that changed, which is why the time still grows a little
  with the number of rows.
- **Update all rows**: signals are about 1.6 to 2 times slower, as each of the
  writes notifies its row, which records that it, and its ancestors, need to
  be checked.
