# Kelicap Observable

[![Kelicap Web Framework](../../assets/branding/kelicap_1_banner.jpeg)](https://github.com/dukefirehawk/kelicap)

![Pub Version (including pre-releases)](https://img.shields.io/pub/v/kelicap_observable?include_prereleases)
[![Null Safety](https://img.shields.io/badge/null-safety-brightgreen)](https://dart.dev/null-safety)
[![License](https://img.shields.io/github/license/dukefirehawk/kelicap)](https://github.com/dukefirehawk/kelicap/blob/main/LICENSE)

Objects, lists and maps that report their changes. Listen to an observable's `changes`, and get the changes made since the last report, in batches, rather than comparing copies of it.

Some uses for it:

* Logging, or saving, an object when it changes
* Updating a view of a list by the items that were added and removed, rather than by diffing the whole list
* Simple data binding, by listening to the changes of a model

## Usage

An `ObservableList` reports the items added and removed, in `listChanges`:

```dart
import 'package:kelicap_observable/kelicap_observable.dart';

void main() {
  var todos = ObservableList<String>.from(['Write tests']);
  todos.listChanges.listen((changes) {
    for (var change in changes) {
      print('At ${change.index}: removed ${change.removed}, added ${change.addedCount}');
    }
  });
  todos.add('Release');
}
```

An object of your own reports changes to its properties by extending `PropertyChangeNotifier`, and calling `notifyPropertyChange` in its setters:

```dart
class User extends PropertyChangeNotifier {
  String _name = '';

  String get name => _name;
  set name(String value) => _name = notifyPropertyChange(#name, _name, value);
}

void main() {
  var user = User();
  user.changes.listen((changes) => print(changes));
  user.name = 'Kelicap';
}
```

`ObservableMap` reports the keys added, removed and changed, in `changes`, as `MapChangeRecord`s. To compare two values yourself, without observing them, use a `Differ`, such as `ListDiffer` or `MapDiffer`.
