import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart';
//import 'dart:js_util' as js_util;

import 'package:kelicap/kelicap.dart';
import 'package:kelicap_forms/src/directives/shared.dart'
    show setElementDisabled;

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

  @HostListener('input', ['\$event.target.value'])
  void handleChange(String value) {
    onChange(value, rawValue: value);
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
