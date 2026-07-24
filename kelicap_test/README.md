# Kelicap Test

## Overview

`kelicap_test` is a library for writing tests for Kelicap.

```dart
// Assume this is 'my_test.dart'.
import 'my_test.template.dart' as ng;

void main() {
  tearDown(disposeAnyRunningTest);

  test('should render "Hello World"', () async {
    final testBed = NgTestBed<HelloWorldComponent>();
    final testFixture = await testBed.create();
    expect(testFixture.text, 'Hello World');
    await testFixture.update((c) => c.name = 'Universe');
    expect(testFixture.text, 'Hello Universe');
  });
}

@Component(selector: 'test', template: 'Hello {{name}}')
class HelloWorldComponent {
  String name = 'World';
}
```

To use `kelicap_test`, configure your package's `pubspec.yaml` as follows:

```yaml
# Use the latest versions if possible.
dev_dependencies:
  build_runner: ^2.10.0
  build_test: ^3.0.0
  build_web_compilers: ^4.6.0
```

**IMPORTANT**: `kelicap_test` will not run without these dependencies set.

To run tests, use `dart run build_runner test`. It automatically compiles your templates and annotations with Kelicap, and then compiles all of the Dart code to JavaScript in order to run browser tests. Here's an example of using Chrome with Dartdevc:

```bash
dart run build_runner test -- -p chrome
```

For more information using `dart run build_runner test`, see the documentation:
<https://github.com/dart-lang/build/tree/master/build_runner#built-in-commands>

## Debug

* `.dart_tool/build/entrypoint/build.dart`
* `dart run build_runner build --dart-jit-vm-arg=--observe --dart-jit-vm-arg=--pause-isolates-on-start`
