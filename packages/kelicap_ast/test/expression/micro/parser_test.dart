import 'package:kelicap_ast/kelicap_ast.dart';
import 'package:kelicap_ast/src/expression/micro/ast.dart';
import 'package:kelicap_ast/src/expression/micro/parser.dart';

import 'package:test/test.dart';

void main() {
  NgMicroAst parse(String directive, String expression, int offset) {
    return const NgMicroParser().parse(
      directive,
      expression,
      offset,
      sourceUrl: '/test/expression/micro/parser_test.dart#inline',
    );
  }

  test('should parse a simple let', () {
    expect(
      parse('ngThing', 'let foo', 0),
      NgMicroAst(letBindings: [LetBindingAst('foo')], properties: []),
    );
  });

  test('should parse a let assignment', () {
    expect(
      parse('ngThing', 'let foo = bar; let baz', 0),
      NgMicroAst(
        letBindings: [LetBindingAst('foo', 'bar'), LetBindingAst('baz')],
        properties: [],
      ),
    );
  });

  test('should parse a simple let and a let assignment', () {
    expect(
      parse('ngThing', 'let baz; let foo = bar', 0),
      NgMicroAst(
        letBindings: [LetBindingAst('baz'), LetBindingAst('foo', 'bar')],
        properties: [],
      ),
    );
  });

  test('should parse a simple let and a let assignment with extra spaces', () {
    expect(
      parse('ngThing', 'let baz; let foo = bar ', 0),
      NgMicroAst(
        letBindings: [LetBindingAst('baz'), LetBindingAst('foo', 'bar')],
        properties: [],
      ),
    );
  });

  test('should parse a let with a full Dart expression', () {
    expect(
      parse('ngFor', 'let x of items.where(filter)', 0),
      NgMicroAst(
        letBindings: [LetBindingAst('x')],
        properties: [PropertyAst('ngForOf', 'items.where(filter)')],
      ),
    );
  });

  test('should parse a let/bind pair', () {
    expect(
      parse('ngFor', 'let item of items; trackBy: byId', 0),
      NgMicroAst(
        letBindings: [LetBindingAst('item')],
        properties: [
          PropertyAst('ngForOf', 'items'),
          PropertyAst('ngForTrackBy', 'byId'),
        ],
      ),
    );
  });

  test('should parse multiple binds', () {
    expect(
      parse('ngTemplateOutlet', 'templateRef; context: templateContext', 0),
      NgMicroAst(
        letBindings: [],
        properties: [
          PropertyAst('ngTemplateOutlet', 'templateRef'),
          PropertyAst('ngTemplateOutletContext', 'templateContext'),
        ],
      ),
    );
  });

  test('should parse a trailing semi-colon', () {
    // Names and values, as `PropertyAst ==` does not compare values.
    List<String> describe(NgMicroAst ast) => [
      for (final let in ast.letBindings) 'let ${let.name}=${let.value}',
      for (final property in ast.properties)
        '${property.name}=${property.value}',
    ];
    expect(describe(parse('ngFor', 'let item of items;', 0)), [
      'let item=null',
      'ngForOf=items',
    ]);
    expect(describe(parse('ngFor', 'let item of items; let i = index; ', 0)), [
      'let item=null',
      'let i=index',
      'ngForOf=items',
    ]);
    expect(describe(parse('ngIf', 'foo;', 0)), ['ngIf=foo']);
  });

  test('should throw a parser error on an empty expression', () {
    expect(
      () => parse('ngFor', '', 0),
      throwsA(TypeMatcher<KelicapParserException>()),
    );
    expect(
      () => parse('ngFor', ';', 0),
      throwsA(TypeMatcher<KelicapParserException>()),
    );
  });
}
