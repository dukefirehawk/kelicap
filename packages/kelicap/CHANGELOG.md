# Change Log

## 1.1.3

### Fixes in 1.1.3

* **Compiler:** Requires `kelicap_compiler` 1.1.3, for the template fixes of `kelicap_ast` 1.1.3. It has a breaking change: a two-way binding without an expression, such as `[(value)]`, fails to compile. See its changelog
* **NgFor:** The `even` and `odd` locals are updated for every item, including those that shift when an item is added or removed before them
* **Security:** `[style]` bindings accept `url(...)` values with a safe absolute URL, such as `url(https://example.com/a.png)`, in or out of quotes, which were replaced with `unsafe`. Values with a quote or a backslash inside the URL, or with unbalanced quotes, are now rejected
* **ViewContainerRef:** `move` without an index moves the view to the end of the container, where it threw a `RangeError`. Moving a view to the index it is already at leaves it in place, where it reordered the DOM nodes of a view that has more than one

## 1.1.2

### Fixes in 1.1.2

* **Compiler:** Requires `kelicap_compiler` 1.1.2, whose views work in a release build (dart2js) when an element with events, children or directives is the top one of a `*ngFor` or `*ngIf`
* **Change detection:** The error of `debugCheckBindings` reads "An expression bound in a Kelicap template", where it read "an Kelicap template"

## 1.1.1

- chore: Add documentation link to pubspec.yaml
- chore: Update README

## 1.1.0

- chore: Upgrade min sdk to 3.13.0 and other dependency upgrades
- chore: Add kelicap logo to README

## 1.0.2

- feat: Update injector
- fix: Misc. JavaScript runtime errors contributed by the community

## 1.0.1

- fix: Replace `querySelector` with `document.querySelector`
- chore: Update README

## 1.0.0

- chore: Initial release
