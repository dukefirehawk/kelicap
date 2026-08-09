@TestOn('vm')
library;

import 'package:analyzer/dart/element/type.dart';
import 'package:kelicap_compiler/v1/src/compiler/output/convert.dart';
import 'package:kelicap_compiler/v1/src/compiler/output/output_ast.dart' as o;
import 'package:test/test.dart';

import '../src/resolve.dart';

void main() {
  group('fromDartType resolves a bare type parameter to', () {
    late DartType bounded;
    late DartType transitivelyBounded;
    late DartType unbounded;

    setUpAll(() async {
      final clazz = (await resolveClass('''
        class Example<T extends num, U extends T, V> {
          T? bounded;
          U? transitivelyBounded;
          V? unbounded;
        }
      '''))!;
      DartType typeOf(String field) =>
          clazz.fields.firstWhere((f) => f.name == field).type;
      bounded = typeOf('bounded');
      transitivelyBounded = typeOf('transitivelyBounded');
      unbounded = typeOf('unbounded');
    });

    test('its bound', () {
      expect(bounded, isA<TypeParameterType>(), reason: 'Sanity check');
      expect(
        fromDartType(bounded),
        isA<o.ExternalType>().having((t) => t.value.name, 'name', 'num?'),
      );
    });

    test('the bound of its bound', () {
      expect(
        fromDartType(transitivelyBounded),
        isA<o.ExternalType>().having((t) => t.value.name, 'name', 'num?'),
      );
    });

    test('dynamic when it has no bound', () {
      expect(fromDartType(unbounded), same(o.dynamicType));
    });

    test('nothing, when resolveBounds is false', () {
      expect(
        fromDartType(bounded, resolveBounds: false),
        isA<o.ExternalType>().having((t) => t.value.name, 'name', 'T?'),
      );
    });
  });
}
