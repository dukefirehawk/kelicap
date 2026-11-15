import 'dart:async';

import 'package:test/test.dart';
import 'package:kelicap/kelicap.dart';
import 'package:kelicap/signals.dart';
import 'package:kelicap/src/core/application_ref.dart';
import 'package:kelicap/src/core/linker/app_view_utils.dart';
import 'package:kelicap/src/runtime/dom_events.dart';

import 'signal_edge_cases_test.template.dart' as ng;

// The state of the components, set up again by each test.
late WritableSignal<int> state;
late WritableSignal<int> a;
late WritableSignal<int> b;
var loopChecks = 0;

/// The checks of each [CheckCounter], by its name.
final counterChecks = <String, int>{};
var hookChecks = 0;
var doChecks = 0;
var bumps = 0;

/// The signals of the rows of [RowsComponent].
var rowSignals = <WritableSignal<int>>[];

/// How many times [LoopComponent] sets a signal, at most, so that a test of a
/// pass that never ends does not freeze the browser.
const loopCap = 1000;

void main() {
  late NgZone ngZone;
  late ApplicationRef appRef;
  late List<Object> errors;

  /// Lets the microtasks that are queued run.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  /// Sets signals outside the zone, so that only they can update the page.
  Future<void> outside(void Function() fn) async {
    ngZone.runOutsideKelicap(fn);
    await settle();
  }

  Future<ComponentRef<T>> bootstrap<T extends Object>(
    ComponentFactory<T> factory,
  ) async {
    final ref = appRef.bootstrap<T>(factory);
    await settle();
    return ref;
  }

  setUp(() {
    state = signal(0);
    a = signal(0);
    b = signal(0);
    loopChecks = hookChecks = doChecks = bumps = 0;
    RootDestroyer.onChecked = null;
    rowSignals = [signal(0), signal(0), signal(0)];
    counterChecks.clear();
    errors = [];

    ngZone = NgZone();
    appRef = internalCreateApplicationRef(
      ngZone,
      Injector.map({ExceptionHandler: _CollectingExceptionHandler(errors)}),
    );
    appViewUtils = AppViewUtils('appId', EventManager(ngZone));
  });

  tearDown(() => appRef.dispose());

  test('a signal set on every check does not run passes forever', () async {
    await bootstrap(ng.createLoopComponentFactory());
    // Lets the passes run until the component stops setting the signal.
    for (var i = 0; i < 10; i++) {
      await settle();
    }
    expect(loopChecks, lessThan(loopCap));
    expect(errors, [isStateError]);
  });

  test('passes that each request one more, a few times, all run', () async {
    loopChecks = loopCap - 5;
    await bootstrap(ng.createLoopComponentFactory());
    for (var i = 0; i < 10; i++) {
      await settle();
    }
    expect(loopChecks, loopCap);
    expect(errors, isEmpty);
  });

  test(
    'a signal set while the OnPush view that read it is checked renders',
    () async {
      final parent = await bootstrap(ng.createSetDuringCheckParentFactory());
      await settle();
      expect(parent.location.querySelector('#state')!.textContent, '1');
      expect(errors, isEmpty);
    },
  );

  test('a view that sets a signal it read on every check stops', () async {
    await bootstrap(ng.createSelfSettingComponentFactory());
    for (var i = 0; i < 10; i++) {
      await settle();
    }
    expect(loopChecks, lessThan(loopCap));
    expect(errors, isNotEmpty);
    expect(errors, everyElement(isStateError));
  });

  test(
    'a view that reads a signal is checked as often as one that does not',
    () async {
      // Each bootstrap checks the roots before it too: compares the checks
      // of one bootstrap.
      await bootstrap(ng.createPlainParentComponentFactory());
      final plainChecks = counterChecks['plain'];
      final parent = await bootstrap(ng.createSignalParentComponentFactory());
      expect(parent.location.textContent, '0');
      expect(counterChecks['signal'], plainChecks);
    },
  );

  test('a view whose first check throws does not stay subscribed', () async {
    final host = await bootstrap<ThrowingReaderHost>(
      ng.createThrowingReaderHostFactory(),
    );
    ngZone.run(() => host.instance.show = true);
    await settle();
    expect(errors, isNotEmpty);
    // Destroys the view that threw.
    ngZone.run(() => host.instance.show = false);
    await settle();
    ngZone.runOutsideKelicap(() => a.set(5));
    expect(appRef.changeDetectionScheduler.isPending, isFalse);
  });

  test('an effect that runs while a view is checked is not its read', () async {
    final ref = ngZone.run(() => effect((_) => a()));
    final read = await bootstrap<EffectToggleParent>(
      ng.createEffectToggleParentFactory(),
    );
    final plain = await bootstrap<PlainToggleParent>(
      ng.createPlainToggleParentFactory(),
    );
    final (readBefore, plainBefore) = (
      counterChecks['effect']!,
      counterChecks['plain']!,
    );
    // Each shows a child that sets a signal while it is checked: only the
    // effect reads the first one.
    ngZone.run(() {
      read.instance.show = true;
      plain.instance.show = true;
    });
    await settle();
    expect(
      counterChecks['effect']! - readBefore,
      counterChecks['plain']! - plainBefore,
    );
    expect(errors, isEmpty);
    ref.destroy();
  });

  test('a computed value that keeps its value does not check again', () async {
    await bootstrap(ng.createEvenComponentFactory());
    await settle();
    expect(bumps, lessThan(10));
    expect(errors, isEmpty);
  });

  group('marked views in an *ngFor', () {
    late ComponentRef<RowsComponent> rows;
    String rowsText() {
      final items = rows.location.querySelectorAll('.row');
      return [for (var i = 0; i < items.length; i++) items.item(i)!.textContent]
          .join(' ');
    }

    setUp(() async {
      rows = await bootstrap<RowsComponent>(ng.createRowsComponentFactory());
      expect(rowsText(), '0 0 0');
    });

    test('are checked, and only they', () async {
      await outside(() {
        rowSignals[0].set(1);
        rowSignals[2].set(3);
      });
      expect(rowsText(), '1 0 3');
      expect(errors, isEmpty);
    });

    test('are checked when one of them is removed in the same pass', () async {
      await outside(() {
        rowSignals[1].set(5);
        rowSignals[2].set(7);
        rows.instance.removeRow(1);
      });
      expect(rowsText(), '0 7');
      await outside(() => rowSignals[2].set(8));
      expect(rowsText(), '0 8');
      expect(errors, isEmpty);
    });

    test('are checked after one of them throws', () async {
      await outside(() {
        rowSignals[0].set(-1);
        rowSignals[2].set(9);
      });
      expect(errors, isNotEmpty);
      expect(rowsText().split(' ').last, '9');
      await outside(() => rowSignals[2].set(10));
      expect(rowsText().split(' ').last, '10');
    });
  });

  group('a host binding of a root component', () {
    test('renders a signal set outside the zone', () async {
      final root = await bootstrap<ThemedRootComponent>(
        ng.createThemedRootComponentFactory(),
      );
      expect(root.location.classList.contains('dark'), isFalse);
      await outside(() => state.set(1));
      expect(root.location.classList.contains('dark'), isTrue);
      expect(errors, isEmpty);
    });

    test('renders a signal set while the component is checked', () async {
      final root = await bootstrap<ThemedSetterRootComponent>(
        ng.createThemedSetterRootComponentFactory(),
      );
      // Its child set the signal when it was first checked.
      expect(root.location.classList.contains('dark'), isTrue);
      expect(errors, isEmpty);
    });
  });

  test('a signal set in an NgZone turn is rendered by its pass', () async {
    final reader = await bootstrap(ng.createStateReaderComponentFactory());
    var passes = 0;
    final sub = ngZone.onMicrotaskEmpty.listen((_) => passes++);
    addTearDown(sub.cancel);
    ngZone.run(() => state.set(1));
    expect(reader.location.textContent, '1', reason: 'at the end of the turn');
    expect(appRef.changeDetectionScheduler.isPending, isFalse);
    await settle();
    expect(passes, 1, reason: 'the request adds no pass');
    expect(errors, isEmpty);
  });

  test(
    'a signal set in the zone after its pass, in a listener, is rendered',
    () async {
      final reader = await bootstrap(ng.createStateReaderComponentFactory());
      // Listens after the app, so it runs after the app's pass, and in the
      // zone, as a component or a service that listens does. It first runs
      // at the end of this turn, which no other turn follows.
      final sub = ngZone.run(
        () => ngZone.onMicrotaskEmpty.listen((_) {
          if (state() == 0) {
            state.set(1);
          }
        }),
      );
      addTearDown(sub.cancel);
      await settle();
      expect(reader.location.textContent, '1');
      expect(errors, isEmpty);
    },
  );

  test('a root component destroyed during a tick is not checked', () async {
    await bootstrap(ng.createRootDestroyerFactory());
    final second = await bootstrap(ng.createStateReaderComponentFactory());
    RootDestroyer.onChecked = second.destroy;
    ngZone.run(() {});
    await settle();
    expect(errors, isEmpty);
  });

  test(
    'a host view marked before it is inserted is refreshed once inserted',
    () async {
      await bootstrap(ng.createManualRowsRootFactory());
      final container = manualRows!.container;
      final themed = ngZone.run(() {
        final ref = ng.createThemedRootComponentFactory().create(
          container.parentInjector,
        );
        // Checked on its own, so it records the signal its host binding reads.
        ref.changeDetectorRef.detectChanges();
        return ref;
      });
      expect(themed.location.classList.contains('dark'), isFalse);
      // Marks it, while it is in no container.
      await outside(() => state.set(1));
      // Inserted below an OnPush view that is not checked: only the mark
      // brings change detection to it.
      ngZone.run(() => container.insert(themed.hostView));
      await settle();
      expect(themed.location.classList.contains('dark'), isTrue);
      expect(errors, isEmpty);
    },
  );

  test(
    'a marked view removed while marked views are checked is not checked',
    () async {
      await bootstrap(ng.createManualRowsRootFactory());
      final rows = manualRows!;
      ngZone.run(rows.addRows);
      await settle();
      expect(rows.container.length, 2);
      expect(errors, isEmpty);
      // While the first row is checked, it removes the second, also marked.
      await outside(() {
        rowSignals[0].set(2);
        rowSignals[1].set(5);
      });
      expect(rows.container.length, 1);
      expect(errors, isEmpty);
    },
  );

  test('a view that reads a signal in some checks keeps recording', () async {
    final parent = await bootstrap<InputReaderParent>(
      ng.createInputReaderParentFactory(),
    );
    Future<int> checksOfChange(int value) async {
      final before = counterChecks['input']!;
      ngZone.run(() => parent.instance.value = value);
      await settle();
      return counterChecks['input']! - before;
    }

    // The first signal it reads checks it twice, once.
    final first = await checksOfChange(1);
    final second = await checksOfChange(2);
    expect(second, lessThan(first));
    expect(await checksOfChange(3), second);
    expect(errors, isEmpty);
  });

  test('a signal with a custom equal notifies of the same object', () async {
    final items = signal(<int>[], equal: (a, b) => false);
    final seen = <int>[];
    final ref = effect((_) => seen.add(items().length));
    items().add(1);
    items.set(items());
    expect(seen, [0, 1]);
    ref.destroy();
  });

  test('an effect that throws does not stop the views it precedes', () async {
    // Created before the view reads the signal, so that it is notified first.
    final ref = ngZone.run(
      () => effect((_) {
        if (state() == 3) throw StateError('effect');
      }),
    );
    final reader = await bootstrap(ng.createStateReaderComponentFactory());
    expect(reader.location.textContent, '0');

    ngZone.runOutsideKelicap(() {
      expect(() => state.set(3), returnsNormally);
    });
    await settle();
    expect(reader.location.textContent, '3');
    expect(errors, [isStateError]);
    ref.destroy();
  });

  group('a view that reads its first signal after its first check', () {
    late ComponentRef<LateReaderComponent> reader;
    String text() => reader.location.textContent!;

    setUp(() async {
      reader = await bootstrap(ng.createLateReaderComponentFactory());
      expect(text(), '');
    });

    test('renders its changes, once checked in a pass', () async {
      ngZone.run(() {
        reader.instance
          ..show = true
          ..changeDetector.markForCheck();
      });
      await settle();
      expect(text(), '0');
      await outside(() => state.set(5));
      expect(text(), '5');
      expect(errors, isEmpty);
    });

    test('renders its changes, once checked on its own', () async {
      await outside(() {
        reader.instance
          ..show = true
          ..changeDetector.markForCheck()
          // Checks it outside of a pass, which nothing follows.
          // ignore: deprecated_member_use
          ..changeDetector.detectChanges();
      });
      expect(text(), '0');
      await outside(() => state.set(7));
      expect(text(), '7');
      expect(errors, isEmpty);
    });
  });

  test('a signal runs the lifecycle hooks of the component that reads it, '
      'but not ngDoCheck', () async {
    await bootstrap(ng.createHookRootComponentFactory());
    final (checksBefore, doChecksBefore) = (hookChecks, doChecks);
    await outside(() => state.set(1));
    expect(hookChecks, greaterThan(checksBefore));
    // Its parent was not checked.
    expect(doChecks, doChecksBefore);
    expect(errors, isEmpty);
  });

  test('a marked view is still checked after a sibling throws', () async {
    final root = await bootstrap(ng.createSiblingsRootComponentFactory());
    String text(String selector) =>
        root.location.querySelector(selector)!.textContent!;

    // a is 1 makes the first sibling throw, while the second is marked.
    await outside(() {
      a.set(1);
      b.set(1);
    });
    expect(errors, isNotEmpty);

    // Once the first sibling no longer throws, a change to the second's
    // signal renders it.
    errors.clear();
    await outside(() {
      a.set(0);
      b.set(2);
    });
    expect(text('#b'), '2');
  });
}

