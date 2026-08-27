import 'package:web/web.dart';

import 'package:meta/meta.dart';
import '../../di/injector.dart' show Injector;

import '../../utilities/unsafe_cast.dart';
import 'component_factory.dart' show ComponentFactory, ComponentRef;
import 'component_loader.dart';
import 'template_ref.dart';
import 'view_container_ref.dart';
import 'view_ref.dart' show EmbeddedViewRef, ViewRef;
import 'views/dynamic_view.dart';
import 'views/view.dart';

/// A container providing an insertion point for attaching children.
///
/// This is created for components containing a nested component or a
/// `<template>` element so they can be attached after initialization.
class ViewContainer extends ComponentLoader implements ViewContainerRef {
  final int index;
  final int? parentIndex;
  final View? parentView;
  final Node nativeElement;

  List<DynamicView> nestedViews = [];

  ViewContainer(
    this.index,
    this.parentIndex,
    this.parentView,
    this.nativeElement,
  );

  //@Deprecated('Use .nativeElement instead')
  //ElementRef get elementRef => ElementRef(nativeElement);

  /// Returns the [ViewRef] for the View located in this container at the
  /// specified index.
  @override
  ViewRef get(int index) {
    return nestedViews[index];
  }

  /// The number of Views currently attached to this container.
  @override
  int get length => nestedViews.length;

  /// Anchor element that specifies the location of this container in the
  /// containing View.
  @override
  HTMLElement get element => nativeElement as HTMLElement;

  @override
  Injector get parentInjector => parentView!.injector(parentIndex);

  @override
  Injector get injector => parentView!.injector(index);

  @experimental
  void detectChangesInCheckAlwaysViews() {
    for (var i = 0, len = nestedViews.length; i < len; i++) {
      nestedViews[i].detectChangesInCheckAlwaysViews();
    }
  }

  void detectChangesInNestedViews() {
    for (var i = 0, len = nestedViews.length; i < len; i++) {
      nestedViews[i].detectChangesDeprecated();
    }
  }

  void destroyNestedViews() {
    for (var i = 0, len = nestedViews.length; i < len; i++) {
      nestedViews[i].destroyInternalState();
    }
  }

  /// Instantiates an Embedded View based on the [TemplateRef `templateRef`]
  /// and inserts it into this container at the specified `index`.
  ///
  /// If `index` is not specified, the new View will be inserted as the last
  /// View in the container.
  ///
  /// Returns the [ViewRef] for the newly created View.
  @override
  EmbeddedViewRef insertEmbeddedView(
    TemplateRef templateRef, [
    int index = -1,
  ]) {
    final viewRef = templateRef.createEmbeddedView();
    insert(viewRef, index);
    return viewRef;
  }

  /// Instantiates an Embedded View based on the [TemplateRef `templateRef`]
  /// and appends it into this container.
  @override
  EmbeddedViewRef createEmbeddedView(TemplateRef templateRef) {
    final viewRef = templateRef.createEmbeddedView();
    _attachView(unsafeCast(viewRef), length);
    return viewRef;
  }

  @override
  ComponentRef<T> createComponent<T extends Object>(
    ComponentFactory<T> componentFactory, [
    int index = -1,
    Injector? injector,
    List<List<Object>>? projectableNodes,
  ]) {
    final contextInjector = injector ?? parentInjector;
    final componentRef = componentFactory.create(
      contextInjector,
      projectableNodes ?? const [],
    );
    insert(componentRef.hostView as ViewRef, index);
    return componentRef;
  }

  @override
  ViewRef insert(ViewRef viewRef, [int index = -1]) {
    if (index == -1) {
      index = length;
    }
    _attachView(unsafeCast(viewRef), index);
    return viewRef;
  }

  @override
  void move(ViewRef viewRef, [int index = -1]) {
    if (index == -1) {
      index = length;
    }
    _moveView(unsafeCast(viewRef), index);
  }

  /// Returns the index of the View, specified via [ViewRef], within the current
  /// container or `-1` if this container doesn't contain the View.
  @override
  int indexOf(ViewRef viewRef) => nestedViews.indexOf(unsafeCast(viewRef));

  /// Destroys a View attached to this container at the specified `index`.
  ///
  /// If `index` is not specified, the last View in the container will be
  /// removed.
  @override
  void remove([int index = -1]) {
    if (index == -1) {
      index = length - 1;
    }
    detachView(index).destroyInternalState();
  }

  /// Use along with [#insert] to move a View within the current container.
  ///
  /// If the `index` param is omitted, the last [ViewRef] is detached.
  @override
  ViewRef detach([int index = -1]) {
    if (index == -1) {
      index = length - 1;
    }
    return detachView(index);
  }

  /// Destroys all Views in this container.
  @override
  void clear() {
    for (var i = nestedViews.length; i > 0; i--) {
      remove(i - 1);
    }
  }

  List<T> mapNestedViews<T, U extends DynamicView>(
    List<T> Function(U) callback,
  ) {
    //final nestedViews = this.nestedViews;
    if (nestedViews.isEmpty) {
      return const <Never>[];
    }
    final result = <T>[];
    for (var i = 0, l = nestedViews.length; i < l; i++) {
      result.addAll(callback(unsafeCast<U>(nestedViews[i])));
    }
    return result;
  }

  /// Like [mapNestedViews], but optimized for views with a single result.
  List<T> mapNestedViewsWithSingleResult<T, U extends DynamicView>(
    T Function(U) callback,
  ) {
    //final nestedViews = this.nestedViews;
    if (nestedViews.isEmpty) {
      return const <Never>[];
    }
    final result = <T>[];
    for (var i = 0, l = nestedViews.length; i < l; i++) {
      result.add(callback(unsafeCast<U>(nestedViews[i])));
    }
    return result;
  }

  Node? _findRenderNode(List<DynamicView> views, int index) {
    return index > 0
        ? views[index - 1].viewFragment!.findLastDomNode()
        : nativeElement;
  }

  void _moveView(DynamicView view, int newIndex) {
    final previousIndex = nestedViews.indexOf(view);
    if (previousIndex == -1) {
      throw StateError('View is not a member of this container');
    }

    nestedViews
      ..removeAt(previousIndex)
      ..insert(newIndex, view);

    final refRenderNode = _findRenderNode(nestedViews, newIndex);

    if (refRenderNode != null) {
      view.addRootNodesAfter(refRenderNode);
    }

    view.wasMoved();
  }

  void _attachView(DynamicView view, int viewIndex) {
    //final views = nestedViews;
    nestedViews.insert(viewIndex, view);

    final refRenderNode = _findRenderNode(nestedViews, viewIndex);
    //nestedViews = views;

    if (refRenderNode != null) {
      view.addRootNodesAfter(refRenderNode);
    }

    view.wasInserted(this);
  }

  DynamicView detachView(int viewIndex) {
    final view = nestedViews.removeAt(viewIndex);
    view
      ..removeRootNodes()
      ..wasRemoved();
    return view;
  }

  @override
  ComponentRef<T> loadNextTo<T extends Object>(
    ComponentFactory<T> component, {
    Injector? injector,
  }) => loadNextToLocation(component, this, injector: injector);
}
