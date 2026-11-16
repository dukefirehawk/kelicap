import 'dart:async';

import 'package:kelicap_common/kelicap_common.dart';

import 'package:web/web.dart';

import 'package:meta/dart2js.dart' as dart2js;
import 'package:meta/meta.dart';

import '../../../core/change_detection/host.dart';
import '../../../core/linker/style_encapsulation.dart';
import '../../../devtools.dart';
import '../../../signals/view_consumer.dart';

import 'render_view.dart';
import 'view.dart';

/// The base type of a view that implements a component's template.
///
/// For every component (a class annotated with `@Component()`), the compiler
/// will generate exactly one component view that extends this class. This view
/// is used to create and change detect the component, wherever it's used
/// declaratively in another component's template.
///
/// In addition to those of [RenderView], this view's responsibilities include:
///
///   * Initializing the component's [rootElement] based on its selector.
///
///   * Initializing the component's [componentStyles].
///
/// The type parameter [T] is the type of the component whose template this view
/// implements. Note that it's the responsibility of the [parentView] to
/// instantiate the component instance and provide it to this view via [create]
/// or [createAndProject]. This is necessary to implement certain hierarchical
/// dependency injection semantics.
abstract class ComponentView<T extends Object> extends RenderView {
  ComponentView(
    View parentView,
    int parentIndex,
    ChangeDetectionCheckedState changeDetectionMode,
  ) : _data = _ComponentViewData(parentView, parentIndex, changeDetectionMode);

  @override
  late final T ctx;

  @override
  late final ComponentStyles componentStyles;

  /// The root element of this component, created from its selector.
  late final HTMLElement rootElement;

  final _ComponentViewData _data;

  // While projectNodes can _start_ null, it is never null by the time we access
  // it (nor do we query to check whether it is null). Getters cannot be late,
  // so this is effectively the same thing.
  @override
  List<List<Object>> get projectedNodes => _data.projectedNodes;

  @override
  View? get parentView => _data.parentView;

  @override
  int get parentIndex => _data.parentIndex;

  /// Returns whether this component view uses default change detection.
  ///
  /// This is only exposed for `debugUsesDefaultChangeDetection` and should not
  /// be referenced by any other means.
  @experimental
  bool get usesDefaultChangeDetection =>
      _data.changeDetectionMode == ChangeDetectionCheckedState.checkAlways;

  // Initialization ------------------------------------------------------------

  // TODO(b/129005490): remove as this is always overridden by derived view.
  @override
  void build() {}

  /// Specialized [createAndProject] when there's no projected content.
  ///
  /// This exists purely as a code size optimization.
  @dart2js.noInline
  void create(T component) {
    createAndProject(component, const []);
  }

  /// Creates this view for [component] with [projectedNodes].
  ///
  /// The [projectedNodes] are any content placed between the opening and
  /// closing tags of [component].
  void createAndProject(T component, List<List<Object>> projectedNodes) {
    ctx = component;
    _data.projectedNodes = projectedNodes;

    if (isDevToolsEnabled) {
      Inspector.instance.registerComponentView(this);
    }

    build();
  }

  /// Called by [build] once all subscriptions are created.
  @dart2js.noInline
  void initSubscriptions(List<StreamSubscription<void>> subscriptions) {
    _data.subscriptions = subscriptions;
  }

  /// Initializes styling to enable css shim for host element.
  ///
  /// The return value serves as a more efficient way of referencing
  /// [rootElement] within a component view's [build] implementation. It
  /// requires less code to assign the return value of a function that's going
  /// to be called anyways, than to generate an extra statement to load a field.
  @dart2js.noInline
  HTMLElement initViewRoot() {
    final hostElement = rootElement;
    componentStyles.addHostShimClassHtmlElement(hostElement);
    return hostElement;
  }

  // Destruction ---------------------------------------------------------------

  @override
  void destroyInternalState() {
    if (!_data.destroyed) {
      _data.destroy();
      destroyInternal();
    }
  }

