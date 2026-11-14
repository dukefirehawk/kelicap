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

/// Measures change detection of the same table, rendered from plain fields
/// with the default change detection, and from signals with OnPush.
///
/// Each operation runs in one [NgZone] turn, which ends with a change
/// detection pass, so the time of the turn is that of the change and of the
/// pass that renders it.
@Component(
  selector: 'bench-app',
  template: '''
    <h1>Signals benchmark</h1>
    <p>
      {{rowCount}} rows, rendered from plain fields with the default change
      detection, and from signals with OnPush. Each operation is one NgZone
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
    <field-table *ngIf="mode == 'fields'" [rows]="fieldRows"></field-table>
    <signal-table *ngIf="mode == 'signals'" [rows]="signalRows"></signal-table>
  ''',
  directives: [NgFor, NgIf, FieldTableComponent, SignalTableComponent],
)
class BenchAppComponent {
  final NgZone _zone;

  /// The number of rows in each table, from `?rows=` in the URL.
  final int rowCount =
      int.tryParse(
        Uri.parse(window.location.href).queryParameters['rows'] ?? '',
      ) ??
      1000;

  late final fieldRows = [
    for (var i = 0; i < rowCount; i++) FieldRow('Row $i'),
  ];
  late final signalRows = [
    for (var i = 0; i < rowCount; i++) SignalRow('Row $i'),
  ];

  /// The table on the page: 'fields', 'signals', or none.
  String? mode;
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
    // The first round warms up the JavaScript engine, and is not reported.
    for (final reported in [false, true]) {
      final round = [..._measure('fields'), ..._measure('signals')];
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
    _render(() => this.mode = mode);
    final fields = mode == 'fields';
    var next = 1;

    void setRow(int index) {
      final value = next++;
      if (fields) {
        fieldRows[index].value = value;
      } else {
        signalRows[index].value.set(value);
      }
    }

    return [
      _time(mode, 'Update one row', 50, 20, (i) => setRow(i * 7 % rowCount)),
      _time(mode, 'Update all rows', 20, 1, (_) {
        for (var i = 0; i < rowCount; i++) {
          setRow(i);
        }
      }),
      _time(mode, 'No change', 50, 20, (_) {}),
    ];
  }

  /// Times [samples] batches of [batch] turns that each run [operation], and
  /// returns the time of one turn.
  ///
  /// A batch is timed as a whole, as browsers round `performance.now()`, to
  /// 0.1 ms in Chrome, which is about the time of a turn.
  Result _time(
    String mode,
    String scenario,
    int samples,
    int batch,
    void Function(int) operation,
  ) {
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
    }
    final checks = RowChecks.count;
    times.sort();
    final mean = times.reduce((a, b) => a + b) / samples;
    return Result(mode, scenario, times[samples ~/ 2], mean, checks / i);
  }

  /// Changes the page, in a turn of the zone.
  void _render(void Function() change) => _zone.run(change);
}
