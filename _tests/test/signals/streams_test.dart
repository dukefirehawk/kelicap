import 'dart:async';

import 'package:test/test.dart';
import 'package:kelicap/signals.dart';

void main() {
  /// Lets the events and microtasks that are queued run.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  group('toSignal', () {
    late StreamController<int> controller;
    late StreamSignal<int> value;

    setUp(() {
      controller = StreamController<int>();
      value = toSignal(controller.stream, initialValue: 0);
    });

    tearDown(() => value.cancel());

    test('reads the initial value before the first event', () {
      expect(value(), 0);
    });

    test('reads the latest event', () async {
      controller
        ..add(1)
        ..add(2);
      await settle();
      expect(value(), 2);
    });

    test('notifies the code that reads it of each event', () async {
      final seen = <int>[];
      final ref = effect((_) => seen.add(value()));
      controller.add(1);
      await settle();
      controller.add(2);
      await settle();
      expect(seen, [0, 1, 2]);
      ref.destroy();
    });

    test('does not notify of an event of the same value', () async {
      var runs = 0;
      final ref = effect((_) {
        value();
        runs++;
      });
      controller.add(0);
      await settle();
      expect(runs, 1);
      ref.destroy();
    });

    test('throws an error of the stream, until the next event', () async {
      controller.addError(StateError('broken'));
      await settle();
      expect(value.call, throwsStateError);
      controller.add(3);
      await settle();
      expect(value(), 3);
    });

    test('does not change after it is cancelled', () async {
      await value.cancel();
      expect(controller.hasListener, isFalse);
      controller.add(1);
      await settle();
      expect(value(), 0);
    });

    test('keeps its last value once the stream is done', () async {
      controller.add(1);
      await controller.close();
      expect(value(), 1);
    });
  });

  group('toStream', () {
    test('sends the value when listened to, and each change', () async {
      final count = signal(0);
      final seen = <int>[];
      final subscription = toStream(count).listen(seen.add);
      await settle();
      count.set(1);
      await settle();
      count.set(2);
      await settle();
      expect(seen, [0, 1, 2]);
      await subscription.cancel();
    });

    test('sends only the latest of the changes made at once', () async {
      final count = signal(0);
      final seen = <int>[];
      final subscription = toStream(count).listen(seen.add);
      await settle();
      count
        ..set(1)
        ..set(2);
      await settle();
      expect(seen, [0, 2]);
      await subscription.cancel();
    });

    test('sends the values of a computed value', () async {
      final count = signal(1);
      final doubled = computed(() => count() * 2);
      final seen = <int>[];
      final subscription = toStream(doubled).listen(seen.add);
      await settle();
      count.set(2);
      await settle();
      expect(seen, [2, 4]);
      await subscription.cancel();
    });

    test('stops tracking the signal when cancelled', () async {
      final count = signal(0);
      final seen = <int>[];
      final subscription = toStream(count).listen(seen.add);
      await settle();
      await subscription.cancel();
      count.set(1);
      await settle();
      expect(seen, [0]);
    });

    test('may be listened to more than once', () async {
      final count = signal(0);
      final stream = toStream(count);
      final first = <int>[];
      final second = <int>[];
      final a = stream.listen(first.add);
      final b = stream.listen(second.add);
      await settle();
      count.set(1);
      await settle();
      await a.cancel();
      count.set(2);
      await settle();
      expect(first, [0, 1]);
      expect(second, [0, 1, 2]);
      await b.cancel();
    });

    test('may be listened to again after it is cancelled', () async {
      final count = signal(0);
      final stream = toStream(count);
      await stream.listen((_) {}).cancel();
      count.set(1);
      final seen = <int>[];
      final subscription = stream.listen(seen.add);
      await settle();
      expect(seen, [1]);
      await subscription.cancel();
    });

    test('sends an error of the source to the stream', () async {
      final count = signal(0);
      final checked = computed(
        () => count() == 1 ? throw StateError('count is 1') : count(),
      );
      final errors = <Object>[];
      final subscription = toStream(checked)
          .listen((_) {}, onError: (Object error) => errors.add(error));
      await settle();
      expect(() => count.set(1), returnsNormally);
      await settle();
      expect(errors, [isStateError]);
      await subscription.cancel();
    });

    test('a listener may set a signal', () async {
      final count = signal(0);
      final copy = signal(-1);
      final subscription = toStream(count).listen(copy.set);
      await settle();
      count.set(5);
      await settle();
      expect(copy(), 5);
      await subscription.cancel();
    });

    test(
      'listened to in an effect, keeps sending once it runs again',
      () async {
        final count = signal(0);
        final trigger = signal(0);
        final seen = <int>[];
        StreamSubscription<int>? subscription;
        final outer = effect((_) {
          trigger();
          subscription ??= toStream(count).listen(seen.add);
        });
        await settle();
        // Runs the outer effect again, which stops the effects it owns.
        trigger.set(1);
        count.set(1);
        await settle();
        expect(seen, [0, 1]);
        outer.destroy();
        await subscription!.cancel();
      },
    );
  });
}
