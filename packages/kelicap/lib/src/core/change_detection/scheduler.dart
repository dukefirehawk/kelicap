import 'dart:async';

import '../zone/ng_zone.dart';

/// **INTERNAL ONLY**: Requests change detection for an application, merging
/// the requests made before it runs into a single pass.
///
/// [NgZone] runs change detection after the callbacks that run in it, such as
/// event handlers and timers. This scheduler is for changes that it does not
/// see, such as those made from code that runs outside it
/// ([NgZone.runOutsideKelicap]): [schedule] requests a pass, however many
/// times it is called before that pass starts.
///
/// The pass runs through [NgZone]: the scheduler enters and leaves it, which
/// ends a turn, so that the zone reports [NgZone.onMicrotaskEmpty], and the
/// application runs change detection as it does after any other turn. Error
/// handling, and the turn events that tests wait on, are therefore the same
/// for both.
final class ChangeDetectionScheduler {
  /// The schedulers of the applications that are running.
  ///
  /// A list, as iterating it is cheaper than a set, and it is iterated on each
  /// change to a signal.
  static final _active = <ChangeDetectionScheduler>[];

  /// Requests a change detection pass in every application that is running.
  ///
  /// Used when state that any of them may render changes, such as a signal.
  static void scheduleAll() {
    final active = _active;
    for (var i = 0, length = active.length; i < length; i++) {
      active[i].schedule();
    }
  }

  /// How many passes in a row may each request another, such as by setting a
  /// signal in `ngAfterViewChecked`, before the scheduler stops requesting
  /// them, as they would otherwise run forever.
  static const maxPassesInARow = 100;

  final NgZone _ngZone;
  final void Function(Object error, StackTrace stackTrace) _onError;
  late final StreamSubscription<void> _onMicrotaskEmptySub;

  var _pending = false;
  var _disposed = false;

  /// Whether [runPass] is running a pass.
  var _inPass = false;

  /// Whether a pass has been requested during the pass that [runPass] runs.
  var _requestedInPass = false;

  /// How many passes in a row have each requested another.
  var _passesInARow = 0;

  /// Creates a scheduler for the application that runs change detection in
  /// [ngZone], which reports to [onError] passes that request another without
  /// end.
  ///
  /// It must be created before the application listens to
  /// [NgZone.onMicrotaskEmpty], so that it learns of each pass before the pass
  /// runs, and a request made during a pass schedules another.
  ChangeDetectionScheduler(
    this._ngZone,
    void Function(Object error, StackTrace stackTrace) onError,
  ) : _onError = onError {
    _onMicrotaskEmptySub = _ngZone.onMicrotaskEmpty.listen((_) {
      _pending = false;
    });
    _active.add(this);
  }

  /// Whether a pass has been requested and has not started yet.
  bool get isPending => _pending;

  /// Requests a change detection pass.
  ///
  /// The pass runs in a microtask, or earlier, at the end of the current
  /// [NgZone] turn, if there is one. Calling this again before the pass starts
  /// has no effect, and calling it during a pass requests another.
  void schedule() {
    if (_inPass) {
      _requestedInPass = true;
    }
    if (_pending || _disposed) {
      return;
    }
    // Requested in an NgZone turn too: the turn may have run its pass already,
    // such as when this is called from a listener of onMicrotaskEmpty. If it
    // has not, the pass clears the request, and the microtask does nothing.
    _pending = true;
    // Scheduled outside the zone, so that the microtask does not delay the end
    // of the current turn, if there is one, and the pass that follows it.
    _ngZone.runOutsideKelicap(() => scheduleMicrotask(_flush));
  }

  /// Runs [pass], a change detection pass of the application.
  ///
  /// If [maxPassesInARow] passes in a row each request another, the last
  /// request is dropped, and reported as an error, so that they stop.
  void runPass(void Function() pass) {
    _inPass = true;
    _requestedInPass = false;
    try {
      pass();
    } finally {
      _inPass = false;
    }
    if (!_requestedInPass) {
      _passesInARow = 0;
      return;
    }
    if (++_passesInARow < maxPassesInARow) {
      return;
    }
    _passesInARow = 0;
    _pending = false;
    _onError(
      StateError(
        '$maxPassesInARow change detection passes in a row each requested '
        'another, such as by setting a signal while they ran, in a lifecycle '
        'hook like ngAfterViewChecked: the next one is not run. Set a signal '
        'only when its value changes, or in an event handler.',
      ),
      StackTrace.current,
    );
  }

  void _flush() {
    // Cleared if the zone has run a pass since the request.
    if (!_pending || _disposed) {
      return;
    }
    // Ends a turn, after which the zone reports onMicrotaskEmpty, and the
    // application runs the pass, which clears _pending. If the zone is still
    // waiting for microtasks, it reports it, and clears it, once they have run.
    _ngZone.run(_noop);
  }

  /// Drops the pass that has been requested, if any, which has not started.
  ///
  /// Used when the passes would not end, such as when the views that signals
  /// mark are checked again too many times in a pass.
  void cancel() {
    _pending = false;
    _passesInARow = 0;
  }

  /// Stops this scheduler: requests made before or after are ignored.
  void dispose() {
    _active.remove(this);
    _disposed = true;
    _pending = false;
    _onMicrotaskEmptySub.cancel();
  }

  static void _noop() {}
}
