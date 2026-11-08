import 'package:kelicap_observable/kelicap_observable.dart';
import 'package:test/test.dart';

void main() {
  group('toObservableList', () {
    test('keeps a nested collection its element type cannot hold', () {
      final nested = [1, 2];
      final result = toObservableList<List<int>>([nested]);
      expect(result, [
        [1, 2],
      ]);
      expect(result.single, same(nested));
    });

    test('converts a nested collection its element type can hold', () {
      final result = toObservableList<List<dynamic>>([
        [1, 2],
      ]);
      expect(result.single, isA<ObservableList<dynamic>>());
    });

    test('converts nested collections of dynamic deeply', () {
      final result = toObservableList<dynamic>([
        [
          {'a': 1},
        ],
      ]);
      expect(result.single, isA<ObservableList<dynamic>>());
      expect(result.single.single, isA<ObservableMap<dynamic, dynamic>>());
    });
  });

  group('toObservableMap', () {
    test('keeps a nested collection its value type cannot hold', () {
      final nested = [1];
      final result = toObservableMap<String, List<int>>({'a': nested});
      expect(result['a'], same(nested));
    });

    test('converts a nested collection its value type can hold', () {
      final result = toObservableMap<String, dynamic>({
        'a': [1],
      });
      expect(result['a'], isA<ObservableList<dynamic>>());
    });

    test('keeps the order of a linked map', () {
      final keys = List.generate(50, (i) => 'key${50 - i}');
      final source = {for (final key in keys) key: 1};
      expect(toObservableMap<String, int>(source).keys, keys);
    });

    test('keeps the order of a nested linked map', () {
      final keys = List.generate(50, (i) => 'key${50 - i}');
      final nested = {for (final key in keys) key: 1};
      final result = toObservableMap<String, dynamic>({'nested': nested});
      expect((result['nested'] as Map).keys, keys);
    });
  });
}
