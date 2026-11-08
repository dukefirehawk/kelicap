import 'package:test/test.dart';

// ignore: avoid_relative_lib_imports
import '../../lib/compiler.dart';

import 'package:kelicap_compiler/v2/context.dart';

void main() {
  setUp(CompileContext.overrideForTesting);

  test('should require integer value for "tabindex"', () async {
    await compilesExpecting(
      '''
      import '$ngImport';

      @Component(
        selector: 'test',
        template: '<div tabindex="foo"></div>',
      )
      class TestComponent {}
    ''',
      errors: [contains('The "tabindex" attribute expects an integer value')],
    );
  });

  for (final binding in ['[(value)]', '[(value)]=""']) {
    test('should require an expression for "$binding"', () async {
      await compilesExpecting(
        '''
        import '$ngImport';

        @Component(
          selector: 'test',
          template: '<input $binding>',
        )
        class TestComponent {}
      ''',
        errors: [contains("Two-way binding '[(name)]' requires an expression")],
      );
    });
  }

  for (final binding in ['(click)', '(click)=""', '(click)="  "']) {
    test('should require an expression for "$binding"', () async {
      await compilesExpecting(
        '''
        import '$ngImport';

        @Component(
          selector: 'test',
          template: '<button $binding></button>',
        )
        class TestComponent {}
      ''',
        errors: [contains('events must have a bound expression: click')],
      );
    });
  }
}
