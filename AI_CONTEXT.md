# Kelicap AI Context

## Overview

Kelicap is a lightweight, native-HTML alternative to Flutter Web. It is a derivative fork of AngularDart (ngdart), modernized to support Dart 3.12 and beyond. It diverges from the Angular TS development path, focusing on providing a fast and productive web framework that is syntactically similar to Angular 16. It strictly utilizes the modern `package:web` for DOM interactions.

## Project Structure

The project is set up as a Dart monorepo using the native Dart `workspace` feature (with some tooling provided by Melos). It follows a 3-layer architecture:

- `ast/` (`kelicap_ast`): The Abstract Syntax Tree of the Kelicap application.
- `compiler/` (`kelicap_compiler`): The build-time tool that compiles the application to native HTML and JavaScript.
- `kelicap/` (`kelicap`): The runtime library that provides the foundation for the framework.

## Tech Stack

- **Language**: Dart `>=3.12.0 <4.0.0`
- **DOM Interop**: Uses `package:web` (`^1.1.1`)
- **Monorepo Tooling**: Dart workspaces and Melos.
- **Dependencies**: Uses `build`, `build_web_compilers`, `built_value`, `sanitize_html`, etc.

## Key Principles & Conventions

1. **Modern Dart Compatibility**: All code should adhere to Dart 3 standards (sound null safety, pattern matching, records, modifiers).
2. **`package:web` Adoption**: Any DOM operations or web interactions must use standard browser interop patterns and APIs compliant with `package:web`.
3. **Type-safe DOM Elements**: Ensure robust sanitization and strict type-safe access to DOM elements, avoiding raw dynamic JS interop where possible.
4. **Independent Path**: Do not follow the latest Angular TypeScript conventions if they conflict with the framework's native-HTML lightweight goal.

## Current Focus

Recent and ongoing efforts focus on modernizing UI components (such as sliders, progress bars, calendars, list reordering, and HTML rendering) by refactoring DOM interactions to utilize compliant `package:web` APIs.
