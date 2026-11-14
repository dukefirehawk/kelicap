# Benchmarks

**Disclaimer: These figures are intended as a quick baseline check on Kelicap's performance rather than a formal, exhaustive benchmark, so please treat them as indicative.**

The benchmark measures how fast Kelicap renders changes, how much memory it uses, and how large its output is, with plain fields and with [signals](https://github.com/dukefirehawk/kelicap/tree/main/packages/kelicap#signals), when compared with Angular 22, and with [Jaspr](https://jaspr.site), a Dart web framework modelled on Flutter. The apps measured are the [Kelicap Benchmark](https://github.com/dukefirehawk/kelicap/tree/main/examples/signals_bench), and the same benchmark in [Angular 22](https://github.com/dukefirehawk/kelicap/tree/main/examples/signals_bench_angular) and in [Jaspr](https://github.com/dukefirehawk/kelicap/tree/main/examples/signals_bench_jaspr). Each renders a table of rows in one of two modes:

- **fields:** each row's value is a plain field, and every component uses the change detection that checks it on every pass (Kelicap's default, and `ChangeDetectionStrategy.Eager` in Angular 22).
- **signals:** each row's value is a signal, and the rows and the table use OnPush, so a row is checked only when its signal changes.

Jaspr has no change detection and no signals, so its benchmark uses their nearest equivalents, described in [Compared with Jaspr](#compared-with-jaspr).

## Setup

- `kelicap` 1.2.0, built with dart2js (`build_runner build --release`, `-O4`), on Dart 3.13.7.
- Angular 22.2.6, in a production build (`ng build`), which runs without zone.js, the default in Angular 22.
- `jaspr` 0.23.5, a client-only app built like Kelicap's, with dart2js (`build_runner build --release`, `-O4`), on Dart 3.13.7.
- Headless Chrome 154 on Linux.

The numbers depend on the machine, and vary between runs: compare the columns of a table rather than numbers from different tables. Kelicap was measured with Angular in one session, and with Jaspr in another, so its numbers differ a little between the two comparisons.

The sections below compare Kelicap with Angular. Its comparison with Jaspr is in [Compared with Jaspr](#compared-with-jaspr).

## Speed

Each operation is a change followed by the change detection pass that renders it. In Kelicap, it is one `NgZone` turn. In Angular, it is `markForCheck()` on the root component followed by `ApplicationRef.tick()`, the equivalent of an event handled in the root. The two benchmarks ran alternately in the same Chrome, and the times are the mean of an operation, the median of three runs.

| Change | Mode | Kelicap, 1,000 rows | Angular, 1,000 rows | Kelicap, 10,000 rows | Angular, 10,000 rows |
| --- | --- | --- | --- | --- | --- |
| One row | fields | 0.13 ms | 0.44 ms | 1.9 ms | 4.6 ms |
| One row | signals | 0.006 ms | 0.024 ms | 0.10 ms | 0.27 ms |
| Every row | fields | 0.48 ms | 0.91 ms | 6.1 ms | 8.6 ms |
| Every row | signals | 0.72 ms | 0.73 ms | 7.4 ms | 9.3 ms |
| Nothing | fields | 0.12 ms | 0.45 ms | 1.9 ms | 4.6 ms |
| Nothing | signals | 0.001 ms | 0.003 ms | 0.001 ms | 0.003 ms |

Rows checked by each operation, the same in both frameworks:

| Change | fields | signals |
| --- | --- | --- |
| One row | All | 1 |
| Every row | All | All |
| Nothing | All | None |

- **Signals:** a change checks only the rows that show it, in both frameworks. Changing one row is about 20 times faster than with fields, and a pass after an event that changed nothing checks nothing. Changing every row is 1.2 to 1.5 times slower, as each signal that changes notifies its row.
- **Kelicap and Angular:** Kelicap is about 1.5 to 4 times faster, except when every row changes through signals, where it is as fast with 1,000 rows, and faster with 10,000.

## Memory

The JavaScript heap of the page, once its table is rendered and garbage is collected, the median of three runs, each in a new browser context. Both apps create the rows of both modes, and render the table of one, or none.

| Page | Kelicap | Angular |
| --- | --- | --- |
| A component that renders `<h1>Hello {{name}}</h1>` | 0.87 MB | 0.87 MB |
| 10,000 rows, no table | 2.4 MB | 3.7 MB |
| 10,000 rows, fields table | 13.7 MB | 9.9 MB |
| 10,000 rows, signals table | 14.0 MB | 10.5 MB |
| DOM nodes, 10,000 rows | 70,045 | 60,040 |

- **Data:** before any table is rendered, Kelicap's page takes about a third less memory than Angular's, 2.4 MB against 3.7 MB, with the rows of both modes created.
- **Rendered rows:** a rendered row takes about 1.1 KB in Kelicap, and 0.6 to 0.7 KB in Angular. Most of the difference is the local variables of `*ngFor`: each of its views keeps a map of seven of them (`$implicit`, `index`, `first`, `last`, `count`, `even` and `odd`), used or not, where Angular's `@for` keeps a small object, and computes `$first`, `$even` and the like from the index.
- **DOM nodes:** Kelicap keeps the space between `</span> <b>` in the row's template as a text node, where Angular removes whitespace-only text nodes by default, so each row has one more node.

## Output size

The JavaScript of a release build, raw and compressed, as served:

| App | Framework | Raw | gzip | Brotli |
| --- | --- | --- | --- | --- |
| A component that renders `<h1>Hello {{name}}</h1>` | Kelicap | 98.0 KB | 31.0 KB | 26.8 KB |
| | Angular | 91.3 KB | 30.5 KB | 27.5 KB |
| The signals benchmark | Kelicap | 164.4 KB | 50.9 KB | 43.5 KB |
| | Angular | 111.2 KB | 37.2 KB | 33.5 KB |

- **The framework:** the two are about the same size, once compressed.
- **The benchmark:** Kelicap's signal adds more to the output, but about half of that is Dart's own libraries, not Kelicap: `Uri.parse`, which reads `?rows=` from the URL (22 KB, raw), and `JsonEncoder`, which prints the results (9 KB), where the Angular benchmark uses the browser's `URL` and `JSON`. In an app where size matters, prefer the browser's APIs, through `package:web`, to `Uri` and `dart:convert`.

## Compared with Jaspr

The [Jaspr Benchmark](https://github.com/dukefirehawk/kelicap/tree/main/examples/signals_bench_jaspr) is the same benchmark in Jaspr 0.23.5. Both apps are Dart, compiled by the same dart2js, so the differences are those of the frameworks. Jaspr has no change detection, and no signals, so its two modes are their nearest equivalents:

- **fields:** each row is a `StatelessComponent`, rebuilt whenever its parent is, so every row is rebuilt on every pass.
- **signals:** each row's value is a `ValueNotifier`, and each row a `StatefulComponent` that rebuilds itself when it changes. The table and the rows override `shouldRebuild`, to skip a rebuild when their input is the same, as OnPush does.

Each operation is a change, a `setState` of the root, and the build that renders it, which Jaspr otherwise runs in a microtask. The rows rebuilt by each operation are the same as the rows checked in Kelicap.

The fields mode is the worst case for Jaspr: it rebuilds every row on every pass, which an app written for Jaspr avoids by keeping its state low in the tree, and its components `const` where they can be. The signals mode is closer to how a Jaspr app is written.

### Speed, with Jaspr

The mean time of an operation, the median of three runs:

| Change | Mode | Kelicap, 1,000 rows | Jaspr, 1,000 rows | Kelicap, 10,000 rows | Jaspr, 10,000 rows |
| --- | --- | --- | --- | --- | --- |
| One row | fields | 0.15 ms | 8.3 ms | 1.9 ms | 90 ms |
| One row | signals | 0.009 ms | 0.040 ms | 0.099 ms | 0.032 ms |
| Every row | fields | 0.52 ms | 10.1 ms | 6.0 ms | 113 ms |
| Every row | signals | 0.74 ms | 9.8 ms | 6.6 ms | 105 ms |
| Nothing | fields | 0.12 ms | 8.2 ms | 1.8 ms | 89 ms |
| Nothing | signals | 0.001 ms | 0.021 ms | 0.001 ms | 0.020 ms |

- **Rebuilding rows:** Kelicap is 13 to 70 times faster when rows are checked or rebuilt. Jaspr has no virtual DOM: each rebuilt element compares itself with the DOM, reading its attributes, and the content of its text nodes, so a rebuilt row costs about 15 to 20 DOM calls. Kelicap compares a binding with its previous value, in JavaScript, and touches the DOM only when it changed.
- **One row, with signals:** Jaspr rebuilds the dirty row directly, so its time does not grow with the number of rows, and it is about 3 times faster with 10,000 rows. Kelicap's change detection goes through the table's rows to find the one marked for check.
- **Nothing, with signals:** both check nothing, but Jaspr still rebuilds the root.

### Memory, with Jaspr

The JavaScript heap of the page, once its table is rendered and garbage is collected, the median of three runs, each in a new browser context:

| Page | Kelicap | Jaspr |
| --- | --- | --- |
| A component that renders `<h1>Hello {{name}}</h1>` | 0.87 MB | 0.83 MB |
| 10,000 rows, no table | 2.4 MB | 2.6 MB |
| 10,000 rows, fields table | 13.6 MB | 25.0 MB |
| 10,000 rows, signals table | 14.0 MB | 25.7 MB |
| DOM nodes, 10,000 rows | 70,044 | 60,035 |

- **Data:** before any table is rendered, the two pages are within 10% of each other.
- **Rendered rows:** a rendered row takes about 1.1 KB in Kelicap, and 2.2 to 2.3 KB in Jaspr, which keeps a component, an element and a render object for each component and each DOM node of the row.
- **DOM nodes:** Kelicap's row has one more, the empty text node of the binding `{{checked()}}` that counts its checks.

### Output size, with Jaspr

| App | Framework | Raw | gzip | Brotli |
| --- | --- | --- | --- | --- |
| A component that renders `<h1>Hello {{name}}</h1>` | Kelicap | 98.0 KB | 31.2 KB | 26.8 KB |
| | Jaspr | 101.7 KB | 31.1 KB | 26.8 KB |
| The signals benchmark | Kelicap | 164.4 KB | 51.1 KB | 43.5 KB |
| | Jaspr | 153.4 KB | 47.0 KB | 40.1 KB |

- **The framework:** the two are the same size, once compressed.
- **The benchmark:** Jaspr's is about 8% smaller. Both use the same code to time and report the scenarios, including `Uri.parse` and `JsonEncoder`, so the difference is that of the frameworks: Kelicap's templates compile to code for each component, where Jaspr's components are plain Dart.

## Running them

The READMEs of the [Kelicap Benchmark](https://github.com/dukefirehawk/kelicap/tree/main/examples/signals_bench), of the [Angular 22 Benchmark](https://github.com/dukefirehawk/kelicap/tree/main/examples/signals_bench_angular) and of the [Jaspr Benchmark](https://github.com/dukefirehawk/kelicap/tree/main/examples/signals_bench_jaspr) say how to build and run them, and how to compare them with their `tool/compare.mjs`.
