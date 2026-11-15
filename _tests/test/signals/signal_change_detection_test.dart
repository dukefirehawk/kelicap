import 'dart:async';

import 'package:test/test.dart';
import 'package:web/web.dart';
import 'package:kelicap/kelicap.dart';
import 'package:kelicap/signals.dart';
import 'package:kelicap/src/core/application_ref.dart';
import 'package:kelicap/src/core/change_detection/scheduler.dart';
import 'package:kelicap/src/core/linker/app_view_utils.dart';
import 'package:kelicap/src/runtime/dom_events.dart';

import 'signal_change_detection_test.template.dart' as ng;

void main() {
  late NgZone ngZone;
  late ApplicationRef appRef;
  late ChangeDetectionScheduler scheduler;
  late ComponentRef<CounterComponent> counter;

  /// Lets the microtasks that are queued run.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  String text(String selector) =>
      counter.location.querySelector(selector)!.textContent!;

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
  });

  tearDown(() => appRef.dispose());

  test('a template renders signals and computed values', () {
    expect(text('#count'), '0');
    expect(text('#doubled'), '0');
  });

  test('an event handler that sets a signal updates the template', () async {
    (counter.location.querySelector('button')! as HTMLElement).click();
    await settle();
    expect(text('#count'), '1');
    expect(text('#doubled'), '2');
  });

  test('setting a signal outside the zone updates the template', () async {
    ngZone.runOutsideKelicap(() => counter.instance.count.set(5));
    expect(scheduler.isPending, isTrue);
    await settle();
    expect(text('#count'), '5');
    expect(text('#doubled'), '10');
  });

  test('setting a signal to an equal value schedules nothing', () {
    ngZone.runOutsideKelicap(() => counter.instance.count.set(0));
    expect(scheduler.isPending, isFalse);
  });

  test('setting a signal schedules nothing once the app is disposed', () {
    appRef.dispose();
    ngZone.runOutsideKelicap(() => counter.instance.count.set(1));
    expect(scheduler.isPending, isFalse);
  });

  test('an OnPush component renders a signal set outside the zone', () async {
    final onPush = appRef.bootstrap<OnPushCounterComponent>(
      ng.createOnPushCounterComponentFactory(),
    );
    await settle();
    ngZone.runOutsideKelicap(() => onPush.instance.count.set(1));
    await settle();
    expect(onPush.location.textContent, '1');
  });
}

@Component(
  selector: 'counter',
  template: '''
    <span id="count">{{count()}}</span>
    <span id="doubled">{{doubled()}}</span>
    <button (click)="increment()">+</button>
  ''',
)
class CounterComponent {
  final count = signal(0);
  late final doubled = computed(() => count() * 2);

  void increment() => count.update((value) => value + 1);
}

@Component(
  selector: 'on-push-counter',
  template: '{{count()}}',
  changeDetection: ChangeDetectionStrategy.onPush,
)
class OnPushCounterComponent {
  final count = signal(0);
}

class _RethrowingExceptionHandler implements ExceptionHandler {
  @override
  void call(exception, [stackTrace, String? reason]) => throw exception;
}
