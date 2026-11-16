import 'dart:convert';

import 'package:kelicap/kelicap.dart';
import 'package:web/web.dart';

import 'rows.dart';

/// The result of a scenario, in one mode.
class Result {
  final String mode;
  final String scenario;
  final double medianMs;
  final double meanMs;
  final double rowsCheckedPerOp;

  Result(
    this.mode,
    this.scenario,
    this.medianMs,
    this.meanMs,
    this.rowsCheckedPerOp,
  );

  String get median => medianMs.toStringAsFixed(3);
  String get mean => meanMs.toStringAsFixed(3);
  String get rowsChecked => rowsCheckedPerOp.toStringAsFixed(1);

  Map<String, Object> toJson() => {
    'mode': mode,
    'scenario': scenario,
    'medianMs': medianMs,
    'meanMs': meanMs,
    'rowsCheckedPerOp': rowsCheckedPerOp,
  };
}

/// Measures change detection of a table that reads no signal, rendered with
/// the default change detection, and with OnPush and `markForCheck`.
///
/// It uses only the API of `kelicap` 1.x, so that it builds against both
/// 1.x and 2.x, to compare them.
///
/// Each operation runs in one [NgZone] turn, which ends with a change
/// detection pass, so the time of the turn is that of the change and of the
/// pass that renders it.
@Component(
  selector: 'bench-app',
  template: '''
    <h1>Change detection without signals</h1>
    <p>
      {{rowCount}} rows that read no signal, rendered with the default change
      detection, and with OnPush and markForCheck. Each operation is one NgZone
      turn, timed with the change detection pass that ends it. Add
      <code>?rows=10000</code> to the URL to change the number of rows.
    </p>
    <button (click)="run()" [disabled]="running">Run</button>
    <span>{{status}}</span>
    <table *ngIf="results.isNotEmpty">
      <tr>
        <th>Mode</th><th>Scenario</th><th>Median (ms)</th><th>Mean (ms)</th>
        <th>Rows checked per operation</th>
      </tr>
      <tr *ngFor="let result of results">
        <td>{{result.mode}}</td><td>{{result.scenario}}</td>
        <td>{{result.median}}</td><td>{{result.mean}}</td>
        <td>{{result.rowsChecked}}</td>
      </tr>
    </table>
    <pre id="results">{{json}}</pre>
    <default-table *ngIf="mode == 'default'" [rows]="rows"></default-table>
    <onpush-table *ngIf="mode == 'onpush'" [rows]="rows"></onpush-table>
  ''',
  directives: [NgFor, NgIf, DefaultTableComponent, OnPushTableComponent],
)
class BenchAppComponent {
  final NgZone _zone;

  /// The number of rows in each table, from `?rows=` in the URL.
  final int rowCount =
      int.tryParse(
        Uri.parse(window.location.href).queryParameters['rows'] ?? '',
      ) ??
      1000;

  late final rows = [for (var i = 0; i < rowCount; i++) Row('Row $i')];

  /// The table on the page: 'default', 'onpush', or none, from `?show=`.
  String? mode = Uri.parse(window.location.href).queryParameters['show'];
  var running = false;
  var status = '';
  var results = <Result>[];
  var json = '';

  BenchAppComponent(this._zone);

  /// Runs the benchmark, synchronously.
  ///
  /// Called outside of the zone, so that each operation is a turn of its own.
  void run() {
    _zone.runOutsideKelicap(_runAll);
  }

  void _runAll() {
    _render(() {
      running = true;
      status = 'Running…';
    });
    // The modes measured, from `?modes=`, such as `?modes=default`.
    final modes =
        (Uri.parse(window.location.href).queryParameters['modes'] ??
                'default,onpush')
            .split(',');
    // The first round warms up the JavaScript engine, and is not reported.
    for (final reported in [false, true]) {
      final round = [for (final mode in modes) ..._measure(mode)];
      if (reported) {
        _render(() {
          results = round;
          json = const JsonEncoder.withIndent('  ').convert(round);
        });
      }
    }
    _render(() {
      mode = null;
      running = false;
      status = 'Done.';
    });
  }

  List<Result> _measure(String mode) {
    final onPush = mode == 'onpush';
    var next = 1;

    void setRow(int index) {
      final row = rows[index];
      row.value = next++;
      if (onPush) {
        row.changeDetector!.markForCheck();
      }
    }

    // Creating the table, which is then removed, untimed: the first check of
    // each of its views.
    _render(() => this.mode = null);
    final create = _time(
      mode,
      'Create table',
      10,
      1,
      (_) => this.mode = mode,
      after: () => _render(() => this.mode = null),
    );
    _render(() => this.mode = mode);
    return [
      create,
      _time(mode, 'Update one row', 50, 20, (i) => setRow(i * 7 % rowCount)),
      _time(mode, 'Update all rows', 20, 1, (_) {
        for (var i = 0; i < rowCount; i++) {
          setRow(i);
        }
      }),
      _time(mode, 'No change', 50, 20, (_) {}),
      _time(
        mode,
        'Remove table',
        10,
        1,
        (_) => this.mode = null,
        after: () => _render(() => this.mode = mode),
      ),
    ];
  }

  /// Times [samples] batches of [batch] turns that each run [operation], and
  /// returns the time of one turn.
  ///
  /// A batch is timed as a whole, as browsers round `performance.now()`, to
  /// 0.1 ms in Chrome, which is about the time of a turn. [after], if given,
  /// runs after each batch, untimed, such as to undo the operation.
  Result _time(
    String mode,
    String scenario,
    int samples,
    int batch,
    void Function(int) operation, {
    void Function()? after,
  }) {
    final times = <double>[];
    RowChecks.count = 0;
    var i = 0;
    for (var sample = 0; sample < samples; sample++) {
      final start = window.performance.now();
      for (var end = i + batch; i < end; i++) {
        final index = i;
        _zone.run(() => operation(index));
      }
      times.add((window.performance.now() - start) / batch);
      after?.call();
    }
    final checks = RowChecks.count;
    times.sort();
    final mean = times.reduce((a, b) => a + b) / samples;
    return Result(mode, scenario, times[samples ~/ 2], mean, checks / i);
  }

  /// Changes the page, in a turn of the zone.
  void _render(void Function() change) => _zone.run(change);
}
