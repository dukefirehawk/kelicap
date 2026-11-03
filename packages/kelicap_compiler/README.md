# Kelicap Compiler

[![Kelicap Web Framework](../../assets/branding/kelicap_1_banner.jpeg)](https://github.com/dukefirehawk/kelicap)

![Pub Version (including pre-releases)](https://img.shields.io/pub/v/kelicap_compiler?include_prereleases)
[![Null Safety](https://img.shields.io/badge/null-safety-brightgreen)](https://dart.dev/null-safety)
[![License](https://img.shields.io/github/license/dukefirehawk/kelicap)](https://github.com/dukefirehawk/kelicap/blob/main/LICENSE)

The compiler of Kelicap. At build time, it compiles each component's template and styles into Dart code that creates and updates the DOM directly. It runs ahead of time, so template errors, such as an unknown property or a missing directive, fail the build rather than the app in the browser.

For a component in `app.dart`, it generates `app.template.dart`, with the component's factory (`AppComponentNgFactory`), which `runApp` and `NgTestBed` take. Generated files are written to `.dart_tool/build`, not to your source tree.

Applications don't depend on this package directly. The builder of [`kelicap`](https://pub.dev/packages/kelicap) runs it when you build your project with `build_runner`:

```bash
dart run build_runner serve web:8080                # development, with DDC
dart run build_runner build --release -o web:build  # production, with dart2js
```

The generated code uses `package:web` and is typed, so that it works in release builds compiled with dart2js as well as in development builds.

## Testing

```bash
dart run build_runner test
```
