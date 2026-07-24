# Kelicap AST

This package contains parsers and utilities for parsing Kelicap templates and expressions into a structured tree (Abstract Syntax Tree) representation of JavaScript objects (nodes). Each node represents an element, attribute, binding, or directive, enabling the Kelicap compiler to understand and validate the code.

## Example

```dart
var parser = TemplateParser();
var ast = parser.parse(r'<p>Hello {{ name }}</p>');
```
