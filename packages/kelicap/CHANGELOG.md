# Change Log

## 1.2.0

### New in 1.2.0

* **Signals:** `package:kelicap/signals.dart` adds signals: values that notify the code that reads them when they change. Create one with `signal(0)`, read it with `count()`, also in a template (`{{count()}}`), and change it with `count.set(1)` or `count.update((value) => value + 1)`. It also has `computed`, for values derived from signals, `effect`, to run code when the signals it read change, `untracked`, `batch`, and `toSignal` and `toStream`, which convert between streams and signals. Setting a signal to a new value runs change detection in every application that is running, even if it was set outside the `NgZone`, such as in code run with `NgZone.runOutsideKelicap`, and checks the components whose templates read it, so that an OnPush component that reads a signal is updated without calling `ChangeDetectorRef.markForCheck`. Only those components are checked: the OnPush components above them, and their siblings, are not, nor are their directives, such as an `*ngFor` that the component is in. Requires `kelicap_compiler` 1.2.0, which generates the code that reaches them. A signal read in a component's lifecycle hooks, or in the setters of its inputs, marks the component whose template uses it, not the component itself, as those run while that one is checked. A signal set while the component that reads it is checked, such as in its `ngAfterViewChecked`, does not mark it. An effect is not destroyed with the component that created it: destroy it in `ngOnDestroy`. The signals are built on `package:alien_signals`

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
