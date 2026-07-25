# Kelicap Web Framework

Kelicap is a lightweight, native-HTML web framework for Dart—built as a modernized fork of AngularDart (ngdart) with support for Dart 3.12+. While its syntax remains close to AngularDart and stays compatible up to Angular 16, Kelicap follows its own path moving forward rather than strictly tracking Angular features. It is a pure Dart web solution with no intent to mimic or bridge with Flutter.

## Architecture

Kelicap is structured into the following core modules:

* **`ast`**: Defines the Abstract Syntax Tree (AST) used internally by the framework.
* **`common`**: Contains shared internal utilities and core helper classes.
* **`compiler`**: Build-time tooling that compiles Kelicap applications into native HTML, CSS, and JavaScript.
* **`kelicap`**: The core runtime library powering Kelicap applications.## Getting Started

## Pre-requisite

Dart 3.12 or later

## Installation

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

## Build and run

```bash
    dart pub upgrade
    dart run build_runner build
```
