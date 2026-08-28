import 'package:meta/meta.dart';

import '../../core/linker/template_ref.dart';
import '../../core/linker/view_container_ref.dart';
import '../../meta/di_arguments.dart';
import '../../meta/directives.dart';

/// An alternative to [NgFor] optimized for immutable/unmodified collections.
///
/// ```html
/// <ng-container *ngForIdentity="let e of list">
///   Hello {{e}}!
/// </ng-container>
/// ```
///
/// Unlike [NgFor], [NgForIdentity]:
/// * Uses _identity_ not _contents_ of a collection to build child views.
/// * Assumes all collections' contents will never change.
/// * Only supports the `$implicit` and `index` local variables.
///
/// This API is **experimental** and subject to change or removal.
@Directive(selector: '[ngForIdentity][ngForIdentityOf]')
@experimental
class NgForIdentity<T> {
  final TemplateRef? _template;
  final ViewContainerRef? _container;

  const NgForIdentity(@Optional() this._template, @Optional() this._container);

  @Input()
  set ngForIdentityOf(Iterable<T>? elements) {
    _container?.clear();
    if (elements == null || elements.isEmpty) {
      return;
    }
    var i = 0;
    for (final element in elements) {
      if (_template == null) return;
      final view = _container?.createEmbeddedView(_template);
      view?.setLocal(r'$implicit', element);
      view?.setLocal(r'index', i++);
      // TODO: Consider if we want all of the NgFor local variables available.
    }
  }
}
