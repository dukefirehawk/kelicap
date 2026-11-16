# Changelog

## 1.1.0

### New in 1.1.0

* **New project:** `kelicap create` makes a project that requires `kelicap` 2.0.1 or later and `kelicap_components` 2.0.0 or later, where it required `kelicap` 1.x and `kelicap_components` 1.x. Its `kelicap_test` dev dependency is ^2.0.1

### Fixes in 1.1.0

* **New project:** The comment of the todo list template links to `kelicap_components` on pub.dev. 1.0.5 still made it link to the old AngularDart site, as the template that the command copies was not updated
* **New project:** The description in the project's `pubspec.yaml` reads "A web app that uses Kelicap Components", where it read "AngularDart Components"

## 1.0.5

### Fixes in 1.0.5

* **New project:** The comment of the todo list template links to `kelicap_components` on pub.dev, where it linked to the old AngularDart site
* **Pubspec:** The package links to its documentation on the [Kelicap documentation](https://dukefirehawk.gitbook.io/kelicap-docs) site, from pub.dev, where it linked to the GitHub repository of the docs

## 1.0.4

### Fixes in 1.0.4

* **create:** `pub get` runs in the project at `--path`, not in a directory of that name in the current directory. If it fails, the command reports the error and exits with its exit code, rather than reporting success

## 1.0.3

* chore: Update template

## 1.0.2

* chore: Update template

## 1.0.1

* chore: Add documentation link

## 1.0.0

* chore: Initial version.
