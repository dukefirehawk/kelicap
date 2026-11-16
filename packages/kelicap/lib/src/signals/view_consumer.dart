import 'package:alien_signals/preset.dart'
    as alien
    show EffectCleanup, EffectNode, PresetReactiveSystem, run, stop;
import 'package:alien_signals/system.dart' show Link, ReactiveFlags;

/// **INTERNAL ONLY**: How many times a signal or a computed value was read.
///
/// A view that has not read a signal yet is checked without a
/// [ViewSignalConsumer], which costs less, and compares it before and after
/// its check to learn whether it needs one. A count, rather than a flag that
/// the view resets and restores, costs the views that read no signal, most of
/// them, only a read and a comparison. Code whose reads are not those of the
/// view that is checked, such as a view that records its own, or an effect,
/// sets it back once it has run.
var signalReads = 0;

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

  /// The last of the signals that the last [check] recorded, if any.
  Link? _lastDep;

  ViewSignalConsumer() : super(flags: ReactiveFlags.none, fn: _noop);

  /// Checks the view, after a crash too: the view tells which.
  void runCheck();

  /// Called when a signal read in the last [check] changes.
  void onChanged();

  /// Checks the view, recording the signals that it reads.
  ///
  /// Returns whether a signal that it read changed while it was checked, after
  /// it was read, which [onChanged] is not called for: the view must be
  /// checked again.
  bool check() {
    if (_disposed) {
      // A destroyed view, which is not checked unless something is wrong:
      // checked without recording the signals it reads, which would keep it
      // alive, and notify it.
      runCheck();
      return false;
    }
    _checking = true;
    // Makes alien.run() run this node, which it does only when it is dirty.
    flags = ReactiveFlags.dirty;
    try {
      alien.run(this);
    } finally {
      _checking = false;
      // The last of the signals recorded, which alien.run() clears before it
      // runs this node for a change, and [runEffect] restores.
      _lastDep = depsTail;
    }
    // A signal that this node read, and that changes while it runs, marks it
    // pending, rather than notifying it, as it is running. A computed value
    // that it read may still have the same value, which checkDirty() tells,
    // as alien.run() does.
    if ((flags & ReactiveFlags.pending) == ReactiveFlags.none) {
      return false;
    }
    final deps = this.deps;
    if (deps == null ||
        !const alien.PresetReactiveSystem().checkDirty(deps, this)) {
      // Watching again, as after a check in which nothing changed.
      flags = ReactiveFlags.watching;
      return false;
    }
    // Dirty and not watching, as after onChanged(): the node is not notified
    // again until the next check, which records the signals anew.
    flags = ReactiveFlags.dirty;
    return true;
  }

  /// Whether the last [check] recorded a signal.
  bool get hasDependencies => deps != null;

  var _disposed = false;

  /// Stops tracking: [onChanged] is not called again.
  void dispose() {
    _disposed = true;
    alien.stop(this);
  }

  @override
  alien.EffectCleanup? runEffect() {
    if (_checking) {
      runCheck();
      return null;
    }
    // A signal changed.
    onChanged();
    // Keeps the signals recorded, which alien.run() would drop as nothing was
    // read, so that the next check finds them, rather than records them anew.
    // They have not changed since the last check, which recorded the last.
    depsTail = _lastDep;
    // Dirty and not watching, the node is not notified again until the next
    // check, which makes it watch. alien.run() then clears recursedCheck.
    flags = ReactiveFlags.dirty | ReactiveFlags.recursedCheck;
    return null;
  }

  static void _noop() {}
}
