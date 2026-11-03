import 'package:web/web.dart';

import 'package:kelicap/kelicap.dart';

import 'control_value_accessor.dart'
    show ChangeHandler, ControlValueAccessor, ngValueAccessor, TouchHandler;

const checkboxValueAccessor = ExistingProvider.forToken(
  ngValueAccessor,
  CheckboxControlValueAccessor,
);

/// The accessor for writing a value and listening to changes on a checkbox input element.
///
/// ### Example
///
/// ```html
/// <input type="checkbox" ngControl="rememberLogin">
/// ```
@Directive(
  selector:
      'input[type=checkbox][ngControl],'
      'input[type=checkbox][ngFormControl],'
      'input[type=checkbox][ngModel]',
  providers: [checkboxValueAccessor],
)
class CheckboxControlValueAccessor extends Object
    with TouchHandler, ChangeHandler<bool>
    implements ControlValueAccessor<bool> {
  final HTMLInputElement _element;

  CheckboxControlValueAccessor(@Optional() Element? element)
    : _element = element as HTMLInputElement;

  // The event, not `$event.target.value`: a member of `$event` is read
  // dynamically, which a DOM object of `package:web` does not allow once
  // compiled with dart2js. Its state is read here, in typed Dart.
  @HostListener('change', [r'$event'])
  void handleChange(Event event) {
    var checked = (event.target as HTMLInputElement).checked;
    onChange(checked, rawValue: '$checked');
  }

  @override
  void writeValue(bool value) {
    _element.checked = value;
  }

  @override
  void onDisabledChanged(bool isDisabled) {
    _element.disabled = isDisabled;
  }
}
