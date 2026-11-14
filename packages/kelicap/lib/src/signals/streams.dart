import 'dart:async';

import 'signals.dart';

/// A [Signal] whose value is the latest event of a stream.
///
/// Created by [toSignal]. Call [cancel] to stop listening to the stream, such
/// as in `ngOnDestroy`.
abstract interface class StreamSignal<T> implements Signal<T> {
  /// Stops listening to the stream: the value does not change again.
  Future<void> cancel();
}

/// Returns a [Signal] whose value is the latest event of [stream], and
/// [initialValue] before the first.
///
/// It listens to [stream] until [StreamSignal.cancel] is called, or the stream
/// is done. If the stream sends an error, reading the signal throws it, until
/// the stream sends an event.
///
/// Each event sets the signal, which renders the components that read it, as
/// setting a [WritableSignal] does, even if the stream is listened to outside
/// of the `NgZone`.
///
/// ```dart
/// class ClockComponent implements OnDestroy {
///   final now = toSignal(
///     Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now()),
///     initialValue: DateTime.now(),
///   );
///
///   @override
///   void ngOnDestroy() => now.cancel();
/// }
/// ```
StreamSignal<T> toSignal<T>(Stream<T> stream, {required T initialValue}) =>
    _StreamSignal(stream, initialValue);

/// Returns a stream of the values of [source]: its value when the stream is
/// listened to, and each value it changes to after that.
///
/// The values are sent asynchronously, so a value that is set and changed
/// again before it is sent is not sent. Each listen to the returned stream
/// tracks [source] separately, until it is cancelled.
///
/// ```dart
/// final query = signal('');
/// toStream(query).listen(search);
/// ```
Stream<T> toStream<T>(Signal<T> source) {
  late StreamController<T> controller;
  EffectRef? tracking;
  // The latest value, sent once the effect has stopped running, so that a
  // listener that sets a signal does not do so while the effect runs.
  var scheduled = false;
  late T latest;

  void send() {
    scheduled = false;
    if (tracking != null) {
      controller.add(latest);
    }
  }

  controller = StreamController<T>(
    onListen: () {
      tracking = effect((_) {
        latest = source();
        if (!scheduled) {
          scheduled = true;
          scheduleMicrotask(send);
        }
      });
    },
    onCancel: () {
      tracking?.destroy();
      tracking = null;
    },
  );
  return controller.stream;
}

/// The value of a [_StreamSignal]: an event of the stream, or an error.
sealed class _Value<T> {}

final class _Event<T> implements _Value<T> {
  final T value;

  _Event(this.value);
}

final class _Error<T> implements _Value<T> {
  final Object error;
  final StackTrace stackTrace;

  _Error(this.error, this.stackTrace);
}

final class _StreamSignal<T> implements StreamSignal<T> {
  final WritableSignal<_Value<T>> _value;
  late final StreamSubscription<T> _subscription;

  _StreamSignal(Stream<T> stream, T initialValue)
    : _value = signal<_Value<T>>(_Event(initialValue), equal: _sameEvent) {
    _subscription = stream.listen(
      (event) => _value.set(_Event(event)),
      onError: (Object error, StackTrace stackTrace) =>
          _value.set(_Error(error, stackTrace)),
    );
  }

  @override
  T call() => switch (_value()) {
    _Event(:final value) => value,
    _Error(:final error, :final stackTrace) => Error.throwWithStackTrace(
      error,
      stackTrace,
    ),
  };

  @override
  Future<void> cancel() => _subscription.cancel();

  /// Whether [a] and [b] are events of the same value, as for a signal that is
  /// set to the same value again, which notifies nothing.
  static bool _sameEvent<T>(_Value<T> a, _Value<T> b) =>
      a is _Event<T> && b is _Event<T> && identical(a.value, b.value);
}
