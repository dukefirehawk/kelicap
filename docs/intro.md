# Introduction

Welcome to the **Kelicap Web Framework**. This guide provides an overview of Kelicap, its core philosophy, and how it fits into the Dart web ecosystem.

## What is Kelicap?

**Kelicap** is a lightweight, high-performance web framework for modern Dart (3.13+). It originated as a modernized, derivative fork of **AngularDart (ngdart)**, redesigned to embrace modern Dart language features, sound null safety, and modern browser standards. Unlike Flutter Web which renders UI using a canvas or HTML engine, Kelicap compiles component templates directly into native HTML, CSS, and JavaScripts.

### Key characteristics

- **Pure Dart**: Write end-to-end web applications in Dart with zero JavaScript dependencies.
- **Native DOM**: Built directly on modern `package:web`.
- **Angular-16 Syntax**: Familiar template syntax (`*ngIf`, `*ngFor`, `[(ngModel)]`, `@Component`) with Angular 16 operational simplicity.

### Framework Philosophy & Design Goals

Kelicap follows a set of core principles designed to maximize developer productivity and web app runtime speed:

1. **Native HTML Rendering & Performance**
   - No heavy canvas engines or DOM abstractions. Kelicap generates minimal, optimized DOM manipulation code at build time.
2. **Clean Separation of Concerns**
   - Keeps templates, component controller logic, and encapsulated styles modular and maintainable.
3. **Compile-Time Optimization**
   - Employs AST parsing (`kelicap_ast`) and template code generation (`kelicap_compiler`) via `build_runner` to avoid slow runtime reflection (`dart:mirrors`).
4. **Independent Evolution**
   - While syntactically aligned with AngularDart, Kelicap focuses on lightweight, pure-Dart web solutions without forcing Angular TypeScript feature parity or Flutter interoperability wrappers.

## How Kelicap Differs from AngularDart & Modern Angular (TS)

| Feature / Aspect | AngularDart (Legacy) | Angular (TS) | Kelicap |
| :--- | :--- | :--- | :--- |
| **Language** | Dart 2.x | TypeScript | Dart 3.13+ |
| **DOM Interop** | `dart:html` (Deprecated) | Web DOM APIs via TS | `package:web` & `dart:js_interop` |
| **Build Tooling** | `webdev` / `build_runner` | Angular CLI / Vite / Webpack | `build_runner` |
| **State Primitives** | Streams | Signals / RxJS | Streams |
| **Rendering** | Direct DOM Manipulation | Ivy / Hydration | Direct DOM Manipulation |