  // Change detection ----------------------------------------------------------

  @override
  bool get firstCheck =>
      _data.changeDetectorState == ChangeDetectorState.neverChecked;

  @override
  void detectChangesDeprecated() {
    if (_data.shouldSkipChangeDetection) {
      if (_data.changeDetectionMode ==
          ChangeDetectionCheckedState.waitingForMarkForCheck) {
        detectChangesInCheckAlwaysViews();
        // Reaches the views below that were marked for refresh, without
        // checking the views on the way.
        if (hasMarkedDescendants) {
          detectChangesInMarkedViewsKeepingMarks();
        }
      }
      return;
    }

    // Checking this view checks the views below it, marked or not. Cleared
    // before the check, as a view below may be marked while it runs.
    clearMarkedDescendants();

    // Sanity check in dev-mode that a destroyed view is not checked again.
    if (isDevMode && _data.destroyed) {
      throw StateError('detectChanges');
    }

    // Records the signals that this view reads while it is checked, including
    // in its embedded views, so that it is marked for check when one of them
    // changes. Child component views record their own.
    //
    // Most views read none, and are checked without recording them, which is
    // written here, so that it is compiled inline, rather than in
    // [_checkRecordingSignals], which is not. A signal that such a view reads
    // first now is also recorded by the nearest view above it that records
    // them, which costs that view a check, at most, when it changes: its next
    // check no longer reads it.
    var checkAgain = false;
    if (_data.signals == null &&
        _data.changeDetectorState != ChangeDetectorState.neverChecked) {
      final reads = signalReads;
      detectChangesOrCrash();
      if (signalReads != reads) {
        checkAgain = _checkRecordingSignals(reads);
      }
    } else {
      checkAgain = _checkRecordingSignals(signalReads);
    }

    // Cleared once checked, rather than before: a view whose check throws
    // stays marked, so that the check that looks for the view that threw,
    // which goes only through marked views below views that are not checked,
    // reaches it. Nothing marks a view while it is checked, as a signal that
    // it read changing then is reported by [checkAgain].
    if (_data.needsRefresh) {
      _data.needsRefresh = false;
    }

    // If we are a 'CheckOnce' component, we are done being checked.
    if (_data.changeDetectionMode == ChangeDetectionCheckedState.checkOnce) {
      _data.changeDetectionMode =
          ChangeDetectionCheckedState.waitingForMarkForCheck;
    }

    // Set the state to already checked at least once.
    _data.changeDetectorState = ChangeDetectorState.checkedBefore;

    // A signal that this view read changed while it was checked, after it was
    // read, such as in a lifecycle hook of a child: checks it again, before
    // the pass ends.
    if (checkAgain) {
      markForRefresh();
    }
  }

  /// Checks this view, recording the signals that it reads: with its
  /// [ViewSignalConsumer], on its first check, or after a check without one
  /// that read a signal, which then runs again.
  ///
  /// Its first check records them. If it read none, it keeps no
  /// [ViewSignalConsumer], and is checked without one, which costs less,
  /// until it reads one: it is then checked again, recording them, which runs
  /// the lifecycle hooks of the directives in its template again.
  ///
  /// Returns whether a signal that it read changed while it was checked, as
  /// [ViewSignalConsumer.check] does.
  ///
  /// The signals that it reads do not count as those of the view above it:
  /// [signalReads] is set back to [reads], its count before this view was
  /// checked.
  @dart2js.noInline
  bool _checkRecordingSignals(int reads) {
    final signals = _data.signals;
    final checkAgain = signals != null
        ? signals.check()
        : _checkWithNewSignals(
            firstCheck:
                _data.changeDetectorState == ChangeDetectorState.neverChecked,
          );
    signalReads = reads;
    return checkAgain;
  }

