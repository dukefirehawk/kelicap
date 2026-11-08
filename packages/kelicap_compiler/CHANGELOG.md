# Change Log

## 1.1.3

### Breaking changes in 1.1.3

* **Breaking:** An event binding of only whitespace, such as `(click)="  "`, fails to compile with "events must have a bound expression", as an empty one does, where it compiled to a handler that does nothing
* **Breaking:** An input of a directive bound to `null`, such as `[value]="null"`, is set to `null` once, as any other value is, where the binding was dropped. As for any other value, this is a change, so the directive's `ngAfterChanges` runs, and an OnPush component is marked to be checked, on the first change detection. On an input whose type is not nullable, it fails to compile with "Input "name" of Directive is not nullable, so it cannot be bound to null", reported at the binding in the template
* **Breaking:** A two-way binding without an expression, such as `[(value)]` or `[(value)]=""`, fails to compile with "Two-way binding '[(name)]' requires an expression", where it was dropped. Give it an expression, or remove it

### New in 1.1.3

* **Templates:** A handler of a DOM event that reads a member of `$event`, such as `(click)="onClick($event.target)"`, `$event!.target` or `$event['target']`, gets a warning: `$event` is read dynamically, which fails in a release build (dart2js). Pass `$event` to a method that takes a typed `Event` instead. The event of an `@Output()` is a Dart object, so it is not warned about, unless the output is a `Stream` of a JavaScript type, such as `Stream<UIEvent>` of `package:web`, which re-emits a DOM event. A `@HostListener` argument such as `$event.target`, of a directive or a component, is warned about once, at the method, when its library is compiled, rather than for each element the directive matches

### Fixes in 1.1.3

* **Components:** A component, directive or provider class whose unnamed constructor is not declared first is created with its unnamed constructor. A class that declared a private constructor first, such as `Foo._()` before `factory Foo()`, failed to compile with "No constructors found", and one that declared a public named constructor first had that constructor's parameters injected
* **Templates:** Requires `kelicap_ast` 1.1.3 for micro-syntax whose expressions have a `;` or `:` in a string or brackets, such as `*ngFor="let x of m['a;b']"`, or a conditional, such as `a?b:c; context: ctx`, or whitespace before a `;`
* **Templates:** Requires `kelicap_ast` 1.1.3, which parses `*`-bindings such as `*ngIf="letter != null"` and `*ngIf="a?b:c"`, and reports invalid decorators where it threw
* **Templates:** The whitespace in a `<textarea>`, which is its value, is kept, as in a `<pre>`, except a newline at the start of either, which the browser drops as well. A `<pre>` no longer starts with a blank line, and a `<textarea>` that holds only indentation has it as its value, as it would in HTML
* **Templates:** Whitespace between inline elements such as `<u>`, `<s>`, `<mark>`, `<ins>` and `<del>` is kept, so `<u>a</u> <u>b</u>` shows a space
* **Templates:** An unknown named entity, such as `&foo;`, is left as written, where its `&` and `;` were removed. A numeric entity of any length is decoded, such as `&#x1F600;` and `&#9;`, which were left as text

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