/// Sets a new value in a signal on every check, which schedules another pass,
/// as an effect reads it.
@Component(selector: 'loop', template: 'loop')
class LoopComponent implements AfterViewChecked, OnDestroy {
  final _ticks = signal(0);
  late final _reader = effect((_) => _ticks());

  LoopComponent() {
    _reader;
  }

  @override
  void ngOnDestroy() => _reader.destroy();

  @override
  void ngAfterViewChecked() {
    loopChecks++;
    if (loopChecks < loopCap) {
      _ticks.set(loopChecks);
    }
  }
}

/// Reads a signal, then sets it to a new value, each time it is checked.
@Component(
  selector: 'self-setting',
  template: '{{bump()}}',
  changeDetection: ChangeDetectionStrategy.onPush,
)
class SelfSettingComponent {
  final _count = signal(0);

  int bump() {
    final count = _count();
    if (++loopChecks < loopCap) {
      _count.set(count + 1);
    }
    return count;
  }
}

/// Reads [state], with a child that counts the checks of its view.
@Component(
  selector: 'signal-parent',
  template: '{{value()}}<check-counter name="signal"></check-counter>',
  directives: [CheckCounter],
)
class SignalParentComponent {
  int value() => state();
}

/// Shows a child that sets [a], which an effect reads, while it is checked.
@Component(
  selector: 'effect-toggle-parent',
  template:
      '<check-counter name="effect"></check-counter>'
      '<signal-setter *ngIf="show" [target]="target"></signal-setter>',
  directives: [CheckCounter, NgIf, SignalSetter],
)
class EffectToggleParent {
  var show = false;
  WritableSignal<int> get target => a;
}

