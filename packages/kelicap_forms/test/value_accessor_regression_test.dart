import 'package:web/web.dart';

import 'package:test/test.dart';
import 'package:kelicap/kelicap.dart';

import 'package:kelicap_forms/kelicap_forms.dart';

import 'package:kelicap_test/kelicap_test.dart';

import 'value_accessor_regression_test.template.dart' as ng;

void _dispatchChange(Element element) {
  element.dispatchEvent(Event('change', EventInit(bubbles: true)));
}

void main() {
  tearDown(disposeAnyRunningTest);

  group('checkbox', () {
    test('accepts a control with a null value', () async {
      final control = Control();
      final fixture =
          await NgTestBed<CheckboxTest>(ng.createCheckboxTestFactory()).create(
            beforeChangeDetection: (component) {
              component.form = ControlGroup({'agree': control});
            },
          );
      final input =
          fixture.rootElement.querySelector('input') as HTMLInputElement;
      expect(input.checked, false);

      await fixture.update((_) {
        input.checked = true;
        _dispatchChange(input);
      });
      expect(control.value, true);
    });

    test('is unchecked when its control is reset', () async {
      final control = Control(true);
      final fixture =
          await NgTestBed<CheckboxTest>(ng.createCheckboxTestFactory()).create(
            beforeChangeDetection: (component) {
              component.form = ControlGroup({'agree': control});
            },
          );
      final input =
          fixture.rootElement.querySelector('input') as HTMLInputElement;
      expect(input.checked, true);

      await fixture.update((_) => control.reset());
      expect(input.checked, false);
    });
  });

  group('select', () {
    test('supports an option whose value changes to null', () async {
      final fixture = await NgTestBed<NullOptionTest>(
        ng.createNullOptionTestFactory(),
      ).create();
      final select =
          fixture.rootElement.querySelector('select') as HTMLSelectElement;

      await fixture.update((component) => component.optionValue = null);
      expect(select.selectedIndex, 0, reason: 'the model is null');

      await fixture.update((_) {
        select.selectedIndex = 1;
        _dispatchChange(select);
      });
      await fixture.update((component) {
        expect(component.selected, 'one');
      });

      await fixture.update((_) {
        select.selectedIndex = 0;
        _dispatchChange(select);
      });
      await fixture.update((component) {
        expect(component.selected, isNull);
      });
    });
  });

  group('radio', () {
    test('only unchecks radio buttons with the same name in a form', () async {
      final form = ControlGroup({
        'small': Control(RadioButtonState(true, 'small')),
        'large': Control(RadioButtonState(false, 'large')),
        'red': Control(RadioButtonState(true, 'red')),
        'blue': Control(RadioButtonState(false, 'blue')),
      });
      final fixture = await NgTestBed<RadioGroupsTest>(
        ng.createRadioGroupsTestFactory(),
      ).create(beforeChangeDetection: (component) => component.form = form);
      final blue =
          fixture.rootElement.querySelector('#blue') as HTMLInputElement;

      await fixture.update((_) => _dispatchChange(blue));

      final value = form.value!;
      expect(value['small'].checked, true, reason: 'other group');
      expect(value['large'].checked, false, reason: 'other group');
      expect(value['red'].checked, false, reason: 'same group');
      expect(value['blue'].checked, true);
    });

    test('unchecks standalone radio buttons with the same name', () async {
      final fixture = await NgTestBed<StandaloneRadioTest>(
        ng.createStandaloneRadioTestFactory(),
      ).create();
      final b = fixture.rootElement.querySelector('#b') as HTMLInputElement;

      await fixture.update((_) => _dispatchChange(b));

      await fixture.update((component) {
        expect(component.a.checked, false);
        expect(component.b.checked, true);
      });
    });

    test('keeps standalone radio buttons of another group', () async {
      final fixture = await NgTestBed<StandaloneRadioTest>(
        ng.createStandaloneRadioTestFactory(),
      ).create();
      final b = fixture.rootElement.querySelector('#b') as HTMLInputElement;
      final unnamed =
          fixture.rootElement.querySelector('#unnamedB') as HTMLInputElement;
      final inForm =
          fixture.rootElement.querySelector('#formB') as HTMLInputElement;

      await fixture.update((_) => _dispatchChange(b));
      await fixture.update((component) {
        expect(component.other.checked, true, reason: 'other name');
        expect(component.unnamedA.checked, true, reason: 'not named');
        expect(component.formA.checked, true, reason: 'other form element');
      });

      await fixture.update((_) => _dispatchChange(unnamed));
      await fixture.update((component) {
        expect(component.unnamedA.checked, true, reason: 'not named');
      });

      await fixture.update((_) => _dispatchChange(inForm));
      await fixture.update((component) {
        expect(component.formA.checked, true, reason: 'other form element');
      });
    });
  });
}

@Component(
  selector: 'checkbox-test',
  directives: [formDirectives],
  template: '''
<form [ngFormModel]="form">
  <input type="checkbox" ngControl="agree">
</form>''',
)
class CheckboxTest {
  late ControlGroup form;
}

@Component(
  selector: 'null-option-test',
  directives: [formDirectives],
  template: '''
<select [(ngModel)]="selected">
  <option [ngValue]="optionValue">None</option>
  <option [ngValue]="'one'">One</option>
</select>''',
)
class NullOptionTest {
  Object? optionValue = 'none';
  Object? selected;
}

@Component(
  selector: 'radio-groups-test',
  directives: [formDirectives],
  providers: formProviders,
  template: '''
<form [ngFormModel]="form">
  <input type="radio" name="size" ngControl="small">
  <input type="radio" name="size" ngControl="large">
  <input type="radio" name="color" ngControl="red">
  <input type="radio" name="color" ngControl="blue" id="blue">
</form>''',
)
class RadioGroupsTest {
  late ControlGroup form;
}

@Component(
  selector: 'standalone-radio-test',
  directives: [formDirectives],
  providers: formProviders,
  template: '''
<input type="radio" name="food" [(ngModel)]="a">
<input type="radio" name="food" [(ngModel)]="b" id="b">
<input type="radio" name="drink" [(ngModel)]="other">
<input type="radio" [(ngModel)]="unnamedA">
<input type="radio" [(ngModel)]="unnamedB" id="unnamedB">
<form><input type="radio" name="food" [(ngModel)]="formA"></form>
<form><input type="radio" name="food" [(ngModel)]="formB" id="formB"></form>''',
)
class StandaloneRadioTest {
  RadioButtonState a = RadioButtonState(true, 'a');
  RadioButtonState b = RadioButtonState(false, 'b');
  RadioButtonState other = RadioButtonState(true, 'other');
  RadioButtonState unnamedA = RadioButtonState(true, 'unnamedA');
  RadioButtonState unnamedB = RadioButtonState(false, 'unnamedB');
  RadioButtonState formA = RadioButtonState(true, 'formA');
  RadioButtonState formB = RadioButtonState(false, 'formB');
}
