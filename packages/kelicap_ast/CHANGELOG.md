# Change Log

## 1.1.3

### Fixes in 1.1.3

* **Micro-syntax:** A `*`-binding is only parsed as micro-syntax when it is. An expression whose first identifier begins with `let`, such as `*ngIf="letter != null"`, no longer fails to compile. A `:` or `;` inside a string or brackets, or a `:` of a conditional, no longer splits the expression, so `*ngIf="a?b:c"`, `*ngIf="check(x: 1)"` and `*ngIf="map['a:b']"` bind the whole expression

## 1.1.2

No changes. Released with the other Kelicap packages, which share its version.

## 1.1.1

- chore: Add documentation link
- chore: Update README

## 1.1.0

- chore: Upgrade min sdk to 3.13.0 and other dependency upgrades

## 1.0.0

- chore: Initial commit