/// [EffectToggleParent], with a signal that nothing reads.
@Component(
  selector: 'plain-toggle-parent',
  template:
      '<check-counter name="plain"></check-counter>'
      '<signal-setter *ngIf="show" [target]="target"></signal-setter>',
  directives: [CheckCounter, NgIf, SignalSetter],
)
class PlainToggleParent {
  var show = false;
  WritableSignal<int> get target => b;
}

/// Sets [target] when it is created.
@Component(selector: 'signal-setter', template: '')
class SignalSetter implements OnInit {
  @Input()
  late WritableSignal<int> target;

  @override
  // Without reading it, which would be a read of the view that checks it.
  void ngOnInit() => target.update((value) => value + 1);
}

/// An OnPush component that reads a computed value, whose child changes the
/// signal it is computed from, without changing it, while it is checked.
@Component(
  selector: 'even',
  template: '{{isEven()}}<even-bumper [count]="count"></even-bumper>',
  directives: [EvenBumper],
  changeDetection: ChangeDetectionStrategy.onPush,
)
class EvenComponent {
  final count = signal(0);
  late final isEven = computed(() => count() % 2 == 0);
}

/// Adds 2 to [count] each time its parent checks it.
@Component(selector: 'even-bumper', template: '')
class EvenBumper implements AfterViewChecked {
  @Input()
  late WritableSignal<int> count;

