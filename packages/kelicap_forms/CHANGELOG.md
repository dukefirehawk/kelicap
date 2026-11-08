# Change Log

## 1.1.3

### Fixes in 1.1.3

* **Checkbox:** A checkbox accepts a null value, which it shows as unchecked. A checkbox bound to a control without a value, such as with `ngControl` in a template-driven form, no longer throws, nor does resetting its control
* **Select:** An `<option [ngValue]="null">`, or one whose value changes to null, no longer throws, and selecting it sets the model to null, not to the text of the option's value. The option needs `kelicap_compiler` 1.1.3, which sets an input bound to `null`. An option bound to a variable that is null from the start is still treated as if it had no `ngValue` until the value changes
* **Radio:** Selecting a radio button unchecks only those with the same `name`. Groups in the same form no longer uncheck each other, and standalone `[(ngModel)]` radio buttons with the same name, in the same form element or in none, now do. Radio buttons without a name are not in a group, as in the browser
* **Validators:** `Validators.pattern` and the `pattern` attribute match the entire value when the pattern has alternatives: `cat|dog` no longer accepts `catfish`. The regular expression is compiled once, rather than on every validation

## 1.1.2

### Fixes in 1.1.2

* **Value accessors:** `[(ngModel)]`, `ngControl` and the other form directives update their control from text, number, checkbox and select inputs in a release build (dart2js), where reading the input's value threw `NoSuchMethodError: get$target`. The accessors read the value from a typed `Event`
* Requires `kelicap` 1.1.2, for form controls inside `*ngIf` and `*ngFor`

## 1.1.1

- chore: Add documentation link
- chore: Update README

## 1.1.0

- chore: Upgrade min sdk to 3.13.0 and other dependency upgrades

## 1.0.2

- fix: Misc. runtime errors contributed by the community

## 1.0.1

- chore: Update `pubspec.yaml` description

## 1.0.0

- chore:Initial release
