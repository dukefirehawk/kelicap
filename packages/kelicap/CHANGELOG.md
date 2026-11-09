# Change Log

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