  /// Checks this view with a new [ViewSignalConsumer].
  ///
  /// It is stored before the check, so that it is disposed with the view even
  /// if the check throws after it recorded a signal. On the first check, it is
  /// dropped if it recorded none. After a check without one that read a
  /// signal, it is kept even so: the view reads signals in some checks, such
  /// as in the setter of an input of a child, which runs only when the input
  /// changes, and would otherwise be checked twice each time it does.
  bool _checkWithNewSignals({required bool firstCheck}) {
    final signals = _data.signals = _ComponentViewSignals(this);
    final checkAgain = signals.check();
    if (firstCheck && !signals.hasDependencies) {
      // Recorded nothing, so nothing notifies it: dropped.
      _data.signals = null;
    }
    return checkAgain;
  }

  /// Whether this view is marked to be checked, which
  /// [detectChangesInMarkedDescendants] then does.
  ///
  /// Generated views read it to run the lifecycle hooks of the component of
  /// this view, as they do when they check it, when only it is checked.
  bool get isMarkedForRefresh {
    final mode = _data.changeDetectionMode;
    return mode != ChangeDetectionCheckedState.waitingToBeAttached &&
        _data.changeDetectorState != ChangeDetectorState.errored &&
        (_data.needsRefresh || mode == ChangeDetectionCheckedState.checkOnce);
  }

  @override
  void detectChangesInMarkedDescendants() {
    if (isMarkedForRefresh) {
      detectChangesDeprecated();
    } else {
      // Neither this view nor its default change detection is checked here:
      // only the marked views below it, as its parent was not checked.
      super.detectChangesInMarkedDescendants();
    }
  }

  /// An OnPush view that waits to be marked for check is not checked, but the
  /// marked views below it are reached.
  @override
  bool get reachesMarkedDescendants =>
      !isWaitingToBeAttached &&
      _data.changeDetectorState != ChangeDetectorState.errored;

  /// Marks this view to be checked, without checking the views above it.
  ///
  /// Unlike [markForCheck], the views above this one are not checked: they
  /// record that a view below them needs to be checked, and change detection
  /// goes through them to it, without checking them, unless they are checked
  /// anyway. Used when a signal that this view read changes, as that changes
  /// nothing in the views above it.
  void markForRefresh() {
    final changeDetectionMode = _data.changeDetectionMode;
    if (changeDetectionMode ==
        ChangeDetectionCheckedState.waitingToBeAttached) {
      return;
    }
    _data.needsRefresh = true;
    if (changeDetectionMode ==
        ChangeDetectionCheckedState.waitingForMarkForCheck) {
      markAsCheckOnce();
    }
    parentView!.markDescendantsForRefresh();
    ChangeDetectionHost.recordMarkedForRefresh();
  }

  @override
  ViewData get viewData => _data;

  @override
  void markViewAboveForRefresh() {
    parentView!.markDescendantsForRefresh();
  }

  // Called by [_ComponentViewSignals], which may not call the protected
  // method itself.
  void _detectChangesOrCrash() => detectChangesOrCrash();

  /// Generated code that is called by hosts.
  ///
  /// TODO(b/161929180): Can this be refactored and/or removed.
  void detectHostChanges(bool firstCheck) {}

  @override
  void disableChangeDetection() {
    _data.changeDetectorState = ChangeDetectorState.errored;
  }

  /// Marks this view to be checked during change detection.
  ///
  /// Unlike [markForCheck], this does not mark this view's ancestry for change
  /// detection. This is also invoked *during* change detection as a means of
  /// invalidating this view when any of its [component]'s inputs change. This
  /// serves to propagate input changes down the component tree during a single
  /// change detection pass.
  void markAsCheckOnce() {
    _data.changeDetectionMode = ChangeDetectionCheckedState.checkOnce;
  }

  @override
  void markForCheck() {
    final changeDetectionMode = _data.changeDetectionMode;
    if (changeDetectionMode ==
        ChangeDetectionCheckedState.waitingToBeAttached) {
      return;
    }
    if (changeDetectionMode ==
        ChangeDetectionCheckedState.waitingForMarkForCheck) {
      markAsCheckOnce();
    }
    parentView!.markForCheck();
  }

