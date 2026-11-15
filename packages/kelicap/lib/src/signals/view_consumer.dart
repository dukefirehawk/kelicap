import 'package:alien_signals/preset.dart'
    as alien
    show EffectCleanup, EffectNode, run, stop;
import 'package:alien_signals/system.dart' show Link, ReactiveFlags;

/// **INTERNAL ONLY**: Whether a signal or a computed value was read since a
/// view reset it.
///
/// A view that has not read a signal yet is checked without a
/// [ViewSignalConsumer], which costs less, and reads it to learn whether it
/// needs one. Setting a field costs less than asking whether a view is being
/// checked, on each read.
var signalRead = false;

/// **INTERNAL ONLY**: Tracks the signals that a view reads while it is
/// checked, and tells the view when one of them changes.
///
/// [check] runs [detectChanges], and records the signals read while it runs.
/// When one of them changes, [onChanged] is called, once, such as to mark the
/// view for check. The signals are recorded again on the next [check].
///
/// It is an [alien.EffectNode], as those are the only nodes that the signals
/// notify, and [check] runs through [alien.run], as an effect does, so that the
/// signals are recorded, and those no longer read are dropped, as for an
/// effect.
///
/// The view's functions are methods, rather than functions passed to it, so
/// that calling them does not go through a closure, as [onChanged] is called
/// for each signal that changes.
abstract base class ViewSignalConsumer extends alien.EffectNode<void> {
  /// Whether [runEffect] runs for a [check], rather than for a change.
  var _checking = false;
  var _forCrash = false;

  ViewSignalConsumer() : super(flags: ReactiveFlags.none, fn: _noop);

  /// Checks the view.
  void detectChanges();

  /// Checks the view after a crash.
  void detectCrash();

  /// Called when a signal read in the last [check] changes.
  void onChanged();

  /// Checks the view, recording the signals that it reads.
  ///
  /// Returns whether a signal that it read changed while it was checked, after
  /// it was read, which [onChanged] is not called for: the view must be
  /// checked again.
  bool check() => _track(forCrash: false);

  /// Checks the view after a crash, recording the signals that it reads.
  ///
  /// Returns what [check] does.
  bool checkForCrash() => _track(forCrash: true);

  bool _track({required bool forCrash}) {
    _checking = true;
    _forCrash = forCrash;
    // Makes alien.run() run this node, which it does only when it is dirty.
    flags = ReactiveFlags.dirty;
    try {
      alien.run(this);
    } finally {
      _checking = false;
    }
    // A signal that this node read, and that changes while it runs, marks it
    // pending, rather than notifying it, as it is running.
    if ((flags & ReactiveFlags.pending) == ReactiveFlags.none) {
      return false;
    }
    // Dirty and not watching, as after onChanged(): the node is not notified
    // again until the next check, which records the signals anew.
    flags = ReactiveFlags.dirty;
    return true;
  }

  /// Stops tracking: [onChanged] is not called again.
  void dispose() => alien.stop(this);

  @override
  alien.EffectCleanup? runEffect() {
    if (_checking) {
      if (_forCrash) {
        detectCrash();
      } else {
        detectChanges();
      }
      return null;
    }
    // A signal changed.
    onChanged();
    // Keeps the signals recorded, which alien.run() would drop as nothing was
    // read, so that the next check finds them, rather than records them anew.
    var last = deps;
    if (last != null) {
      for (Link? next; (next = last!.nextDep) != null;) {
        last = next;
      }
    }
    depsTail = last;
    // Dirty and not watching, the node is not notified again until the next
    // check, which makes it watch. alien.run() then clears recursedCheck.
    flags = ReactiveFlags.dirty | ReactiveFlags.recursedCheck;
    return null;
  }

  static void _noop() {}
}
