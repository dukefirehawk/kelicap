# Change Log

## 2.0.1

### Fixes in 2.0.1

* **Performance:** Change detection of components that read no signal is about as fast as in 1.1.5. In 2.0.0, a pass over a table of 1,000 to 10,000 rows that read no signal was 30% to 60% slower than in 1.1.5 with the default change detection, and up to a sixth slower with OnPush. It is now up to a tenth slower with the default change detection, and as fast with OnPush. `examples/no_signals_bench` measures it
  * Requires `kelicap_compiler` 2.0.1, whose generated code checks each child component without the cost that the public `ChangeDetectorRef.detectChanges` now has
  * A component that reads its first signal after its first check also makes the nearest component above it that reads signals depend on that signal, until that component's next check: that costs it one check, at most, when the signal changes
* **Signals:** `ChangeDetectorRef.detectChanges` called in an `effect`, such as to render a component at once, no longer makes the effect depend on the signals that the component reads, which ran it again when one of them changed
* **Change detection:** A root component destroyed during change detection, such as by a lifecycle hook of another root, no longer throws a `RangeError`, and the roots after it are still checked
* **Change detection:** A pass that ends with the error about components checked again 100 times no longer counts toward the 100 passes in a row that each set a signal, which reported that error after fewer passes

## 2.0.0

### Breaking changes in 2.0.0

* **Breaking:** Requires `kelicap_compiler` 2.0.0, whose generated code reaches the components that signals mark, below views that are not checked, such as an OnPush parent

### New in 2.0.0

* **Signals:** `package:kelicap/signals.dart` adds signals, built on `package:alien_signals`:
  * `signal(0)` creates one. Read it with `count()`, also in a template (`{{count()}}`), and change it with `count.set(1)` or `count.update((value) => value + 1)`
  * `computed` derives a value from signals, `effect` runs code when the signals it read change, `untracked` reads signals without tracking them, `batch` groups changes, and `toSignal` and `toStream` convert between streams and signals
* **Change detection:** Setting a signal runs change detection, even outside the `NgZone`, and checks only the components whose templates read it. An OnPush component that reads a signal updates without `ChangeDetectorRef.markForCheck`, and the components above it and beside it are not checked
  * A signal read in a lifecycle hook or an input setter marks the parent component, whose template is being checked, not the component itself
  * A component checked because of a signal runs `ngAfterContentChecked` and `ngAfterViewChecked`, but not `ngDoCheck`
  * A signal set during change detection, such as in `ngAfterViewInit`, checks the components that read it again in the same pass. After 100 such checks in a pass, or 100 passes in a row that each set a signal, the error handler is called, and the components are not checked again until something else runs change detection
* **Effects:** An effect is not destroyed with the component that created it: destroy it in `ngOnDestroy`. An error that an effect throws goes to the zone that created it, such as the application's `ExceptionHandler`, and is not thrown by the `set` that ran it

## 1.1.5

### Fixes in 1.1.5

* **API docs:** The library and lifecycle hook docs link to the [Kelicap documentation](https://dukefirehawk.gitbook.io/kelicap-docs), where they linked to pages of the old AngularDart site that do not exist, and the links to its live examples and cheat sheet are gone
* **Pubspec:** The package links to its documentation on the [Kelicap documentation](https://dukefirehawk.gitbook.io/kelicap-docs) site, from pub.dev, where it linked to the GitHub repository of the docs
* **README:** It links to the [Kelicap Components Gallery](https://kelicap-components-gallery.web.app/), where the components of `kelicap_components` can be tried live

## 1.1.4

### Fixes in 1.1.4

* **Dependency injection:** Code compiled by `kelicap_compiler` 1.1.4 injects each `package:web` type, such as `Document` and `Window`, from its own provider, where an injector returned the first of their providers for each of them. See its changelog. Hand-written code that looks one up by its `Type`, such as `injector.get(Document)`, cannot tell them apart, as each is `JSObject` at runtime, and no longer finds its provider: the error says so. Inject it in a constructor, or use `document` and `window` directly

## 1.1.3

### Breaking changes in 1.1.3

* **Breaking:** Requires `kelicap_compiler` 1.1.3, for the template fixes of `kelicap_ast` 1.1.3. It rejects some templates it compiled before: a two-way binding without an expression (`[(value)]`), an event binding of only whitespace, and `null` bound to an input that is not nullable. An input of a directive bound to `null`, such as `[value]="null"`, is now set to `null`, and runs the directive's `ngAfterChanges`, and marks an OnPush component to be checked, on the first change detection, where the binding was dropped. See its changelog

### Fixes in 1.1.3

* **NgFor:** The `even` and `odd` locals are updated for every item, including those that shift when an item is added or removed before them
* **Security:** `[style]` bindings accept `url(...)` values whose URL is safe, absolute such as `url(https://example.com/a.png)` or relative such as `url(images/a.png)`, in or out of quotes, which were replaced with `unsafe`. So do `URL(...)` in any case, and a `url(...)` among declarations, before a `;` or after a space. Values with a quote or a backslash inside the URL, or with unbalanced quotes, are now rejected
* **ViewContainerRef:** `move` without an index moves the view to the end of the container, where it threw a `RangeError`. Moving a view to the index it is already at leaves it in place, where it reordered the DOM nodes of a view that has more than one. Moving a view to an index out of range throws a `RangeError` and leaves the container as it was, where it removed the view from the container but left its DOM nodes on the page. A view inserted or moved after a view without DOM nodes, such as one of an empty `<template>`, is put after the nearest view before it that has some, or at the start of the container, where its DOM nodes were not added to the page or not moved.

## 1.1.2

### Fixes in 1.1.2

* **Compiler:** Requires `kelicap_compiler` 1.1.2, whose views work in a release build (dart2js) when an element with events, children or directives is the top one of a `*ngFor` or `*ngIf`
* **Change detection:** The error of `debugCheckBindings` reads "An expression bound in a Kelicap template", where it read "an Kelicap template"

## 1.1.1

* chore: Add documentation link to pubspec.yaml
* chore: Update README

## 1.1.0

* chore: Upgrade min sdk to 3.13.0 and other dependency upgrades
* chore: Add kelicap logo to README

## 1.0.2

* feat: Update injector
* fix: Misc. JavaScript runtime errors contributed by the community

## 1.0.1

* fix: Replace `querySelector` with `document.querySelector`
* chore: Update README

## 1.0.0

* chore: Initial release
