import 'package:alien_signals/preset.dart'
    as alien
    show EffectCleanup, EffectNode, run, stop;
import 'package:alien_signals/system.dart' show ReactiveFlags;

/// **INTERNAL ONLY**: Tracks the signals that a view reads while it is
/// checked, and tells the view when one of them changes.
///
/// [check] runs the change detection of a view, and records the signals read
/// while it runs. When one of them changes, [onChanged] is called, once, such
/// as to mark the view for check. The signals are recorded again on the next
/// [check].
///
/// It is an [alien.EffectNode], as those are the only nodes that the signals
/// notify, and [check] runs through [alien.run], as an effect does, so that the
/// signals are recorded, and those no longer read are dropped, as for an
/// effect.
final class ViewSignalConsumer extends alien.EffectNode<void> {
  /// Called when a signal read in the last [check] changes.
  final void Function() onChanged;

  final void Function() _detectChanges;
  final void Function() _detectCrash;

  void Function()? _tracked;

  /// Creates a consumer for a view that its first function checks, or its
  /// second after a crash, and that [onChanged] marks for check.
  ///
  /// The functions are kept, rather than passed to [check], so that a check
  /// does not create a closure.
  ViewSignalConsumer(this._detectChanges, this._detectCrash, this.onChanged)
    : super(flags: ReactiveFlags.none, fn: _noop);

  /// Checks the view, recording the signals that it reads.
  void check() => _track(_detectChanges);

  /// Checks the view after a crash, recording the signals that it reads.
  void checkForCrash() => _track(_detectCrash);

  void _track(void Function() fn) {
    _tracked = fn;
    // Makes alien.run() run this node, which it does only when it is dirty.
    flags = ReactiveFlags.dirty;
    try {
      alien.run(this);
    } finally {
      _tracked = null;
    }
  }

  /// Stops tracking: [onChanged] is not called again.
  void dispose() => alien.stop(this);

  @override
  alien.EffectCleanup? runEffect() {
    final tracked = _tracked;
    if (tracked != null) {
      tracked();
    } else {
      // A signal changed. Nothing is read here, so alien.run() drops the
      // signals, which [track] records again when the view is checked.
      onChanged();
    }
    return null;
  }

  static void _noop() {}
}
