import 'package:test/test.dart';
import 'package:kelicap/signals.dart';

void main() {
  group('signal', () {
    test('reads the value it was created with', () {
      expect(signal(1)(), 1);
    });

    test('set() changes the value', () {
      final count = signal(1)..set(2);
      expect(count(), 2);
    });

    test('update() sets the value from the current one', () {
      final count = signal(1)..update((value) => value + 1);
      expect(count(), 2);
    });

    test('asReadonly() reads the value of the signal', () {
      final count = signal(1);
      final readonly = count.asReadonly();
      count.set(2);
      expect(readonly, isNot(isA<WritableSignal<int>>()));
      expect(readonly(), 2);
    });

    test('does not notify for a value that is equal', () {
      final name = signal(
        'a',
        equal: (a, b) => a.toLowerCase() == b.toLowerCase(),
      );
      var runs = 0;
      final ref = effect((_) {
        name();
        runs++;
      });
      name.set('a');
      name.set('A');
      expect(runs, 1);
      expect(name(), 'a');
      name.set('b');
      expect(runs, 2);
      ref.destroy();
    });
  });

  group('computed', () {
    test('derives its value from signals', () {
      final count = signal(2);
      final doubled = computed(() => count() * 2);
      expect(doubled(), 4);
      count.set(3);
      expect(doubled(), 6);
    });

    test('computes lazily, and caches its value', () {
      final count = signal(2);
      var runs = 0;
      final doubled = computed(() {
        runs++;
        return count() * 2;
      });
      expect(runs, 0);
      doubled();
      doubled();
      expect(runs, 1);
      count.set(3);
      expect(runs, 1);
      doubled();
      expect(runs, 2);
    });
  });

  group('effect', () {
    test('runs now, and again when a signal it read changes', () {
      final count = signal(0);
      final seen = <int>[];
      final ref = effect((_) => seen.add(count()));
      count.set(1);
      count.set(2);
      expect(seen, [0, 1, 2]);
      ref.destroy();
    });

    test('runs its cleanup before running again, and when destroyed', () {
      final count = signal(0);
      final log = <String>[];
      final ref = effect((onCleanup) {
        final value = count();
        log.add('run $value');
        onCleanup(() => log.add('cleanup $value'));
      });
      count.set(1);
      ref.destroy();
      expect(log, ['run 0', 'cleanup 0', 'run 1', 'cleanup 1']);
    });

    test('does not run after it is destroyed', () {
      final count = signal(0);
      var runs = 0;
      effect((_) {
        count();
        runs++;
      }).destroy();
      count.set(1);
      expect(runs, 1);
    });
  });

  test('untracked() reads a signal without tracking it', () {
    final count = signal(0);
    final other = signal(0);
    var runs = 0;
    final ref = effect((_) {
      count();
      untracked(other.call);
      runs++;
    });
    other.set(1);
    expect(runs, 1);
    count.set(1);
    expect(runs, 2);
    ref.destroy();
  });

  test('batch() runs effects once, when it returns', () {
    final first = signal('a');
    final last = signal('b');
    final seen = <String>[];
    final ref = effect((_) => seen.add('${first()} ${last()}'));
    final result = batch(() {
      first.set('c');
      last.set('d');
      expect(seen, ['a b'], reason: 'not during the batch');
      return 42;
    });
    expect(result, 42);
    expect(seen, ['a b', 'c d']);
    ref.destroy();
  });
}