  @override
  void detachDeprecated() {
    _data.changeDetectionMode = ChangeDetectionCheckedState.waitingToBeAttached;
  }

  @override
  void reattachDeprecated() {
    _data.changeDetectionMode = ChangeDetectionCheckedState.checkAlways;
    markForCheck();
  }

  // Styling -------------------------------------------------------------------

  @dart2js.noInline
  @override
  void updateChildClass(HTMLElement element, String newClass) {
    if (identical(element, rootElement)) {
      componentStyles.updateChildClassForHostHtmlElement(element, newClass);
      final parent = parentView;
      if (parent is RenderView) {
        parent.addShimC(element);
      }
    } else {
      super.updateChildClass(element, newClass);
    }
  }

  @dart2js.noInline
  @override
  void updateChildClassNonHtml(Element element, String newClass) {
    if (identical(element, rootElement)) {
      componentStyles.updateChildClassForHost(element, newClass);
      final parent = parentView;
      if (parent is RenderView) {
        parent.addShimE(element);
      }
    } else {
      super.updateChildClassNonHtml(element, newClass);
    }
  }
}

/// Tracks the signals that a component view reads, and marks the view for
/// refresh when one of them changes.
final class _ComponentViewSignals extends ViewSignalConsumer {
  final ComponentView<Object> _view;

  _ComponentViewSignals(this._view);

  @override
  void runCheck() => _view._detectChangesOrCrash();

  @override
  void onChanged() => _view.markForRefresh();
}

/// Data for [ComponentView] bundled together as an optimization.
@sealed
class _ComponentViewData implements RenderViewData {
  @dart2js.noInline
  factory _ComponentViewData(
    View parentView,
    int parentIndex,
    ChangeDetectionCheckedState changeDetectionMode,
  ) {
    return _ComponentViewData._(parentView, parentIndex, changeDetectionMode);
  }

  _ComponentViewData._(
    this.parentView,
    this.parentIndex,
    this._changeDetectionMode,
  );

  @override
  final View parentView;

  @override
  final int parentIndex;

  @override
  late final List<List<Object>> projectedNodes;

  @override
  List<StreamSubscription<void>>? subscriptions;

  /// Tracks the signals that the view reads, once it has read one.
  ViewSignalConsumer? signals;

  /// Whether the view was marked by [ComponentView.markForRefresh] since it
  /// was checked.
  var needsRefresh = false;

  @override
  ChangeDetectionCheckedState get changeDetectionMode => _changeDetectionMode;
  ChangeDetectionCheckedState _changeDetectionMode;
  set changeDetectionMode(ChangeDetectionCheckedState mode) {
    if (_changeDetectionMode != mode) {
      _changeDetectionMode = mode;
      _updateShouldSkipChangeDetection();
    }
  }

  @override
  ChangeDetectorState get changeDetectorState => _changeDetectorState;
  ChangeDetectorState _changeDetectorState = ChangeDetectorState.neverChecked;
  set changeDetectorState(ChangeDetectorState state) {
    if (_changeDetectorState != state) {
      _changeDetectorState = state;
      _updateShouldSkipChangeDetection();
    }
  }

  @override
  bool get destroyed => _destroyed;
  bool _destroyed = false;

  @override
  bool get shouldSkipChangeDetection => _shouldSkipChangeDetection;
  bool _shouldSkipChangeDetection = false;

  @override
  void destroy() {
    _destroyed = true;
    signals?.dispose();
    final subscriptions = this.subscriptions;
    if (subscriptions != null) {
      for (var i = 0, length = subscriptions.length; i < length; ++i) {
        subscriptions[i].cancel();
      }
    }
  }

  void _updateShouldSkipChangeDetection() {
    _shouldSkipChangeDetection =
        _changeDetectionMode ==
            ChangeDetectionCheckedState.waitingForMarkForCheck ||
        _changeDetectionMode ==
            ChangeDetectionCheckedState.waitingToBeAttached ||
        _changeDetectorState == ChangeDetectorState.errored;
  }
}
