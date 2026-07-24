# Kelicap AST

![Pub Version (including pre-releases)](https://img.shields.io/pub/v/kelicap_ast?include_prereleases)
[![Null Safety](https://img.shields.io/badge/null-safety-brightgreen)](https://dart.dev/null-safety)
[![License](https://img.shields.io/github/license/dukefirehawk/kelicap)](https://github.com/dukefirehawk/kelicap/blob/master/LICENSE)

This package contains parsers and utilities for parsing Kelicap templates and expressions into a structured tree (Abstract Syntax Tree) representation of JavaScript objects (nodes). Each node represents an element, attribute, binding, or directive, enabling the Kelicap compiler to understand and validate the code.

## Example

```dart
var parser = TemplateParser();
var ast = parser.parse(r'<p>Hello {{ name }}</p>');
```
