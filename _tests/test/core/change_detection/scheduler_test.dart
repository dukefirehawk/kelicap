import 'dart:async';

import 'package:test/test.dart';
import 'package:kelicap/kelicap.dart';
import 'package:kelicap/src/core/application_ref.dart';
import 'package:kelicap/src/core/change_detection/scheduler.dart';
import 'package:kelicap/src/core/linker/app_view_utils.dart';
import 'package:kelicap/src/runtime/dom_events.dart';

import 'scheduler_test.template.dart' as ng;

void main() {
  late NgZone ngZone;
  late ApplicationRef appRef;
  late ChangeDetectionScheduler scheduler;
  late ComponentRef<CounterComponent> counter;
  late List<StreamSubscription<void>> subs;

  // Change detection passes since the app was bootstrapped and settled.
  var passes = 0;

  /// Lets the microtasks that are queued run.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  setUp(() async {
    ngZone = NgZone();
    appRef = internalCreateApplicationRef(
      ngZone,
      Injector.map({ExceptionHandler: _RethrowingExceptionHandler()}),
    );
    appViewUtils = AppViewUtils('appId', EventManager(ngZone));
    scheduler = appRef.changeDetectionScheduler;
    counter = appRef.bootstrap(ng.createCounterComponentFactory());
    await settle();
    passes = 0;
    // Subscribed after the app, so this runs after each pass.
    subs = [ngZone.onMicrotaskEmpty.listen((_) => passes++)];
  });

  tearDown(() {
    for (final sub in subs) {
      sub.cancel();
    }
    CounterComponent.onViewChecked = null;
    appRef.dispose();
  });

  test('a change made outside the zone is not rendered on its own', () async {
    ngZone.runOutsideKelicap(() => counter.instance.count = 1);
    await settle();
    expect(counter.location.textContent, '0');
    expect(passes, 0);
  });

  test('schedule() renders a change made outside the zone', () async {
    ngZone.runOutsideKelicap(() {
      counter.instance.count = 1;
      scheduler.schedule();
    });
    expect(scheduler.isPending, isTrue);
    expect(counter.location.textContent, '0', reason: 'not synchronously');
    await settle();
    expect(counter.location.textContent, '1');
    expect(scheduler.isPending, isFalse);
    expect(passes, 1);
  });

  test('requests before a pass are merged into one pass', () async {
    ngZone.runOutsideKelicap(() {
      for (var i = 1; i <= 3; i++) {
        counter.instance.count = i;
        scheduler.schedule();
      }
    });
    await settle();
    expect(counter.location.textContent, '3');
    expect(passes, 1);
  });

  test('a request in a zone turn uses the pass that ends the turn', () async {
    ngZone.run(() {
      counter.instance.count = 1;
      scheduler.schedule();
    });
    expect(counter.location.textContent, '1', reason: 'at the end of the turn');
    expect(scheduler.isPending, isFalse);
    await settle();
    expect(passes, 1);
  });

  test('a request during a pass schedules another pass', () async {
    // Changing a binding here would fail the dev mode check, so this only
    // requests a pass, and does not throw for calling tick() recursively.
    var checks = 0;
    CounterComponent.onViewChecked = () {
      if (checks++ == 0) {
        scheduler.schedule();
      }
    };
    ngZone.runOutsideKelicap(scheduler.schedule);
    await settle();
    expect(passes, 2);
    expect(scheduler.isPending, isFalse);
  });

  test('dispose() stops scheduling', () async {
    appRef.dispose();
    ngZone.runOutsideKelicap(scheduler.schedule);
    expect(scheduler.isPending, isFalse);
    await settle();
    expect(passes, 0);
  });
}

@Component(selector: 'counter', template: '{{count}}')
class CounterComponent implements AfterViewChecked {
  static void Function()? onViewChecked;

  var count = 0;

  @override
  void ngAfterViewChecked() => onViewChecked?.call();
}

class _RethrowingExceptionHandler implements ExceptionHandler {
  @override
  void call(exception, [stackTrace, String? reason]) => throw exception;
}
