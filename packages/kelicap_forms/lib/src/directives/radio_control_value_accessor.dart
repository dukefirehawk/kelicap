import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart';
//import 'dart:js_util' as js_util;

import 'package:kelicap/kelicap.dart';

import 'shared.dart' show setElementDisabled;

import 'control_value_accessor.dart'
    show ChangeHandler, ControlValueAccessor, ngValueAccessor, TouchHandler;
import 'ng_control.dart' show NgControl;

const radioValueAccessor = ExistingProvider.forToken(
  ngValueAccessor,
  RadioControlValueAccessor,
);

/// Internal class used by Kelicap to uncheck radio buttons with the matching
/// name.
@Injectable()
class RadioControlRegistry {
  final List<dynamic> _accessors = [];
  void add(NgControl control, RadioControlValueAccessor accessor) {
    _accessors.add([control, accessor]);
  }

  void remove(RadioControlValueAccessor accessor) {
    var indexToRemove = -1;
    for (var i = 0; i < _accessors.length; ++i) {
      if (identical(_accessors[i][1], accessor)) {
        indexToRemove = i;
      }
    }
    _accessors.removeAt(indexToRemove);
  }

  void select(RadioControlValueAccessor accessor) {
    for (var c in _accessors) {
      if (!identical(c[1], accessor) && _isSameGroup(c[0], c[1], accessor)) {
        c[1].fireUncheck();
      }
    }
  }

  /// Whether selecting [selected] unchecks [other], whose control is [control].
  ///
  /// As in the browser, radio buttons without a name are never in a group.
  /// Radio buttons with a name are in one if they share it and either belong to
  /// the same form model, or have no form model and share a form element.
  bool _isSameGroup(
    NgControl control,
    RadioControlValueAccessor other,
    RadioControlValueAccessor selected,
  ) {
    if (selected.name == null || other.name != selected.name) return false;
    final a = control.control;
    final b = selected._control?.control;
    if (a == null || b == null) return false;
    if (identical(a.root, b.root)) return true;
    return identical(a, a.root) &&
        identical(b, b.root) &&
        other._form == selected._form;
  }
}

/// The value provided by the forms API for radio buttons.
class RadioButtonState {
  final bool checked;
  final String value;

  RadioButtonState(this.checked, this.value);
}

/// The accessor for writing a radio control value and listening to changes that
/// is used by the [NgModel], [NgFormControl], and [NgControlName] directives.
///
/// ### Example
///
/// ```dart
/// @Component(
///   template: '''
///     <input type="radio" name="food" [(ngModel)]="foodChicken">
///     <input type="radio" name="food" [(ngModel)]="foodFish">
///   '''
/// )
/// class FoodCmp {
///   RadioButtonState foodChicken = new RadioButtonState(true, "chicken");
///   RadioButtonState foodFish = new RadioButtonState(false, "fish");
/// }
/// ```
@Directive(
  selector:
      'input[type=radio][ngControl],'
      'input[type=radio][ngFormControl],'
      'input[type=radio][ngModel]',
  providers: [radioValueAccessor],
)
class RadioControlValueAccessor extends Object
    with TouchHandler, ChangeHandler<RadioButtonState>
    implements ControlValueAccessor<RadioButtonState>, OnDestroy, OnInit {
  final Element? _element;
  final RadioControlRegistry? _registry;
  final Injector? _injector;
  RadioButtonState? _state;
  late NgControl? _control;

  @Input()
  String? name;

  RadioControlValueAccessor(
    @Optional() this._element,
    @Optional() this._registry,
    @Optional() this._injector,
  );

  HTMLFormElement? get _form => (_element as HTMLInputElement?)?.form;

  @HostListener('change')
  void changeHandler() {
    onChange(RadioButtonState(true, _state!.value), rawValue: _state!.value);
    _registry?.select(this);
  }

  @override
  void ngOnInit() {
    _control = _injector?.provideType(NgControl);
    if (_control != null) {
      _registry?.add(_control!, this);
    }
  }

  @override
  void ngOnDestroy() {
    _registry?.remove(this);
  }

  @override
  void writeValue(RadioButtonState? value) {
    _state = value;
    if (value?.checked ?? false) {
      // TODO: Migrate to 3.6 (Need review)
      //js_util.setProperty(_element, 'checked', true);
      _element?.setProperty('checked'.toJS, true.toJS);
    }
  }

  void fireUncheck() {
    // A radio button whose model has no state has nothing to uncheck.
    final state = _state;
    if (state == null) return;
    onChange(RadioButtonState(false, state.value), rawValue: state.value);
  }

  @override
  void onDisabledChanged(bool isDisabled) {
    setElementDisabled(_element, isDisabled);
  }
}
