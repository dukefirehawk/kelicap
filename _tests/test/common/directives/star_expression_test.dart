@TestOn('browser')
library;

import 'package:test/test.dart';
import 'package:kelicap/kelicap.dart';
import 'package:kelicap_test/kelicap_test.dart';

import 'package:_tests/matchers.dart';

import 'star_expression_test.template.dart' as ng;

void main() {
  tearDown(disposeAnyRunningTest);

  test('*-bindings support expressions that resemble micro-syntax', () async {
    final fixture = await NgTestBed<ExpressionsTest>(
      ng.createExpressionsTestFactory(),
    ).create();
    expect(fixture.rootElement, hasTextContent('1;2;3;4;5;'));

    await fixture.update((component) {
      component.letter = null;
      component.lettersCount = 0;
      component.flag = false;
      component.expected = 2;
      component.values = const {'a:b': false};
    });
    expect(fixture.rootElement, hasTextContent(''));
  });

  test('*-bindings still support micro-syntax', () async {
    final fixture = await NgTestBed<MicroSyntaxTest>(
      ng.createMicroSyntaxTestFactory(),
    ).create();
    expect(fixture.rootElement, hasTextContent('0a;1b;a;b;'));
  });
}

@Component(
  selector: 'expressions-test',
  directives: [NgIf],
  // On one line, so that the text has no whitespace between the elements.
  template:
      '<span *ngIf="letter != null">1;</span>'
      '<span *ngIf="lettersCount > 0">2;</span>'
      '<span *ngIf="flag?yes:no">3;</span>'
      '<span *ngIf="check(value: 1)">4;</span>'
      """<span *ngIf="values['a:b'] == true">5;</span>""",
)
class ExpressionsTest {
  String? letter = 'a';
  int lettersCount = 1;
  bool flag = true;
  bool yes = true;
  bool no = false;
  int expected = 1;
  Map<String, bool> values = const {'a:b': true};

  bool check({required int value}) => value == expected;
}

@Component(
  selector: 'micro-syntax-test',
  directives: [NgFor],
  template:
      '<span *ngFor="let item of items; let i = index">{{i}}{{item}};</span>'
      '<span *ngFor="let item of items;trackBy:byValue">{{item}};</span>',
)
class MicroSyntaxTest {
  List<String> items = ['a', 'b'];

  Object? byValue(int index, dynamic item) => item;
}
