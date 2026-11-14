import 'package:test/test.dart';
import 'package:kelicap/signals.dart';
import 'package:kelicap/src/signals/view_consumer.dart';

void main() {
  late WritableSignal<int> count;
  late WritableSignal<int> other;
  late List<int> rendered;
  late int changes;
  late ViewSignalConsumer consumer;

  setUp(() {
    count = signal(0);
    other = signal(0);
    rendered = [];
    changes = 0;
    consumer = ViewSignalConsumer(
      () => rendered.add(count()),
      () => rendered.add(-count()),
      () => changes++,
    );
  });

  tearDown(() => consumer.dispose());

  test('check() runs the check', () {
    consumer.check();
    consumer.checkForCrash();
    expect(rendered, [0, -0]);
  });

  test('tells once that a signal read in the check changed', () {
    consumer.check();
    count.set(1);
    count.set(2);
    expect(changes, 1);
    expect(rendered, [0], reason: 'does not check again by itself');
  });

  test('does not tell of a signal not read in the check', () {
    consumer.check();
    other.set(1);
    expect(changes, 0);
  });

  test('records the signals again on the next check', () {
    consumer.check();
    count.set(1);
    consumer.check();
    count.set(2);
    expect(changes, 2);
    expect(rendered, [0, 1]);
  });

  test('records the signals read after a crash', () {
    consumer.checkForCrash();
    count.set(1);
    expect(changes, 1);
  });

  test('does not tell of a computed value that is unchanged', () {
    final isPositive = computed(() => count() > 0);
    final consumer = ViewSignalConsumer(isPositive.call, isPositive.call, () {
      changes++;
    })..check();
    addTearDown(consumer.dispose);
    count.set(-1);
    expect(changes, 0);
    count.set(1);
    expect(changes, 1);
  });

  test('records nested checks separately', () {
    var innerChanges = 0;
    final inner = ViewSignalConsumer(other.call, other.call, () {
      innerChanges++;
    });
    addTearDown(inner.dispose);
    final outer = ViewSignalConsumer(
      () {
        count();
        inner.check();
        count();
      },
      () {},
      () => changes++,
    )..check();
    addTearDown(outer.dispose);
    other.set(1);
    expect((changes, innerChanges), (0, 1));
    count.set(1);
    expect((changes, innerChanges), (1, 1));
  });

  test('does not tell after it is disposed', () {
    consumer
      ..check()
      ..dispose();
    count.set(1);
    expect(changes, 0);
  });

  test('does not own an effect created during a check', () {
    final source = signal(0);
    final runs = <int>[];
    EffectRef? ref;
    final consumer = ViewSignalConsumer(
      () => ref ??= effect((_) => runs.add(source())),
      () {},
      () {},
    )..check();
    addTearDown(consumer.dispose);
    consumer.check();
    source.set(1);
    expect(runs, [0, 1], reason: 'not stopped by the second check');
    ref!.destroy();
  });
}
