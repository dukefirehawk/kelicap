import 'dart:js_interop';

import 'package:web/web.dart';

import '../../core/change_detection/differs/default_keyvalue_differ.dart';
import '../../meta/directives.dart';
import '../../meta/lifecycle_hooks.dart';
import '../../meta/di_arguments.dart';

import '../../utilities/unsafe_cast.dart';

/// The `NgStyle` directive changes an element's style based on the bound style
/// expression:
///
///     <div [ngStyle]="styleExp"></div>
///
/// _styleExp_ must evaluate to a `Map<String, String>`. Element style properties
/// are set based on the map entries: each _key_:_value_ pair identifies a
/// style property _name_ and its _value_.
///
/// For details, see the [`ngStyle` discussion in the Template Syntax][guide]
/// page.
///
/// ### Examples
///
/// Try the [live example][ex] from the [Template Syntax][guide] page. Here are
/// the relevant excerpts from the example's template and the corresponding
/// component class:
///
/// <?code-excerpt "docs/template-syntax/lib/app_component.html (NgStyle-2)"?>
/// ```html
/// <div [ngStyle]="currentStyles">
///   This div is initially italic, normal weight, and extra large (24px).
/// </div>
/// ```
///
/// <?code-excerpt "docs/template-syntax/lib/app_component.dart (setStyles)"?>
/// ```dart
/// Map<String, String> currentStyles = <String, String>{};
/// void setCurrentStyles() {
///   currentStyles = <String, String>{
///     'font-style': canSave ? 'italic' : 'normal',
///     'font-weight': !isUnchanged ? 'bold' : 'normal',
///     'font-size': isSpecial ? '24px' : '12px'
///   };
/// }
/// ```
///
/// In this example, user changes to the `<input>` elements result in updates
/// to the corresponding style properties of the first paragraph.
///
/// A [Map] literal can be used as a style expression:
///
///     <div [ngStyle]="{'font-style': 'italic'}"></div>
///
/// A better practice, however, is to bind to a component field or method, as
/// in the binding to `setStyle()` above.
///
@Directive(selector: '[ngStyle]')
class NgStyle implements DoCheck {
  final Element? _ngElement;
  Map<String, String?> _rawStyle = {};
  DefaultKeyValueDiffer? _differ;

  NgStyle(@Optional() this._ngElement);

  @Input('ngStyle')
  set rawStyle(Map<String, String?>? v) {
    _rawStyle = v ?? {};
    if (_differ == null && v != null) {
      _differ = DefaultKeyValueDiffer();
    }
  }

  @override
  void ngDoCheck() {
    final differ = _differ;
    if (differ == null || !differ.diff(_rawStyle)) {
      return;
    }
    differ
      ..forEachAddedItem(_setProperty)
      ..forEachChangedItem(_setProperty)
      ..forEachRemovedItem(_setProperty);
  }

  void _setProperty(KeyValueChangeRecord record) {
    // A removed key arrives with a null value. The empty string clears the
    // declaration, which is what `dart:html` did when handed null.
    _inlineStyle?.setProperty(
      unsafeCast(record.key),
      record.currentValue as String? ?? '',
    );
  }

  /// The host element's inline style declaration.
  ///
  /// `style` is declared on the element subtypes rather than on [Element], so
  /// it cannot be reached through the statically known type. Note this must be
  /// a CSS property on `style` -- setting a property of the same name directly
  /// on the element, as `dart:js_interop_unsafe`'s `setProperty` does, defines
  /// a JavaScript field on the DOM object and changes nothing about how the
  /// element renders.
  CSSStyleDeclaration? get _inlineStyle {
    final element = _ngElement;
    if (element == null) return null;
    if (element.isA<HTMLElement>()) return (element as HTMLElement).style;
    if (element.isA<SVGElement>()) return (element as SVGElement).style;
    return null;
  }
}
