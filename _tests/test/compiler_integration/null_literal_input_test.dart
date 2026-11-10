import 'package:test/test.dart';

// ignore: avoid_relative_lib_imports
import '../../lib/compiler.dart';

import 'package:kelicap_compiler/v2/context.dart';

void main() {
  setUp(CompileContext.overrideForTesting);

  Matcher isNotNullable(String input) =>
      contains('Input "$input" of CounterDirective is not nullable');

  String counter(String type) =>
      '''
      import '$ngImport';

      @Directive(selector: '[counter]')
      class CounterDirective<T> {
        @Input()
        set count($type value) {}
      }
    ''';

  String testComponent(String binding) =>
      '''
      @Component(
        selector: 'test',
        template: '<div counter $binding></div>',
        directives: [CounterDirective],
      )
      class TestComponent {
        int? maybe;
      }
    ''';

  test('fails on null bound to an input that is not nullable', () async {
    await compilesExpecting(
      counter('int') + testComponent('[count]="null"'),
      errors: [allOf(isNotNullable('count'), containsSourceLocation(1, 14))],
    );
  });

  for (final type in ['int?', 'dynamic', 'Object?', 'T']) {
    test('accepts null bound to an input of type $type', () async {
      await compilesNormally(counter(type) + testComponent('[count]="null"'));
    });
  }

  test('accepts null bound to an inherited input made nullable', () async {
    await compilesNormally('''      import '$ngImport';

      class BaseCounter {
        @Input()
        set count(int value) {}
      }

      @Directive(selector: '[counter]')
      class CounterDirective extends BaseCounter {
        @Input()
        @override
        set count(int? value) {}
      }
    ${testComponent('[count]="null"')}''');
  });

  test(
    'accepts an expression bound to an input that is not nullable',
    () async {
      await compilesNormally(counter('int') + testComponent('[count]="1"'));
    },
  );
}
