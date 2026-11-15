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
var hookChecks = 0;

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
    loopChecks = hookChecks = 0;
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

  test(
    'a signal runs the lifecycle hooks of the component that reads it',
    () async {
      await bootstrap(ng.createHookRootComponentFactory());
      final before = hookChecks;
      await outside(() => state.set(1));
      expect(hookChecks, greaterThan(before));
      expect(errors, isEmpty);
    },
  );

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

/// Sets a new value in a signal on every check, which schedules another pass.
@Component(selector: 'loop', template: 'loop')
class LoopComponent implements AfterViewChecked {
  final _ticks = signal(0);

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

/// An OnPush component that reads [state], and counts its checks.
@Component(
  selector: 'hook-child',
  template: '{{value()}}',
  changeDetection: ChangeDetectionStrategy.onPush,
)
class HookChild implements AfterViewChecked {
  int value() => state();

  @override
  void ngAfterViewChecked() => hookChecks++;
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
