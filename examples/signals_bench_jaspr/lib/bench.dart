import 'dart:async';
import 'dart:convert';

import 'package:jaspr/client.dart';
import 'package:jaspr/dom.dart';
import 'package:web/web.dart' show window;

import 'rows.dart';

/// The result of a scenario, in one mode, as the Kelicap benchmark reports it.
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

  Map<String, Object> toJson() => {
    'mode': mode,
    'scenario': scenario,
    'medianMs': medianMs,
    'meanMs': meanMs,
    'rowsCheckedPerOp': rowsCheckedPerOp,
  };
}

/// A client binding that runs its frames when [flush] is called.
///
/// Jaspr builds the components marked dirty in a microtask, to batch the
/// changes of a task. The benchmark runs synchronously, so it calls [flush]
/// after each change, to render it, the equivalent of the end of an NgZone
/// turn in Kelicap. A microtask still flushes the frames of an event, such as
/// a click.
class BenchBinding extends ClientAppBinding {
  final _frames = <void Function()>[];

  @override
  void scheduleFrame(void Function() frameCallback) {
    _frames.add(frameCallback);
    scheduleMicrotask(flush);
  }

  /// Runs the scheduled frames.
  void flush() {
    while (_frames.isNotEmpty) {
      _frames.removeAt(0)();
    }
  }
}

/// Measures the rebuilds of the same table, rendered from plain fields that
/// rebuild with their parent, and from value notifiers that rebuild only the
/// rows that changed.
class BenchApp extends StatefulComponent {
  final BenchBinding binding;

  const BenchApp(this.binding);

  /// The state of the app on the page, once it is built.
  static BenchAppState? instance;

  @override
  State<BenchApp> createState() => BenchAppState();
}

class BenchAppState extends State<BenchApp> {
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

  /// The table on the page: 'fields', 'signals', or none, from `?show=`.
  String? mode = Uri.parse(window.location.href).queryParameters['show'];
  var running = false;
  var status = '';
  var results = <Result>[];
  var json = '';

  @override
  void initState() {
    super.initState();
    BenchApp.instance = this;
    // Creates the rows of both modes up front, so that the memory of a page
    // does not depend on the table it shows.
    fieldRows.length + signalRows.length;
  }

  /// Runs the benchmark, synchronously.
  void run() {
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
        signalRows[index].value.value = value;
      }
    }

    return [
      _time(mode, 'Update one row', 50, 20, (n) => setRow(n * 7 % rowCount)),
      _time(mode, 'Update all rows', 20, 1, (_) {
        for (var i = 0; i < rowCount; i++) {
          setRow(i);
        }
      }),
      _time(mode, 'No change', 50, 20, (_) {}),
    ];
  }

  /// Times [samples] batches of [batch] operations, and returns the time of
  /// one, as the Kelicap benchmark does.
  ///
  /// Each operation is followed by a rebuild of the root, as an event handler
  /// of the root that calls `setState` would make it, the equivalent of an
  /// NgZone turn of the Kelicap benchmark.
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
        _render(() => operation(index));
      }
      times.add((window.performance.now() - start) / batch);
    }
    final checks = RowChecks.count;
    times.sort();
    final mean = times.reduce((x, y) => x + y) / samples;
    return Result(mode, scenario, times[samples ~/ 2], mean, checks / i);
  }

  /// Changes the page, and renders it.
  void _render(void Function() change) {
    setState(change);
    component.binding.flush();
  }

  @override
  Component build(BuildContext context) => Component.fragment([
    const h1([Component.text('Signals benchmark (Jaspr)')]),
    p([
      Component.text(
        '$rowCount rows, rendered from plain fields that rebuild with their '
        'parent, and from value notifiers that rebuild only their row. Add ',
      ),
      const code([Component.text('?rows=10000')]),
      const Component.text(' to the URL to change the number of rows.'),
    ]),
    button(disabled: running, onClick: run, [const Component.text('Run')]),
    span([Component.text(status)]),
    if (results.isNotEmpty)
      table([
        tr([
          for (final heading in [
            'Mode',
            'Scenario',
            'Median (ms)',
            'Mean (ms)',
            'Rows checked per operation',
          ])
            th([Component.text(heading)]),
        ]),
        for (final result in results)
          tr([
            td([Component.text(result.mode)]),
            td([Component.text(result.scenario)]),
            td([Component.text(result.medianMs.toStringAsFixed(3))]),
            td([Component.text(result.meanMs.toStringAsFixed(3))]),
            td([Component.text(result.rowsCheckedPerOp.toStringAsFixed(1))]),
          ]),
      ]),
    pre(id: 'results', [Component.text(json)]),
    if (mode == 'fields') FieldTableComponent(fieldRows),
    if (mode == 'signals') SignalTableComponent(signalRows),
  ]);
}
