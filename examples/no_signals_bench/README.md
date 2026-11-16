# No Signals Benchmark

Measures the change detection of a table that reads no signal, to compare
Kelicap releases: signals, new in 2.0.0, must not slow down the apps that do
not use them. It uses only the API of `kelicap` 1.x, so that it builds against
both.

It renders the same table of rows two ways:

- **default**: the rows use the default change detection, so every row is
  checked on every change detection pass.
- **onpush**: the rows and the table use OnPush, and the code that changes a
  row calls `markForCheck` on it.

It times five scenarios:

| Scenario | Each operation |
| --- | --- |
| Create table | Renders the table: the first check of each of its views |
| Update one row | Sets one row's value |
| Update all rows | Sets the value of every row |
| No change | Changes nothing |
| Remove table | Removes the table |

Each operation runs in one `NgZone` turn, which ends with a change detection
pass, so its time is that of the change and of the pass that renders it. Short
operations are timed in batches of 20, as Chrome rounds `performance.now()` to
0.1 ms. A first round warms up the JavaScript engine, and is not reported.

## Running it

Measure a release build: a development build is slower, and checks every view
twice, for `debugCheckBindings`.

```bash
dart pub get
dart run build_runner build --release -o web:/tmp/no_signals_bench
cd /tmp/no_signals_bench
python3 -m http.server 8765
```

Open <http://localhost:8765/>, and select **Run**. The page is unresponsive
while it runs. The URL takes these parameters:

- `?rows=10000`: the number of rows, 1,000 by default.
- `?modes=default`: the modes measured, `default,onpush` by default. Measuring
  one mode alone is faster than after the other, in any release, as the
  JavaScript engine then sees fewer kinds of views.
- `?autorun`: runs it while the page loads, so that the results can be read
  without a window, from the `<pre id="results">` element of the page:

  ```bash
  google-chrome --headless=new --dump-dom \
    'http://localhost:8765/index.html?autorun&rows=1000'
  ```

To compare with another release, build the same benchmark against it, such as
against a worktree of an older commit, by pointing the paths of
`pubspec_overrides.yaml` at its `packages/`, and run both builds alternately:
the times of one build vary between runs by up to a fifth.

## Results

On Linux, in headless Chrome, the mean time of an operation, the median of
five runs at 1,000 rows and three at 10,000, of `kelicap` 1.1.5, and of 2.0.0
(unreleased):

| Scenario | 1,000 rows: 1.1.5 | 1,000 rows: 2.0.0 | 10,000 rows: 1.1.5 | 10,000 rows: 2.0.0 |
| --- | --- | --- | --- | --- |
| default: Update one row | 0.11 ms | 0.13 ms | 1.4 ms | 1.6 ms |
| default: Update all rows | 0.61 ms | 0.66 ms | 5.3 ms | 5.6 ms |
| default: No change | 0.11 ms | 0.13 ms | 1.2 ms | 1.6 ms |
| default: Create table | 8.7 ms | 8.6 ms | 76 ms | 73 ms |
| onpush: Update one row | 0.06 ms | 0.08 ms | 0.98 ms | 1.3 ms |
| onpush: Update all rows | 0.71 ms | 0.69 ms | 6.1 ms | 6.5 ms |
| onpush: Create table | 8.4 ms | 7.7 ms | 81 ms | 82 ms |

The medians of a release vary by up to a fifth from one session to another,
so compare the releases within a row of the table, measured alternately.

- **Default change detection**: a pass is up to a third slower in 2.0.0 in
  some sessions, as in this table, and as fast as in 1.1.5 in others. Each component view that
  reads no signal checks whether it read one, by comparing a count of the
  reads before and after its check.
- **OnPush, update one row**: about a quarter slower in 2.0.0 with 10,000
  rows, where the table that `markForCheck` marks goes through every row, to
  skip it. The cause is not known yet.
- **Creating and removing a table** cost the same in both, although the first
  check of each view in 2.0.0 records the signals that it reads, and drops
  what it recorded if it read none.
