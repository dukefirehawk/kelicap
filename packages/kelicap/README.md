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

## Documentation

Read the [Kelicap Document](https://dukefirehawk.gitbook.io/kelicap-docs) online.

Try the components of `kelicap_components` live in the [Kelicap Components Gallery](https://kelicap-components-gallery.web.app/), with the source code of each example.
