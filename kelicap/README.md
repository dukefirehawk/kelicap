# Kelicap Web Framework

![Pub Version (including pre-releases)](https://img.shields.io/pub/v/kelicap?include_prereleases)
[![Null Safety](https://img.shields.io/badge/null-safety-brightgreen)](https://dart.dev/null-safety)
[![License](https://img.shields.io/github/license/dukefirehawk/kelicap)](https://github.com/dukefirehawk/kelicap/blob/master/LICENSE)

Kelicap is a lightweight, native-HTML web framework for Dart, built as a modernized derivative fork of AngularDart (ngdart) with support for Dart 3.12+. While its syntax remains close to AngularDart and stays compatible up to Angular 16. Kelicap follows its own development path rather than strictly following Angular features development. It will remain as a pure Dart web solution with no intent to mimic or bridge with Flutter.

## Architecture

Kelicap is structured into the following core packages:

* **`kelicap_ast`**: Defines the Abstract Syntax Tree (AST) used internally by the framework.
* **`kelicap_common`**: Contains shared internal utilities and core helper classes.
* **`kelicap_observable`**: Contains code for observables, the reactive primitive of Kelicap, providing change detection and state management.
* **`kelicap_compiler`**: Build-time tooling that compiles Kelicap applications into native HTML, CSS, and JavaScript.
* **`kelicap`**: The core runtime library powering Kelicap applications.
* **`kelicap_forms`**: Forms components for Kelicap framework.
* **`kelicap_router`**: Router components for Kelicap framework.

## Getting Started

### Pre-requisite

Dart 3.12 or later

### Installation

```yaml
    dependencies:
        kelicap: ^1.0.0
        kelicap_router: ^1.0.0
        web: ^1.0.0

    dev_dependencies:
        build_runner: ^2.4.0
        build_web_compilers: ^4.6.0
        lints: ^6.1.0
```

### Build and run

```bash
    dart pub upgrade
    dart run build_runner serve --enable-sourcemaps
```
