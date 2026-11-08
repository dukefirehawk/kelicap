# Change Log

## 1.1.3

### Fixes in 1.1.3

* **Router:** A root `<router-outlet>` that is destroyed and recreated, such as under `*ngIf`, navigates without calling the destroyed components' lifecycle methods, where it could throw and render nothing
* **Location:** `Location.subscribe` can be called more than once, including alongside the router, where it threw `Bad state: Stream has already been listened to`

## 1.1.2

No changes. Released with the other Kelicap packages, which share its version.

## 1.1.1

* chore: Add documentation link
* chore: Update README

## 1.1.0

* chore: Upgrade min sdk to 3.13.0 and other dependency upgrades

## 1.0.2

* fix: Update build.yaml

## 1.0.1

* chore: Update `pubspec.yaml` description

## 1.0.0

* chore: Initial release
