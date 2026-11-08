import 'package:kelicap_ast/kelicap_ast.dart';
import 'package:test/test.dart';

void main() {
  final recovering = RecoveringExceptionHandler();

  List<StandaloneTemplateAst> parse(String template, {bool recover = false}) {
    recovering.exceptions.clear();
    return const NgParser().parse(
      template,
      sourceUrl: '/test/regression_test.dart#inline',
      exceptionHandler: recover ? recovering : const ThrowingExceptionHandler(),
      desugar: false,
    );
  }

  String humanize(List<StandaloneTemplateAst> asts) => asts
      .map((ast) => ast.accept(const HumanizingTemplateAstVisitor()))
      .join();

  List<ParserErrorCode> errors() => [
    for (final e in recovering.exceptions) e.errorCode,
  ];

  group('a decorator without a value', () {
    test('has a source span for `on-` and `bind-`', () {
      final element = parse('<div on-foo bind-bar></div>').single as ElementAst;
      expect(element.events.single.sourceSpan.text, 'on-foo');
      expect(element.properties.single.sourceSpan.text, 'bind-bar');
    });

    test('is reported, not a crash, on <ng-content> and <ng-container>', () {
      for (final (template, error) in [
        (
          '<ng-content on-foo></ng-content>',
          ParserErrorCode.invalidDecoratorInNgContent,
        ),
        (
          '<ng-container bind-foo></ng-container>',
          ParserErrorCode.invalidDecoratorInNgContainer,
        ),
      ]) {
        expect(
          () => parse(template),
          throwsA(
            isA<KelicapParserException>().having(
              (e) => e.errorCode,
              'errorCode',
              error,
            ),
          ),
          reason: template,
        );
        parse(template, recover: true);
        expect(errors(), [error], reason: template);
      }
    });
  });

  group('recovery', () {
    for (final template in ['<div @', '<div @>']) {
      test('reports an annotation prefix without a name in "$template"', () {
        parse(template, recover: true);
        expect(errors(), contains(ParserErrorCode.elementDecoratorAfterPrefix));
      });
    }

    test('keeps the closing tag after an annotation prefix and a value', () {
      final asts = parse('<div @="x"></div>', recover: true);
      expect(humanize(asts), '<div @="x"></div>');
      expect(errors(), [ParserErrorCode.elementDecoratorAfterPrefix]);
    });

    for (final template in [r'<div #%></div>', r'<div #\></div>']) {
      test('reports an invalid reference name in "$template"', () {
        expect(humanize(parse(template, recover: true)), '<div #></div>');
        expect(errors(), contains(ParserErrorCode.expectedToken));
      });
    }

    test('reports an invalid template name', () {
      expect(humanize(parse('<div *%></div>', recover: true)), '<div *></div>');
      expect(errors(), contains(ParserErrorCode.expectedToken));
    });
  });

  group('whitespace', () {
    String minimize(String template) => humanize(
      const MinimizeWhitespaceVisitor().visitAllRoot(parse(template)),
    );

    test('is kept in a <textarea>, whose text is its value', () {
      expect(
        minimize('<textarea>  a\n   b </textarea>'),
        '<textarea>  a\n   b </textarea>',
      );
    });

    test('drops a newline at the start of a <textarea> or <pre>', () {
      expect(
        minimize('<textarea>\nfoo</textarea>'),
        '<textarea>foo</textarea>',
      );
      expect(
        minimize('<textarea>\r\nfoo</textarea>'),
        '<textarea>foo</textarea>',
      );
      expect(minimize('<pre>\n  a</pre>'), '<pre>  a</pre>');
      expect(minimize('<textarea>\n</textarea>'), '<textarea></textarea>');
      // As in the browser, only the newline is dropped, not the indentation.
      expect(
        minimize('<textarea>\n    </textarea>'),
        '<textarea>    </textarea>',
      );
    });

    test('replaces &ngsp; with a space in a <textarea>', () {
      expect(
        minimize('<textarea>a&ngsp;b</textarea>'),
        '<textarea>a b</textarea>',
      );
    });

    test('is kept in a <pre> of any case', () {
      expect(minimize('<PRE>  a   b  </PRE>'), '<PRE>  a   b  </PRE>');
    });

    for (final tag in ['u', 's', 'mark', 'ins', 'del', 'bdi', 'data']) {
      test('is kept between inline <$tag> elements', () {
        expect(
          minimize('<div>\n  <$tag>a</$tag> <$tag>b</$tag>\n</div>'),
          '<div><$tag>a</$tag> <$tag>b</$tag></div>',
        );
      });
    }
  });

  group('entities', () {
    String text(String template) => (parse(template).single as TextAst).value;

    test('an unknown named entity is left as it is', () {
      expect(text('a &foo; b'), 'a &foo; b');
      expect(text('x=1&y;z'), 'x=1&y;z');
    });

    test('a named entity is decoded, including one with digits', () {
      expect(text('a &amp; b'), 'a & b');
      expect(text('&frac12;'), '½');
    });

    test('a numeric entity of any length is decoded', () {
      expect(text('&#9;|'), '\t|');
      expect(text('&#65;'), 'A');
      expect(text('&#128512;'), '😀');
      expect(text('&#x1F600;'), '😀');
      expect(text('&#X41;'), 'A');
    });

    test('a numeric entity that is not a character is replaced', () {
      expect(text('&#0;'), '�');
      expect(text('&#xD800;'), '�');
      expect(text('&#x110000;'), '�');
      expect(text('&#99999999999999999999;'), '�');
    });
  });

  group('two-way binding', () {
    for (final template in ['<input [(foo)]>', '<input [(foo)]="">']) {
      test('without an expression is reported in "$template"', () {
        expect(
          () => const NgParser().parse(
            template,
            sourceUrl: '/test/regression_test.dart#inline',
          ),
          throwsA(
            isA<KelicapParserException>().having(
              (e) => e.errorCode,
              'errorCode',
              ParserErrorCode.bananaMissingValue,
            ),
          ),
        );
      });
    }

    test('with an expression is desugared', () {
      final asts = const NgParser().parse(
        '<input [(foo)]="bar">',
        sourceUrl: '/test/regression_test.dart#inline',
      );
      expect(humanize(asts), r'<input (fooChange)="bar = $event" [foo]="bar">');
    });
  });

  group('doctype', () {
    test('is recognized in any case', () {
      expect(
        humanize(parse('<!doctype html><b>x</b>')),
        '<!doctype html><b>x</b>',
      );
    });

    test('is not a template that starts with ">"', () {
      final asts = parse('> a <b>x</b>');
      expect((asts.first as TextAst).value, '> a ');
      expect(humanize(asts), '> a <b>x</b>');
    });
  });

  group('source spans', () {
    test('of text cover its source after an entity', () {
      expect(parse('a &amp; b<i>y</i>').first.sourceSpan.text, 'a &amp; b');
      expect(parse('a &#x1F600; b').single.sourceSpan.text, 'a &#x1F600; b');
    });

    test('of an attribute cover an escaped quote', () {
      final element =
          parse(r'''<div a="x\"y" b='x\'y' c="z"></div>''').single
              as ElementAst;
      expect(
        [for (final a in element.attributes) a.sourceSpan.text],
        [r'a="x\"y"', r"b='x\'y'", 'c="z"'],
      );
      expect(
        [for (final a in element.attributes) a.value],
        ['x"y', "x'y", 'z'],
      );
    });

    test('of an attribute with an escaped backslash before its quote', () {
      final element = parse(r'<div a="x\\" b="c"></div>').single as ElementAst;
      expect(
        [for (final a in element.attributes) a.sourceSpan.text],
        [r'a="x\\"', 'b="c"'],
      );
    });

    test('of an attribute that ends with an escaped quote is unclosed', () {
      parse(r'<div title="a\"', recover: true);
      expect(errors(), contains(ParserErrorCode.enclosedQuote));
    });
  });

  group('AST', () {
    test('a reference has the offset of its prefix', () {
      final element = parse('<div #foo></div>').single as ElementAst;
      final reference = element.references.single as ParsedReferenceAst;
      expect(reference.prefixOffset, 5);
      expect(reference.nameOffset, 6);
    });

    test('stars are equal to stars, not properties', () {
      expect(StarAst('ngIf', 'x'), StarAst('ngIf', 'x'));
      expect(StarAst('ngIf', 'x'), isNot(PropertyAst('ngIf', 'x')));
    });

    test('an event has a stable hash code', () {
      final element =
          parse('<div (keydown.ctrl.a)="x()"></div>').single as ElementAst;
      final event = element.events.single;
      expect(event.hashCode, event.hashCode);
      expect(
        event.hashCode,
        EventAst('keydown', 'x()', ['ctrl', 'a']).hashCode,
      );
    });

    test('events and properties are equal only with equal values', () {
      expect(EventAst('click', 'a()'), isNot(EventAst('click', 'b()')));
      expect(PropertyAst('title', 'a'), isNot(PropertyAst('title', 'b')));
      expect(EventAst('click', 'a()'), EventAst('click', 'a()'));
      expect(PropertyAst('title', 'a'), PropertyAst('title', 'a'));
    });

    test('a parsed node with children is a parent', () {
      final element = parse('<div><span></span></div>').single;
      expect(element.isParent, isTrue);
      expect(element.childNodes.single.isParent, isFalse);
    });
  });

  group('a dangling close tag', () {
    test('of an <ng-container> is a container', () {
      final asts = parse('</ng-container>', recover: true);
      expect(asts.single, isA<ContainerAst>());
      expect(errors(), [ParserErrorCode.danglingCloseElement]);
    });

    test('of an <ng-container> keeps its close tag when desugared', () {
      recovering.exceptions.clear();
      final asts = const NgParser().parse(
        '</ng-container>',
        sourceUrl: '/test/regression_test.dart#inline',
        exceptionHandler: recovering,
      );
      final container = asts.single as ContainerAst;
      expect(container.closeComplement.isSynthetic, isFalse);
      expect(container.closeComplement.sourceSpan.text, '</ng-container>');
    });

    test('of a <template> is a template', () {
      final asts = parse('</template>', recover: true);
      expect(asts.single, isA<EmbeddedTemplateAst>());
      expect(errors(), [ParserErrorCode.danglingCloseElement]);
    });
  });

  test('an invalid micro-expression is reported at its start', () {
    const template = '<div *ngFor="   let x ="></div>';
    recovering.exceptions.clear();
    const NgParser().parse(
      template,
      sourceUrl: '/test/regression_test.dart#inline',
      exceptionHandler: recovering,
    );
    final error = recovering.exceptions.single;
    expect(error.errorCode, ParserErrorCode.invalidMicroExpression);
    expect(error.offset, template.indexOf('let'));
  });

  group('desugaring synthetic nodes', () {
    String desugar(StandaloneTemplateAst ast) =>
        humanize([ast.accept(DesugarVisitor()) as StandaloneTemplateAst]);

    test('desugars a star with micro-syntax', () {
      final element = ElementAst(
        'div',
        CloseElementAst('div'),
        stars: [StarAst('ngFor', 'let x of xs')],
      );
      expect(
        desugar(element),
        '<template ngFor [ngForOf]="xs" let-x><div></div></template>',
      );
    });

    test('desugars nodes with unmodifiable lists', () {
      final element = ElementAst(
        'input',
        null,
        bananas: List.unmodifiable([BananaAst('foo', 'bar')]),
      );
      expect(
        desugar(element),
        r'<input (fooChange)="bar = $event" [foo]="bar"/>',
      );

      final container = ContainerAst(
        childNodes: List.unmodifiable([
          ElementAst(
            'i',
            CloseElementAst('i'),
            stars: List.unmodifiable([StarAst('ngIf', 'y')]),
          ),
        ]),
        stars: List.unmodifiable([StarAst('ngIf', 'x')]),
      );
      expect(
        desugar(container),
        '<template [ngIf]="x"><ng-container>'
        '<template [ngIf]="y"><i></i></template>'
        '</ng-container></template>',
      );
    });
  });

  group('humanizing', () {
    test('includes the value of an annotation', () {
      expect(
        humanize(parse('<div @skipSchemaValidationFor="x"></div>')),
        '<div @skipSchemaValidationFor="x"></div>',
      );
    });

    test('includes ngProjectAs and the reference of <ng-content>', () {
      expect(
        humanize(
          parse('<ng-content select="a" ngProjectAs="b" #ref></ng-content>'),
        ),
        '<ng-content select="a" ngProjectAs="b" #ref></ng-content>',
      );
    });

    test('includes the events of a <template>', () {
      expect(
        humanize(parse('<template (foo)="bar()"></template>')),
        '<template (foo)="bar()"></template>',
      );
    });
  });
}
