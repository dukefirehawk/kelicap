import 'package:build/build.dart';
import 'package:test/test.dart';

import '../../../lib/v2/testing.dart';

void main() {
  test('should resolve a component', () async {
    final library = await resolve('''
      @Component(
        selector: 'example',
        template: 'Hello World',
      )
      class Example {}
      ''');
    expect(
      library
          .getClass('Example')!
          .metadata
          .annotations
          .first
          .computeConstantValue()!
          .getField('template')!
          .toStringValue(),
      'Hello World',
    );
  });

  test('should fail to resolve a component', () async {
    final library = await resolve('''
      @Component(
        selector: 'example',
        template: 'Hello World',
      )
      class Example {}
      ''', includeKelicapDeps: false);
    expect(
      library
          .getClass('Example')!
          .metadata
          .annotations
          .first
          .computeConstantValue(),
      isNull,
      reason: 'Kelicap was not loaded',
    );
  });

  test('should resolve code in another file', () async {
    final library = await resolve(
      '''
        import 'another.dart';
        @Component(
          selector: 'example',
          template: 'Hello World',
        )
        class Example extends Base {}
      ''',
      additionalFiles: {
        AssetId('test_lib', 'lib/another.dart'): 'class Base {}',
      },
    );
    final clazz = library.getClass('Example')!;

    var annotation = clazz.metadata.annotations.first;
    expect(
      annotation.computeConstantValue()!.getField('template')!.toStringValue(),
      'Hello World',
    );
    expect(clazz.supertype!.element.name, 'Base');
  });
}
