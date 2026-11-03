# Change Log

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
