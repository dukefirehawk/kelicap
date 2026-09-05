# Kelicap Test

[![Kelicap Web Framework](../../assets/branding/kelicap_1_banner.jpeg)](https://github.com/dukefirehawk/kelicap)

![Pub Version (including pre-releases)](https://img.shields.io/pub/v/kelicap_test?include_prereleases)
[![Null Safety](https://img.shields.io/badge/null-safety-brightgreen)](https://dart.dev/null-safety)
[![License](https://img.shields.io/github/license/dukefirehawk/kelicap)](https://github.com/dukefirehawk/kelicap/blob/master/LICENSE)

## Overview

To run tests, use `dart run build_runner test`. It automatically compiles your templates and annotations with Kelicap, and then compiles all of the Dart code to JavaScript in order to run browser tests. Here's an example of using Chrome with Dartdevc:

```bash
dart run build_runner test -- -p chrome
```

For more information using `dart run build_runner test`, see the documentation:
<https://github.com/dart-lang/build/tree/master/build_runner#built-in-commands>

## Debug

* `.dart_tool/build/entrypoint/build.dart`
* `dart run build_runner build --dart-jit-vm-arg=--observe --dart-jit-vm-arg=--pause-isolates-on-start`
