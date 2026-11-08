# Change Log

## 1.1.3

### Fixes in 1.1.3

* **Templates:** Requires `kelicap_ast` 1.1.3, which parses `*`-bindings such as `*ngIf="letter != null"` and `*ngIf="a?b:c"`, and reports invalid decorators where it threw

## 1.1.2

### Breaking changes in 1.1.2

* **Breaking:** A provider of a `@GenerateInjector` whose dependency is annotated `@Optional()` but is not nullable, such as `Engine(@Optional() String name)`, fails to compile, as it already did in a component. Make the parameter nullable (`String? name`)

### Fixes in 1.1.2

* **Views:** The top element of the view of a `*ngFor` or `*ngIf`, such as an `<option>` repeated in a `<select>`, is typed by its tag, where it was `dynamic`: in a release build (dart2js), its events, children and directives threw `NoSuchMethodError`, such as `append$1 is not a function`
* **Errors:** An error in a component, such as an unknown directive, is reported once, without a stack trace of the compiler. It was reported twice, the second time with the stack trace
* **Queries:** `@ViewChild` and `@ContentChild` of a generic component or directive, such as `@ViewChild(GenericComponent)`, find it. They were always `null`
* **Templates:** A `*ngIf` or `*ngFor` in the template of a directive without a class to read types from no longer crashes the compiler with `Null check operator used on a null value`

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