  @override
  void ngAfterViewChecked() {
    if (++bumps < loopCap) {
      count.update((value) => value + 2);
    }
  }
}

/// An OnPush list of OnPush rows, each of which reads one of [rowSignals].
@Component(
  selector: 'rows',
  template: '<row *ngFor="let value of values" [value]="value"></row>',
  directives: [NgFor, RowComponent],
  changeDetection: ChangeDetectionStrategy.onPush,
)
class RowsComponent {
  final ChangeDetectorRef _changeDetector;
  var values = List.of(rowSignals);

  RowsComponent(this._changeDetector);

  void removeRow(int index) {
    values = List.of(values)..removeAt(index);
    _changeDetector.markForCheck();
  }
}

/// Renders [value], and throws when it is -1.
@Component(
  selector: 'row',
  template: '<span class="row">{{text()}}</span>',
  changeDetection: ChangeDetectionStrategy.onPush,
)
class RowComponent {
  @Input()
  late WritableSignal<int> value;

  String text() {
    final current = value();
    if (current == -1) throw StateError('row is -1');
    return '$current';
  }
}

/// [SignalParentComponent] without the signal.
@Component(
  selector: 'plain-parent',
  template: '{{value()}}<check-counter name="plain"></check-counter>',
  directives: [CheckCounter],
)
class PlainParentComponent {
  int value() => 0;
}

