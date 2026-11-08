# Kelicap Test

[![Kelicap Web Framework](../../assets/branding/kelicap_1_banner.jpeg)](https://github.com/dukefirehawk/kelicap)

![Pub Version (including pre-releases)](https://img.shields.io/pub/v/kelicap_test?include_prereleases)
[![Null Safety](https://img.shields.io/badge/null-safety-brightgreen)](https://dart.dev/null-safety)
[![License](https://img.shields.io/github/license/dukefirehawk/kelicap)](https://github.com/dukefirehawk/kelicap/blob/main/LICENSE)

Testing for Kelicap components. `NgTestBed` creates a component in the browser's DOM, and its `NgTestFixture` changes the component's state, waits for change detection and asynchronous work to settle, and reads what the component rendered.

## Installation

```yaml
dev_dependencies:
  build_runner: ^2.4.0
  build_test: ^3.0.0
  build_web_compilers: ^4.8.0
  kelicap_test: ^1.1.3
  test: ^1.22.0
```

Tests of components run in a browser. Add a `dart_test.yaml` to your package:

```yaml
platforms: [chrome]
```

## Writing a test

```dart
import 'package:kelicap/kelicap.dart';
import 'package:kelicap_test/kelicap_test.dart';
import 'package:test/test.dart';

import 'greeting_test.template.dart' as ng;

@Component(selector: 'greeting', template: 'Hello {{name}}')
class GreetingComponent {
  var name = 'World';
}

void main() {
  tearDown(disposeAnyRunningTest);

  test('greets by name', () async {
    var testBed = NgTestBed<GreetingComponent>(ng.GreetingComponentNgFactory);
    var fixture = await testBed.create();
    expect(fixture.text, 'Hello World');

    await fixture.update((component) => component.name = 'Kelicap');
    expect(fixture.text, 'Hello Kelicap');
  });
}
```

The compiler generates `greeting_test.template.dart`, with the factory of each component in the test. `fixture.rootElement` is the component's element, for finding and clicking on its children. `disposeAnyRunningTest` removes the component after each test, as only one runs at a time. To provide services, pass `rootInjector` to `NgTestBed`.

## Running tests

Build the tests with `build_runner`, into a directory, and run them from it:

```bash
dart run build_runner build -o build
dart test --precompiled build
```

This compiles them with DDC, as in development. A release build compiles with dart2js, which is stricter about JavaScript interop, so run them with it too:

```bash
dart run build_runner build --define 'build_web_compilers:entrypoint=compiler=dart2js' -o build
dart test --precompiled build
```

`dart run build_runner test` also builds and runs them in one step, in a version of `build_runner` where it loads browser tests.

## Debugging the build

To debug the builders, run the build in a VM you can attach to:

```bash
dart run build_runner build --dart-jit-vm-arg=--observe --dart-jit-vm-arg=--pause-isolates-on-start
```

The build script it runs is `.dart_tool/build/entrypoint/build.dart`.
