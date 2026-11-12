# Change Log

## 1.1.5

### Fixes in 1.1.5

* **Pubspec:** The package links to its documentation on the [Kelicap documentation](https://dukefirehawk.gitbook.io/kelicap-docs) site, from pub.dev, where it linked to the GitHub repository of the docs

## 1.1.4

No changes. Released with the other Kelicap packages, which share its version.

## 1.1.3

### Fixes in 1.1.3

* **toObservableList, toObservableMap:** A deep conversion no longer throws on a nested collection with a specific element type, such as `toObservableList<List<int>>`. Such a collection is kept as it is, and is not observable, as its element type is not available at runtime
* **toObservableMap, toObservable:** A deep conversion uses the kind of map it is given, so it keeps the order of a linked map, as a shallow conversion does
* **ObservableList:** `setAll` with an index above 0 no longer throws a `RangeError`, or reports the wrong elements as removed, while there is a listener
* **ChangeNotifier:** Changes are delivered to a new observer when the previous one cancelled with a delivery scheduled

## 1.1.2

No changes. Released with the other Kelicap packages, which share its version.

## 1.1.1

* chore: Add documentation link
* chore: Update README

## 1.1.0

* chore: Upgrade min sdk to 3.13.0 and other dependency upgrades
* chore: Remove dependency on dart_internal package
* refactor: Deprecated `toObservable` function and replaced with `toObservableList` and `toObservableMap` functions for better reactive state management.

## 1.0.0

* chore: Initial release
