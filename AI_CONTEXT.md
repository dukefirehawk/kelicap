# Kelicap AI Context

## Overview

Kelicap is a lightweight, native-HTML alternative to Flutter Web. It is a derivative fork of AngularDart (ngdart), modernized to support Dart 3.12 and beyond. It diverges from the Angular TS development path, focusing on providing a fast and productive web framework that is syntactically similar to Angular 16. It strictly utilizes the modern `package:web` for DOM interactions.

## Project Structure

The project is set up as a Dart monorepo using the native Dart `workspace` feature (with some tooling provided by Melos). It follows a 3-layer architecture:

- `ast/` (`kelicap_ast`): The Abstract Syntax Tree of the Kelicap application.
- `compiler/` (`kelicap_compiler`): The build-time tool that compiles the application to native HTML and JavaScript.
- `observable/` (`kelicap_observable`): The reactive state management library that powers the framework.
- `common/` (`kelicap_common`): The shared utilities and common code used across the framework.
- `kelicap/` (`kelicap`): The runtime library that provides the foundation for the framework.
- `forms/` (`kelicap_forms`): The forms library that provides form handling and validation capabilities.
- `router/` (`kelicap_router`): The routing library that provides navigation and route management capabilities.

## Tech Stack

- **Language**: Dart `>=3.13.0 <4.0.0`
- **DOM Interop**: Uses `package:web` (`^1.1.1`)
- **Monorepo Tooling**: Dart workspaces and Melos.
- **Dependencies**: Uses `build`, `build_web_compilers`, `built_value`, `sanitize_html`, etc.

## Key Principles & Conventions

1. **Modern Dart Compatibility**: All code should adhere to Dart 3 standards (sound null safety, pattern matching, records, modifiers).
2. **`package:web` Adoption**: Any DOM operations or web interactions must use standard browser interop patterns and APIs compliant with `package:web`.
3. **Type-safe DOM Elements**: Ensure robust sanitization and strict type-safe access to DOM elements, avoiding raw dynamic JS interop where possible.
4. **Independent Path**: Do not follow the latest Angular TypeScript conventions if they conflict with the framework's native-HTML lightweight goal.

## Development Workflow

- **Branches**: Work on a topic branch, such as `feature/<name>` (e.g. `feature/dart3.13`), `refactor/<name>` or `fix/<name>`, and merge it into `main` with a pull request. `develop` was merged into `main` in the same way in the past, but is now behind it; `release/<yyyy.mm>` branches (e.g. `release/2026.07`) mark releases.
- **Setup**: The packages are a Dart workspace with Melos (`melos:` in the root `pubspec.yaml`, no `melos.yaml`). Run `dart pub get` at the root, which resolves them all into the root `pubspec.lock`. The examples (`examples/*`) are outside the workspace: they reach the local packages through their own `pubspec_overrides.yaml`. The root `pubspec_overrides.yaml` only holds commented-out git overrides.
- **Code generation**: Components compile to `*.template.dart` files at build time, written to `.dart_tool/build`, not to the source tree. So `dart analyze` reports `uri_has_not_been_generated` for their imports until `dart run build_runner build` has run in that package. Don't commit generated templates.
- **Checks**: In each package you changed, from its directory:

  ```bash
  dart format --output=none --set-exit-if-changed .
  dart analyze
  ```

  Then run the tests, whose platform the package's `dart_test.yaml` sets:

  - **VM tests** (`kelicap_ast`, `kelicap_compiler`): `dart run build_runner test`, or `dart test`.
  - **Browser tests**, in Chrome (`kelicap_forms`, `kelicap_router`, `kelicap_test`, and `kelicap_observable`, which runs on both): build them with DDC into a directory outside the repo, and run them from it:

    ```bash
    dart run build_runner build -o /tmp/<package>_ddc
    dart test --precompiled /tmp/<package>_ddc -P ci
    ```

    Don't use `dart run build_runner test` for them: with build_runner 2.16 every browser test fails to load (`Failed to load script at .../*.browser_test.dart.js`), although the build succeeds. Build the whole package with `-o <dir>`, not `-o test:<dir>`, which leaves out the `test/` level the runner looks for.

  `_tests/` holds the end-to-end tests of the framework, in two presets, which must be given, as without one its browser tests are loaded on the VM and fail (`'JSObject' isn't a type`):

  ```bash
  cd _tests
  dart run build_runner build -o /tmp/tests_ddc
  dart test --precompiled /tmp/tests_ddc -P browser   # in Chrome
  dart test -P vm                                     # test/compiler, test/compiler_integration, test/compiler_resolved
  ```

  `test/compiler_resolved` holds the tests of `kelicap_compiler` that resolve code importing `package:kelicap`. Put new tests of that kind there, not in `kelicap_compiler`, which must not depend on `kelicap` (that depends on it). If they fail inside the analyzer (`ast_binary_reader.dart`, such as `NullAwareElementImpl is not a subtype of ExpressionImpl`), delete `.dart_tool/build_resolvers`: its cached SDK summary is stale, and is rebuilt.

  Some of these tests already fail. Before you change the compiler, run them, so you can tell your failures from those.
- **Release builds (dart2js)**: The DDC builds above and `build_runner serve` tolerate dynamic access to JavaScript objects. A release build (`build_runner build --release`, dart2js) does not, so code can work in development and fail in production. `[(ngModel)]` did so when `kelicap_forms` read `$event.target.value` in a `@HostListener`, and so did an element at the top of a `*ngFor` or `*ngIf` that the compiler generated as `dynamic`. After changing anything that touches the DOM, or the code the compiler generates, also run the tests with dart2js:

  ```bash
  dart run build_runner build --define 'build_web_compilers:entrypoint=compiler=dart2js' -o /tmp/<package>_js
  dart test --precompiled /tmp/<package>_js -P ci
  ```

  and build an example in release mode, served as static files, and check it in a browser:

  ```bash
  cd examples/hello_world
  dart run build_runner build --release -o web:/tmp/hello_world
  ```

  Never read members of `$event`, or of other DOM objects, dynamically in templates or `@HostListener` arguments: pass `$event` to a method that takes a typed `Event` (or the element), and read it there.
- **CI**: None. `tool/ci.sh` is a leftover of `mono_repo`, which no workflow runs. Run the checks locally.
- **Versions**: All packages are released together and share a version (`1.1.2`; `kelicap_cli` has its own, `1.0.3`). Bump `version` in each package's `pubspec.yaml`, and the constraints between them, together. `tool/update_versions.dart` rewrites the dependency constraints of every pubspec from `tool/package_versions.yaml`, but that list is out of date (Dart 3.12, `lints` ^5): update it before running the tool, or it downgrades constraints.
- **Changelog**: Every user-facing change gets an entry in the affected package's `CHANGELOG.md`, written as plain-English statements about the package (not commit messages). Group a release's entries under `### Breaking changes in X.Y.Z` (each entry prefixed `**Breaking:**`), `### New in X.Y.Z` and `### Fixes in X.Y.Z`, in that order, omitting empty sections. Prefix each fix with a bold area label, e.g. ``* **Forms:** `[(ngModel)]` updates its model in a release build``. Entries before this format are flat lists of commit-style bullets (`- fix: ...`); write new releases in this format. Commit messages use [Conventional Commits](https://www.conventionalcommits.org/) (`type(scope): description`, `!` for breaking changes).

## Current Focus

Recent and ongoing efforts focus on modernizing UI components (such as sliders, progress bars, calendars, list reordering, and HTML rendering) by refactoring DOM interactions to utilize compliant `package:web` APIs.
