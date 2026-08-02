# Hello World

## Development build

To debug locally with DDC:

```bash
dart pub get
webdev serve
```

To debug locally with Dart2JS, minified:

```bash
dart pub get
webdev serve --release
```

## Relese build

```bash
dart pub get
webdev build
```

## Debugging

dart --observe=9229 --pause-isolates-on-start run build_runner build

dart run build_runner build --dart-jit-vm-arg=--observe --dart-jit-vm-arg=--pause-isolates-on-start

dart run build_runner build --build-filter=lib/**.css.shim.dart --verbose

dart run build_runner serve
