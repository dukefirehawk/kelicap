import 'package:alien_signals/alien_signals.dart'
    as alien
    show Effect, effect, endBatch, startBatch;
import 'package:alien_signals/preset.dart'
    show ComputedNode, SignalNode, getActiveSub, setActiveSub;
import 'package:alien_signals/system.dart' show ReactiveFlags;

import '../core/change_detection/scheduler.dart';
import 'view_consumer.dart';

/// A value that notifies the code that reads it when it changes.
///
/// Call it to read its value. A read in a [computed] value or an [effect] is
/// tracked: the computed value is recomputed, or the effect run again, when
/// the signal changes.
abstract interface class Signal<T> {
  /// Reads the value of this signal.
  T call();
}

/// A [Signal] whose value can be set.
///
/// Setting it to a new value runs change detection, in every application that
/// is running, even if the value was set outside of their [NgZone], such as in
/// code run with `NgZone.runOutsideKelicap`. It marks the components whose
/// templates read it for check, so an OnPush component that reads it is
/// updated without calling `ChangeDetectorRef.markForCheck`.
abstract interface class WritableSignal<T> implements Signal<T> {
  /// Sets the value of this signal to [value].
  ///
  /// Nothing is notified if [value] is equal to the current value, by the
  /// `equal` function given to [signal], which is [identical] by default. So
  /// after changing a list or map in place, set the signal to a new one.
  void set(T value);

  /// Sets the value of this signal to what [updater] returns for its current
  /// value.
  ///
  /// Reading the current value here is not tracked.
  void update(T Function(T value) updater);

  /// Returns a read-only view of this signal, which can be read but not set.
  Signal<T> asReadonly();
}

/// Whether [a] and [b] are equal values of a signal.
typedef ValueEqualityFn<T> = bool Function(T a, T b);

/// Registers a [cleanup] function to run before an [effect] runs again, and
/// when it is destroyed.
typedef EffectCleanupRegisterFn = void Function(void Function() cleanup);

/// A running [effect], which can be destroyed.
abstract interface class EffectRef {
  /// Stops the effect, and runs its cleanup functions.
  ///
  /// The effect is not run again.
  void destroy();
}

/// Creates a [WritableSignal] whose value is [initialValue].
///
/// [equal] tells whether a new value is the same as the current one, and so
/// notifies nothing. It is [identical] by default.
///
/// ```dart
/// @Component(
///   selector: 'counter',
///   template: '<button (click)="increment()">{{count()}}</button>',
/// )
/// class CounterComponent {
///   final count = signal(0);
///
///   void increment() => count.update((value) => value + 1);
/// }
/// ```
WritableSignal<T> signal<T>(T initialValue, {ValueEqualityFn<T>? equal}) =>
    _WritableSignal(initialValue, equal ?? identical);

/// Creates a read-only [Signal] whose value [computation] derives from other
/// signals.
///
/// [computation] runs when the value is first read, and is cached. It runs
/// again on a read after a signal it read has changed.
///
/// ```dart
/// final count = signal(2);
/// final doubled = computed(() => count() * 2);
/// ```
Signal<T> computed<T>(T Function() computation) => _Computed(computation);

/// Runs [fn] now, and again whenever a signal it read changes.
///
/// [fn] runs synchronously, as soon as a signal it read is set, or at the end
/// of a [batch]. Functions passed to its `onCleanup` argument run before it
/// runs again, and when the effect is destroyed. An effect is not destroyed
/// with the component that created it: call [EffectRef.destroy], such as in
/// `ngOnDestroy`.
///
/// ```dart
/// final ref = effect((onCleanup) {
///   final timer = Timer(const Duration(seconds: 1), () => save(form()));
///   onCleanup(timer.cancel);
/// });
/// ```
EffectRef effect(void Function(EffectCleanupRegisterFn onCleanup) fn) {
  // An effect is owned by the effect it is created in, which stops it when it
  // runs again. One created while a view is checked, such as by a component
  // that an *ngIf creates, is not owned by the view, which would stop it when
  // the view is checked again.
  final owner = getActiveSub();
  if (owner is! ViewSignalConsumer) {
    return _createEffect(fn);
  }
  setActiveSub(null);
  try {
    return _createEffect(fn);
  } finally {
    setActiveSub(owner);
  }
}

EffectRef _createEffect(void Function(EffectCleanupRegisterFn onCleanup) fn) =>
    _EffectRef(
      alien.effect<void Function()?>(() {
        List<void Function()>? cleanups;
        fn((cleanup) => (cleanups ??= []).add(cleanup));
        final registered = cleanups;
        if (registered == null) {
          return null;
        }
        return () {
          for (final cleanup in registered) {
            cleanup();
          }
        };
      }),
    );

/// Runs [fn] and returns its result, without tracking the signals it reads.
///
/// In a [computed] value or an [effect], use it to read a signal without
/// recomputing, or running again, when that signal changes.
T untracked<T>(T Function() fn) {
  final previous = setActiveSub(null);
  try {
    return fn();
  } finally {
    setActiveSub(previous);
  }
}

/// Runs [fn] and returns its result, running the [effect]s of the signals it
/// sets only once, when it returns.
T batch<T>(T Function() fn) {
  alien.startBatch();
  try {
    return fn();
  } finally {
    alien.endBatch();
  }
}

final class _WritableSignal<T> extends SignalNode<T>
    implements WritableSignal<T> {
  final ValueEqualityFn<T> _equal;

  _WritableSignal(T value, this._equal)
    : super(
        flags: ReactiveFlags.mutable,
        currentValue: value,
        pendingValue: value,
      );

  @override
  T call() => get();

  @override
  void set(T value) {
    // The value most recently set, which a batch has not committed yet.
    if (_equal(pendingValue, value)) {
      return;
    }
    super.set(value);
    ChangeDetectionScheduler.scheduleAll();
  }

  @override
  void update(T Function(T value) updater) => set(updater(pendingValue));

  @override
  Signal<T> asReadonly() => _ReadonlySignal(this);
}

final class _ReadonlySignal<T> implements Signal<T> {
  final Signal<T> _source;

  _ReadonlySignal(this._source);

  @override
  T call() => _source();
}

final class _Computed<T> extends ComputedNode<T> implements Signal<T> {
  _Computed(T Function() computation)
    : super(flags: ReactiveFlags.none, getter: (_) => computation());

  @override
  T call() => get();
}

final class _EffectRef implements EffectRef {
  final alien.Effect _effect;

  _EffectRef(this._effect);

  @override
  void destroy() => _effect();
}
