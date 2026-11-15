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
    consumer = _Consumer(() => rendered.add(count()), () => changes++);
  });

  tearDown(() => consumer.dispose());

  test('check() runs the check', () {
    consumer.check();
    expect(rendered, [0]);
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

  test('drops the signals no longer read, on the check after a change', () {
    var readCount = true;
    final consumer = _Consumer(
      () => readCount ? count() : other(),
      () => changes++,
    )..check();
    addTearDown(consumer.dispose);
    count.set(1);
    readCount = false;
    consumer.check();
    count.set(2);
    expect(changes, 1, reason: 'count is no longer read');
    other.set(1);
    expect(changes, 2);
  });

  test('tells of a change after a change and a check', () {
    consumer.check();
    count.set(1);
    count.set(2);
    consumer.check();
    count.set(3);
    count.set(4);
    expect(changes, 2);
    expect(rendered, [0, 2]);
  });

  test('does not tell of a computed value that is unchanged', () {
    final isPositive = computed(() => count() > 0);
    final consumer = _Consumer(isPositive.call, () => changes++)..check();
    addTearDown(consumer.dispose);
    count.set(-1);
    expect(changes, 0);
    count.set(1);
    expect(changes, 1);
  });

  test('records nested checks separately', () {
    var innerChanges = 0;
    final inner = _Consumer(other.call, () => innerChanges++);
    addTearDown(inner.dispose);
    final outer = _Consumer(() {
      count();
      inner.check();
      count();
    }, () => changes++)..check();
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
    final consumer = _Consumer(
      () => ref ??= effect((_) => runs.add(source())),
      () {},
    )..check();
    addTearDown(consumer.dispose);
    consumer.check();
    source.set(1);
    expect(runs, [0, 1], reason: 'not stopped by the second check');
    ref!.destroy();
  });
}

/// A consumer that runs functions.
final class _Consumer extends ViewSignalConsumer {
  final void Function() _runCheck;
  final void Function() _onChanged;

  _Consumer(this._runCheck, this._onChanged);

  @override
  void runCheck() => _runCheck();

  @override
  void onChanged() => _onChanged();
}
