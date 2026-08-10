import 'package:test/test.dart';
// ignore: avoid_relative_lib_imports
import '../../lib/compiler.dart';
import 'package:kelicap_compiler/v2/context.dart';

void main() {
  CompileContext.overrideForTesting();

  group('should prevent providing an app-wide, singleton service', () {
    test('from a generated injector', () async {
      await compilesExpecting(
        """
        import '$ngImport';

        @GenerateInjector([
          ClassProvider(NgZone),
        ])
        final injectorFactory = null; // OK for compiler tests.
      """,
        errors: [
          allOf([
            contains(
              'singleton service provided by the framework that cannot be '
              'overridden or manually provided',
            ),
            containsSourceLocation(6, 15),
          ]),
        ],
      );
    });

    test('from a component', () async {
      await compilesExpecting(
        """
        import '$ngImport';

        @Component(
          selector: 'foo',
          template: '',
          providers: [ClassProvider(NgZone)],
        )
        class Foo {}
      """,
        errors: [
          allOf([
            contains(
              'singleton service provided by the framework that cannot be '
              'overridden or manually provided',
            ),
            containsSourceLocation(3, 9),
          ]),
        ],
      );
    });
  });
}