/// Counts the checks of its view in [counterChecks].
@Component(selector: 'check-counter', template: '')
class CheckCounter implements AfterViewChecked {
  @Input()
  String name = '';

  @override
  void ngAfterViewChecked() =>
      counterChecks[name] = (counterChecks[name] ?? 0) + 1;
}

/// Shows a [ThrowingReaderComponent] while [show] is set.
@Component(
  selector: 'throwing-reader-host',
  template: '<throwing-reader *ngIf="show"></throwing-reader>',
  directives: [NgIf, ThrowingReaderComponent],
)
class ThrowingReaderHost {
  var show = false;
}

/// Reads [a], then throws, on every check.
@Component(selector: 'throwing-reader', template: '{{value()}}{{boom()}}')
class ThrowingReaderComponent {
  int value() => a();

  int boom() => throw StateError('boom');
}

/// The [ManualRowsComponent] of the test that runs.
ManualRowsComponent? manualRows;

@Component(
  selector: 'manual-rows-root',
  template: '<manual-rows-parent></manual-rows-parent>',
  directives: [ManualRowsParent],
)
class ManualRowsRoot {}

/// An OnPush view that is not checked, in which [ManualRowsComponent] puts
/// the views of its container.
@Component(
  selector: 'manual-rows-parent',
  template: '<manual-rows></manual-rows>',
  directives: [ManualRowsComponent],
  changeDetection: ChangeDetectionStrategy.onPush,
)
class ManualRowsParent {}

/// Creates two [RemoverRow]s in its container, which read [rowSignals].
@Component(selector: 'manual-rows', template: '')
class ManualRowsComponent {
  final ViewContainerRef container;
  final ChangeDetectorRef _changeDetector;

  ManualRowsComponent(this.container, this._changeDetector) {
    manualRows = this;
  }

  void addRows() {
    for (var i = 0; i < 2; i++) {
      container
          .createComponent<RemoverRow>(ng.createRemoverRowFactory())
          .instance
        ..value = rowSignals[i]
        // The first row removes the second when it reads 2.
        ..onTwo = i == 0 ? () => container.remove(1) : null;
    }
    // Checks the OnPush view above, which renders the rows, once.
    _changeDetector.markForCheck();
  }
}

/// Renders [value], and calls [onTwo] once when it reads 2.
@Component(
  selector: 'remover-row',
  template: '{{text()}}',
  changeDetection: ChangeDetectionStrategy.onPush,
)
class RemoverRow {
  late WritableSignal<int> value;
  void Function()? onTwo;

  String text() {
    final current = value();
    if (current == 2) {
      final callback = onTwo;
      onTwo = null;
      callback?.call();
    }
    return '$current';
  }
}

/// Reads no signal itself: its child reads [state] in an input setter.
@Component(
  selector: 'input-reader-parent',
  template:
      '<check-counter name="input"></check-counter>'
      '<input-reader [value]="value"></input-reader>',
  directives: [CheckCounter, InputReader],
)
class InputReaderParent {
  var value = 0;
}

/// Reads [state] when its input is set above 0.
@Component(selector: 'input-reader', template: '')
class InputReader {
  @Input()
  set value(int value) {
    if (value > 0) state();
  }
}

/// A root component whose host binding reads [state].
@Component(selector: 'themed-root', template: 'themed')
class ThemedRootComponent {
  @HostBinding('class.dark')
  bool get dark => state() == 1;
}

