# Change Log

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
