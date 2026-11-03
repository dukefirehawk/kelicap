# Change Log

## 1.1.2

### Fixes in 1.1.2

* **Views:** The top element of the view of a `*ngFor` or `*ngIf`, such as an `<option>` repeated in a `<select>`, is typed by its tag, where it was `dynamic`: in a release build (dart2js), its events, children and directives threw `NoSuchMethodError`, such as `append$1 is not a function`

## 1.1.1

* fix: deprecated method usage in di module
* chore: Add documentation link
* chore: Update README

## 1.1.0

* chore: Upgrade min sdk to 3.13.0 and other dependency upgrades

## 1.0.3

* fix: incorrect raw type reference

## 1.0.2

* fix: Misc. compile and runtime errors contributed by the community

## 1.0.1

* fix: Replaced deprecated methods used to get type string in di module

## 1.0.0

* chore: Initial release
