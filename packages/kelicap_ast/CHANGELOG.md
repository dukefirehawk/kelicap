# Change Log

## 1.1.3

### Breaking changes in 1.1.3

* **Breaking:** `[(name)]` without an expression, or with an empty one, is reported as `bananaMissingValue`, where it was dropped, or bound `= $event`. Give it an expression, or remove it

### Fixes in 1.1.3

* **Micro-syntax:** A `*`-binding is only parsed as micro-syntax when it is. An expression whose first identifier begins with `let`, such as `*ngIf="letter != null"`, no longer fails to compile. A `:` or `;` inside a string or brackets, or a `:` of a conditional, no longer splits the expression, so `*ngIf="a?b:c"`, `*ngIf="check(x: 1)"` and `*ngIf="map['a:b']"` bind the whole expression
* **Micro-syntax:** A trailing `;`, as in `*ngFor="let x of xs;"`, is accepted, where it failed to parse
* **Micro-syntax:** An expression ends at a `;` outside of its strings and brackets, so `*ngFor="let x of m['a;b']"` binds `m['a;b']`, and a key is a name directly followed by `:`, so `a?b:c; context: ctx` binds the conditional `a?b:c`. An expression may have whitespace before its `;`, such as `f(a, b); context: ctx`, and the whitespace is trimmed from it. The error for an invalid micro-expression is reported at the expression, after any whitespace before it
* **Parser:** `on-name` and `bind-name` without a value have a source span, so the compiler reports a missing expression where it threw a `TypeError`, as did `<ng-content>` and `<ng-container>` with one
* **Parser:** In a recovering parse, as the compiler's, an `@` without a name, and a `%` or `\` after `#` or `*`, are reported as errors, where they threw. `<div @="x"></div>` keeps its closing tag
* **Whitespace:** The whitespace in a `<textarea>`, which is its value, is kept, as in a `<pre>`, which is matched in any case, except a newline at the start of either, which the browser drops as well. `&ngsp;` in them is replaced with a space. Whitespace between inline elements such as `<u>`, `<s>`, `<mark>`, `<ins>` and `<del>` is kept
* **Entities:** An unknown named entity, such as `&foo;`, is left as it is, where its `&` and `;` were removed. A numeric entity of any length is decoded, such as `&#x1F600;` and `&#9;`, which were left as text, and one that is not a character becomes U+FFFD, as in the browser
* **Doctype:** `<!doctype html>` is recognized in any case, and a template that starts with `>` is text, where it was read as a doctype up to the next `>`
* **Source spans:** The span of text with an entity, and of an attribute with an escaped quote or backslash, covers its source, where it ended early. An attribute value whose closing quote is escaped, such as `"a\"` at the end of a template, is reported as unclosed
* **AST:** `EventAst` and `PropertyAst` are equal only with equal values, `StarAst` compares to other stars, an event has a stable hash code, `ParsedReferenceAst.prefixOffset` is the offset of `#`, and a parsed node with children `isParent`
* **Parser:** A dangling `</ng-container>` or `</template>` is recovered as a container or a template, where it was an element
* **DesugarVisitor:** Desugars synthetic nodes, including those with unmodifiable lists, where it threw
* **HumanizingTemplateAstVisitor:** Includes the values of annotations, the events of a `<template>`, and the `ngProjectAs` and reference of an `<ng-content>`

## 1.1.2

No changes. Released with the other Kelicap packages, which share its version.

## 1.1.1

* chore: Add documentation link
* chore: Update README

## 1.1.0

* chore: Upgrade min sdk to 3.13.0 and other dependency upgrades

## 1.0.0

* chore: Initial commit
