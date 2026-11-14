# Kelicap Web Framework

[![Kelicap Web Framework](../../assets/branding/kelicap_1_banner.jpeg)](https://github.com/dukefirehawk/kelicap)

![Pub Version (including pre-releases)](https://img.shields.io/pub/v/kelicap?include_prereleases)
[![Null Safety](https://img.shields.io/badge/null-safety-brightgreen)](https://dart.dev/null-safety)
[![License](https://img.shields.io/github/license/dukefirehawk/kelicap)](https://github.com/dukefirehawk/kelicap/blob/main/LICENSE)

Kelicap is a lightweight web framework for Dart that renders native HTML. It is a modernized fork of AngularDart (ngdart) for Dart 3.13 and later, built on [`package:web`](https://pub.dev/packages/web). Its template syntax stays close to AngularDart and to Angular up to version 16, but Kelicap follows its own path rather than Angular's newer features. It is a pure Dart web framework, with no aim to mimic or bridge to Flutter.

This package is the runtime: components, directives, pipes, dependency injection, change detection and bootstrapping. Its builder runs the Kelicap compiler on your project when you build it.

## Packages

| Package | What it is |
| --- | --- |
| [`kelicap`](https://pub.dev/packages/kelicap) | The runtime, and the builder that compiles your templates |
| [`kelicap_forms`](https://pub.dev/packages/kelicap_forms) | Template-driven and reactive forms, with validators |
| [`kelicap_router`](https://pub.dev/packages/kelicap_router) | Routing for single-page applications |
| [`kelicap_test`](https://pub.dev/packages/kelicap_test) | Testing components in a browser |
| [`kelicap_observable`](https://pub.dev/packages/kelicap_observable) | Observable objects, lists and maps |
| [`kelicap_cli`](https://pub.dev/packages/kelicap_cli) | A command-line tool to create Kelicap projects |
| [`kelicap_compiler`](https://pub.dev/packages/kelicap_compiler), [`kelicap_ast`](https://pub.dev/packages/kelicap_ast), [`kelicap_common`](https://pub.dev/packages/kelicap_common) | Used by the packages above; you don't depend on them directly |

A library of UI components, [`kelicap_components`](https://github.com/dukefirehawk/kelicap_components), is developed in its own repository. See them in the [Kelicap Components Gallery](https://kelicap-components-gallery.web.app/).

## Getting started

Kelicap needs Dart 3.13 or later. The quickest start is `kelicap create <name>`, of [`kelicap_cli`](https://pub.dev/packages/kelicap_cli). To set up a project by hand, add to `pubspec.yaml`:

```yaml
dependencies:
  kelicap: ^1.1.3
  web: ^1.1.1

dev_dependencies:
  build_runner: ^2.4.0
  build_web_compilers: ^4.8.0
```

A component, in `lib/app.dart`:

```dart
import 'package:kelicap/kelicap.dart';

@Component(
  selector: 'my-app',
  template: '<h1>Hello {{name}}</h1>',
)
class AppComponent {
  var name = 'Kelicap';
}
```

Its entry point, `web/main.dart`, runs the factory the compiler generates in `app.template.dart`:

```dart
import 'package:kelicap/kelicap.dart';
import 'package:my_app/app.template.dart' as ng;

void main() {
  runApp(ng.AppComponentNgFactory);
}
```

And `web/index.html` loads it:

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <script defer src="main.dart.js"></script>
</head>
<body>
  <my-app></my-app>
</body>
</html>
```

## Build and run

During development, build and serve the app, rebuilding it as files change, at <http://localhost:8080>:

```bash
dart pub get
dart run build_runner serve web:8080
```

For production, build it with dart2js into `build/`, and serve that directory as static files:

```bash
dart run build_runner build --release -o web:build
```

The development build (DDC) tolerates dynamic access to JavaScript objects, and the release build (dart2js) does not, so test a release build before deploying. In templates and `@HostListener`s, pass `$event` to a method that takes a typed `Event`, rather than reading members such as `$event.target.value`.

## Signals

`package:kelicap/signals.dart` adds signals: values that notify the code that reads them when they change. A component can keep its state in signals, and read them in its template by calling them:

```dart
import 'package:kelicap/kelicap.dart';
import 'package:kelicap/signals.dart';

@Component(
  selector: 'todo-list',
  template: '''
    <h2>Tasks ({{count()}})</h2>
    <p *ngFor="let todo of todos()">{{todo}}</p>
    <button (click)="add('Another task')">Add</button>
  ''',
  directives: [NgFor],
  changeDetection: ChangeDetectionStrategy.onPush,
)
class TodoListComponent {
  final todos = signal(['Learn signals']);
  late final count = computed(() => todos().length);

  void add(String todo) => todos.update((todos) => [...todos, todo]);
}
```

- **Writing:** `set` and `update` change a signal. Setting it to a value that is `identical` to its current value notifies nothing, so update a list or a map by setting a new one, as above, rather than changing it in place.
- **Change detection:** setting a signal runs change detection, even outside of the `NgZone`, and checks only the components whose templates read it. With `ChangeDetectionStrategy.onPush`, the others, including those above them, are not checked, so a change costs only the components that show it. Plain fields of an OnPush component still need `ChangeDetectorRef.markForCheck`.
- **Derived values:** `computed(() => ...)` derives a value from signals. It is computed when it is read, and cached until a signal it read changes.
- **Effects:** `effect((onCleanup) { ... })` runs code now, and again whenever a signal it read changes. It is not destroyed with the component that created it: call `destroy()` on the `EffectRef` it returns, such as in `ngOnDestroy`.
- **Streams:** `toSignal(stream, initialValue: ...)` returns a signal of a stream's latest event: call `cancel()` on it when the component is destroyed. `toStream(signal)` returns a stream of a signal's values.
- **Reading without tracking:** `untracked(() => ...)` reads signals without being notified of their changes, and `batch(() => ...)` runs the effects of the signals it sets once, at its end.

A signal read in a component's lifecycle hooks, or in the setters of its inputs, checks the component whose template uses it, not the component itself, as those run while that one is checked. Do not set a signal that a component reads while that component is checked, such as in its `ngAfterViewChecked`: it is not checked again.

### Performance

With plain fields and the default change detection, every change detection pass checks every component. With signals and OnPush, a pass checks only the components that read a signal that changed. The [signals benchmark](https://github.com/dukefirehawk/kelicap/tree/main/examples/signals_bench) measures a table of rows rendered both ways. These are the mean times of one change and the pass that renders it, in a release build in Chrome:

| Change | 1,000 rows: fields | 1,000 rows: signals | 10,000 rows: fields | 10,000 rows: signals |
| --- | --- | --- | --- | --- |
| One row | 0.13 ms | < 0.01 ms | 1.9 ms | 0.10 ms |
| Nothing, such as an event that changes no state | 0.12 ms | < 0.01 ms | 1.9 ms | < 0.01 ms |
| Every row | 0.48 ms | 0.72 ms | 6.1 ms | 7.4 ms |

- **One row:** about 20 times faster. Only that row is checked: not the table above it, nor the `*ngFor` that lists the rows, which would compare all of them. Change detection goes through the rows only to find the one that changed, so the time still grows a little with their number.
- **Nothing:** a pass that follows an event that changed no signal checks nothing.
- **Every row:** about 1.2 to 1.5 times slower, as each signal that changes notifies the component that read it. Signals pay off when a change affects a small part of the page, which is the common case.

The times vary between runs, by up to half with 10,000 rows, and between machines: compare the columns of a row rather than the numbers themselves. The benchmark's README [compares it with Angular 22](https://github.com/dukefirehawk/kelicap/tree/main/examples/signals_bench#compared-with-angular-22), which checks the same rows: Kelicap is as fast or faster in each case.

## Documentation

Read the [Kelicap Document](https://dukefirehawk.gitbook.io/kelicap-docs) online.

Try the components of `kelicap_components` live in the [Kelicap Components Gallery](https://kelicap-components-gallery.web.app/), with the source code of each example.
