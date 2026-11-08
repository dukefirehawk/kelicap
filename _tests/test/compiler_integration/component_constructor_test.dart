import 'package:test/test.dart';

// ignore: avoid_relative_lib_imports
import '../../lib/compiler.dart';

import 'package:kelicap_compiler/v2/context.dart';

void main() {
  setUp(CompileContext.overrideForTesting);

  test('uses the unnamed constructor after a private one', () async {
    await compilesNormally('''
      import '$ngImport';

      @Component(selector: 'test', template: '')
      class TestComponent {
        final String value;

        TestComponent._(this.value);

        factory TestComponent() => TestComponent._('value');
      }
    ''');
  });

  test('fails on a component with only a private constructor', () async {
    await compilesExpecting(
      '''
      import '$ngImport';

      @Component(selector: 'test', template: '')
      class TestComponent {
        TestComponent._();
      }
    ''',
      errors: [contains('No constructors found')],
    );
  });
}
