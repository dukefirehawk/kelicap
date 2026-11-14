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
  final NgZone _ngZone;
  late final StreamSubscription<void> _onMicrotaskEmptySub;

  var _pending = false;
  var _disposed = false;

  /// Creates a scheduler for the application that runs change detection in
  /// [ngZone].
  ///
  /// It must be created before the application listens to
  /// [NgZone.onMicrotaskEmpty], so that it learns of each pass before the pass
  /// runs, and a request made during a pass schedules another.
  ChangeDetectionScheduler(this._ngZone) {
    _onMicrotaskEmptySub = _ngZone.onMicrotaskEmpty.listen((_) {
      _pending = false;
    });
  }

  /// Whether a pass has been requested and has not started yet.
  bool get isPending => _pending;

  /// Requests a change detection pass.
  ///
  /// The pass runs in a microtask, or earlier, at the end of the current
  /// [NgZone] turn, if there is one. Calling this again before the pass starts
  /// has no effect, and calling it during a pass requests another.
  void schedule() {
    if (_pending || _disposed) {
      return;
    }
    _pending = true;
    // Scheduled outside the zone, so that the microtask does not delay the end
    // of the current turn, if there is one, and the pass that follows it.
    _ngZone.runOutsideKelicap(() => scheduleMicrotask(_flush));
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

  /// Stops this scheduler: requests made before or after are ignored.
  void dispose() {
    _disposed = true;
    _pending = false;
    _onMicrotaskEmptySub.cancel();
  }

  static void _noop() {}
}
