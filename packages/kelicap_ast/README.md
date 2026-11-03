# Kelicap AST

[![Kelicap Web Framework](../../assets/branding/kelicap_1_banner.jpeg)](https://github.com/dukefirehawk/kelicap)

![Pub Version (including pre-releases)](https://img.shields.io/pub/v/kelicap_ast?include_prereleases)
[![Null Safety](https://img.shields.io/badge/null-safety-brightgreen)](https://dart.dev/null-safety)
[![License](https://img.shields.io/github/license/dukefirehawk/kelicap)](https://github.com/dukefirehawk/kelicap/blob/main/LICENSE)

The parser of Kelicap's templates. It turns a template into an abstract syntax tree (AST), whose nodes are its elements, attributes, text, interpolations, bindings, events, references and directives. The Kelicap compiler, [`kelicap_compiler`](https://pub.dev/packages/kelicap_compiler), uses it to validate and compile templates.

Applications don't depend on this package: it is for tools that read Kelicap templates, such as the compiler, linters and formatters.

## Usage

```dart
import 'package:kelicap_ast/kelicap_ast.dart';

void main() {
  var nodes = parse(
    '<p *ngIf="show">Hello {{name}}</p>',
    sourceUrl: 'hello.html',
  );
  for (var node in nodes) {
    print(node);
  }
}
```

By default, `parse` desugars the shorthand forms: `*ngIf` becomes a `<template>` element, and `[(ngModel)]` becomes a property binding and an event binding. Pass `desugar: false` to keep them as written.

A template with errors throws. To collect the errors instead, pass a `RecoveringExceptionHandler` as `exceptionHandler`, and read its `exceptions` after parsing.
