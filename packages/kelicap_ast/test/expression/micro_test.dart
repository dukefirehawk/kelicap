import 'package:kelicap_ast/src/expression/micro.dart';
import 'package:test/test.dart';

void main() {
  group('isMicroExpression', () {
    for (final expression in [
      'let x',
      'let x of xs',
      'let x of xs; let i = index',
      'let\n  x of xs',
      'items; let x',
      'items;let x',
      'user.items; let x',
      'foo(a);let x',
      "map['a'];let x",
      'a?.b; let x',
      'a??b; let x',
      'trackBy: fn',
      'trackBy:fn',
      'ngForOf: items; let x',
      'foo;',
      'key:a?b:c',
      'f(a, b); let x',
      "x == 'a b'; let y",
      'a?b:c; context: ctx',
      'cond ; let x',
    ]) {
      test('is true for "$expression"', () {
        expect(isMicroExpression(expression), isTrue);
      });
    }

    for (final expression in [
      'letter',
      'letter != null',
      'lettersCount > 0',
      'let',
      'let + 1',
      'let == 1',
      'a',
      'a != null',
      'a ? b : c',
      'a?b:c',
      'a?b: c',
      'a?b?c:d:e',
      'a?[0]:b',
      'a??b',
      'a?.b',
      'check(x: 1)',
      'check(x:1)',
      "map['a:b']",
      "map['a;b']",
      '"a:b"',
      r"'it\'s:b'",
      '{a:1}',
      '[a?b:c]',
      ':foo',
      ';foo',
      '',
    ]) {
      test('is false for "$expression"', () {
        expect(isMicroExpression(expression), isFalse);
      });
    }

    test('is false for null', () {
      expect(isMicroExpression(null), isFalse);
    });
  });
}
