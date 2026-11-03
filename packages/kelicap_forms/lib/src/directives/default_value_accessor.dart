import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart';
//import 'dart:js_util' as js_util;

import 'package:kelicap/kelicap.dart';

import 'shared.dart' show setElementDisabled;

import 'control_value_accessor.dart';

const defaultValueAccessor = ExistingProvider.forToken(
  ngValueAccessor,
  DefaultValueAccessor,
);

/// The default accessor for writing a value and listening to changes that is used by the
/// [NgModel], [NgFormControl], and [NgControlName] directives.
///
/// ### Example
///     <input type="text" ngControl="searchQuery">
@Directive(
  selector:
      'input:not([type=checkbox])[ngControl],'
      'textarea[ngControl],'
      'input:not([type=checkbox])[ngFormControl],'
      'textarea[ngFormControl],'
      'input:not([type=checkbox])[ngModel],'
      'textarea[ngModel],[ngDefaultControl]',
  providers: [defaultValueAccessor],
)
class DefaultValueAccessor extends Object
    with TouchHandler, ChangeHandler<String>
    implements ControlValueAccessor<dynamic> {
  final Element? _element;

  DefaultValueAccessor(@Optional() this._element);

  // The event, not `$event.target.value`: a member of `$event` is read
  // dynamically, which a DOM object of `package:web` does not allow once
  // compiled with dart2js. Its value is read here, in typed Dart.
  @HostListener('input', [r'$event'])
  void handleChange(Event event) {
    var value = _valueOf(event.target);
    onChange(value, rawValue: value);
  }

  /// The value of [target]: of an input, a textarea or a select, or else its
  /// `value` property, as of a custom element with `ngDefaultControl`.
  static String _valueOf(EventTarget? target) {
    if (target == null) return '';
    if (target.isA<HTMLInputElement>()) {
      return (target as HTMLInputElement).value;
    } else if (target.isA<HTMLTextAreaElement>()) {
      return (target as HTMLTextAreaElement).value;
    } else if (target.isA<HTMLSelectElement>()) {
      return (target as HTMLSelectElement).value;
    }
    var value = (target as JSObject).getProperty<JSAny?>('value'.toJS);
    return value.dartify()?.toString() ?? '';
  }

  @override
  void writeValue(value) {
    var normalizedValue = value ?? '';
    final e = _element;
    if (e == null) return;

    // TODO: Fix this type checking
    if (e.isA<HTMLInputElement>()) {
      (e as HTMLInputElement).value = normalizedValue.toString();
    } else if (e.isA<HTMLTextAreaElement>()) {
      (e as HTMLTextAreaElement).value = normalizedValue.toString();
    } else if (e.isA<HTMLSelectElement>()) {
      (e as HTMLSelectElement).value = normalizedValue.toString();
    } else {
      e.setProperty('value'.toJS, normalizedValue.toString().toJS);
    }
  }

  @override
  void onDisabledChanged(bool isDisabled) {
    setElementDisabled(_element, isDisabled);
  }
}