/// [ThemedRootComponent], with a child that sets [state] once checked.
@Component(
  selector: 'themed-setter-root',
  template: '<state-setter></state-setter>',
  directives: [StateSetter],
)
class ThemedSetterRootComponent {
  @HostBinding('class.dark')
  bool get dark => state() == 1;
}

/// Sets [state] to 1 once it is checked.
@Component(selector: 'state-setter', template: '')
class StateSetter implements AfterViewInit {
  @override
  void ngAfterViewInit() => state.set(1);
}

/// An OnPush component that renders [state].
@Component(
  selector: 'state-reader',
  template: '{{value()}}',
  changeDetection: ChangeDetectionStrategy.onPush,
)
class StateReaderComponent {
  int value() => state();
}

/// Reads [state] only once [show] is set, after its first check.
@Component(
  selector: 'late-reader',
  template: '<span *ngIf="show">{{value()}}</span>',
  directives: [NgIf],
  changeDetection: ChangeDetectionStrategy.onPush,
)
class LateReaderComponent {
  final ChangeDetectorRef changeDetector;
  var show = false;

  LateReaderComponent(this.changeDetector);

  int value() => state();
}

/// Reads [state] before the child that sets it is checked.
@Component(
  selector: 'set-during-check-parent',
  template:
      '<span id="state">{{value()}}</span><set-during-check-child>'
      '</set-during-check-child>',
  directives: [SetDuringCheckChild],
  changeDetection: ChangeDetectionStrategy.onPush,
)
class SetDuringCheckParent {
  int value() => state();
}

/// Sets [state] once it is checked, while its parent is still being checked.
@Component(selector: 'set-during-check-child', template: '')
class SetDuringCheckChild implements AfterViewInit {
  @override
  void ngAfterViewInit() => state.set(1);
}

@Component(
  selector: 'hook-root',
  template: '<hook-parent></hook-parent>',
  directives: [HookParent],
)
class HookRootComponent {}

/// An OnPush component that reads no signal, and so is not marked.
@Component(
  selector: 'hook-parent',
  template: '<hook-child></hook-child>',
  directives: [HookChild],
  changeDetection: ChangeDetectionStrategy.onPush,
)
class HookParent {}

/// An OnPush component that reads [state], and counts its checks, and its
/// `ngDoCheck` calls.
@Component(
  selector: 'hook-child',
  template: '{{value()}}',
  changeDetection: ChangeDetectionStrategy.onPush,
)
class HookChild implements AfterViewChecked, DoCheck {
  int value() => state();

  @override
  void ngAfterViewChecked() => hookChecks++;

  @override
  void ngDoCheck() => doChecks++;
}

@Component(
  selector: 'siblings-root',
  template: '<siblings-parent></siblings-parent>',
  directives: [SiblingsParent],
)
class SiblingsRootComponent {}

/// An OnPush component that reads no signal, with two OnPush children.
@Component(
  selector: 'siblings-parent',
  template:
      '<throwing-sibling></throwing-sibling><plain-sibling>'
      '</plain-sibling>',
  directives: [ThrowingSibling, PlainSibling],
  changeDetection: ChangeDetectionStrategy.onPush,
)
class SiblingsParent {}

/// Throws when it is checked while [a] is 1.
@Component(
  selector: 'throwing-sibling',
  template: '<span id="a">{{value()}}</span>',
  changeDetection: ChangeDetectionStrategy.onPush,
)
class ThrowingSibling {
  int value() => a() == 1 ? throw StateError('a is 1') : a();
}

@Component(
  selector: 'plain-sibling',
  template: '<span id="b">{{value()}}</span>',
  changeDetection: ChangeDetectionStrategy.onPush,
)
class PlainSibling {
  int value() => b();
}

class _CollectingExceptionHandler implements ExceptionHandler {
  final List<Object> errors;

  _CollectingExceptionHandler(this.errors);

  @override
  void call(exception, [stackTrace, String? reason]) => errors.add(exception);
}

/// Calls [onChecked], once, when it is checked.
@Component(selector: 'root-destroyer', template: '')
class RootDestroyer implements AfterViewChecked {
  static void Function()? onChecked;

  @override
  void ngAfterViewChecked() {
    final callback = onChecked;
    onChecked = null;
    callback?.call();
  }
}
