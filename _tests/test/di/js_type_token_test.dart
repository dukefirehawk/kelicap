@TestOn('browser')
library;

import 'package:test/test.dart';
import 'package:web/web.dart';
import 'package:kelicap/kelicap.dart';
import 'package:kelicap_test/kelicap_test.dart';

import 'js_type_token_test.template.dart' as ng;

// A `Type` literal of a `package:web` type is `JSObject` at runtime, so
// `Window` and `Document` were the same token, and an injector returned the
// first of their providers for both.

void main() {
  tearDown(disposeAnyRunningTest);

  group('A generated injector', () {
    late Injector injector;

    setUp(() => injector = jsTypeInjector(Injector.empty()));

    test('injects each package:web type from its own provider', () {
      final service = injector.get(BrowserService) as BrowserService;
      expect(identical(service.window, window), isTrue);
      expect(identical(service.document, document), isTrue);
    });

    test('injects a nullable or typedef of a type by the same token', () {
      final service = injector.get(AliasService) as AliasService;
      expect(identical(service.document, document), isTrue);
      expect(identical(service.body, document.body), isTrue);
    });

    test('injects a package:web type named with @Inject', () {
      final service = injector.get(InjectService) as InjectService;
      expect(identical(service.document, document), isTrue);
    });

    test('explains a lookup by the Type of a package:web type', () {
      expect(
        () => injector.get(Document),
        throwsA(
          predicate(
            (e) => '$e'.contains('A type of package:web'),
            'an error that explains package:web types',
          ),
        ),
      );
    });
  });

  group('A component', () {
    test('injects each package:web type from its own provider', () async {
      final fixture = await NgTestBed<ProvidesBrowserTypes>(
        ng.createProvidesBrowserTypesFactory(),
      ).create();
      final child = fixture.assertOnlyInstance.child!;
      expect(identical(child.window, window), isTrue);
      expect(identical(child.document, document), isTrue);
    });

    test('injects a package:web type from the root injector', () async {
      final fixture = await NgTestBed<UsesRootBrowserTypes>(
        ng.createUsesRootBrowserTypesFactory(),
        rootInjector: jsTypeInjector,
      ).create();
      final component = fixture.assertOnlyInstance;
      expect(identical(component.window, window), isTrue);
      expect(identical(component.document, document), isTrue);
    });

    test('still injects its host element as HTMLElement', () async {
      final fixture = await NgTestBed<InjectsHost>(
        ng.createInjectsHostFactory(),
      ).create();
      expect(
        identical(fixture.assertOnlyInstance.element, fixture.rootElement),
        isTrue,
      );
    });
  });
}

Window getWindow() => window;

Document getDocument() => document;

HTMLElement getBody() => document.body!;

@Injectable()
class BrowserService {
  final Window window;
  final Document document;

  BrowserService(this.window, this.document);
}

@Injectable()
class AliasService {
  final Document? document;
  // ignore: deprecated_member_use
  final HtmlElement body;

  // ignore: deprecated_member_use
  AliasService(@Optional() this.document, this.body);
}

@Injectable()
class InjectService {
  final Object document;

  InjectService(@Inject(Document) this.document);
}

// `Window` is first, so that `Document` used to find its provider.
@GenerateInjector([
  FactoryProvider(Window, getWindow),
  FactoryProvider(Document, getDocument),
  FactoryProvider(HTMLElement, getBody),
  ClassProvider(BrowserService),
  ClassProvider(AliasService),
  ClassProvider(InjectService),
])
final InjectorFactory jsTypeInjector = ng.jsTypeInjector$Injector;

@Directive(selector: '[browser-child]')
class BrowserChild {
  final Window window;
  final Document document;

  BrowserChild(this.window, this.document);
}

@Component(
  selector: 'provides-browser-types',
  template: '<div browser-child></div>',
  directives: [BrowserChild],
  providers: [
    FactoryProvider(Window, getWindow),
    FactoryProvider(Document, getDocument),
  ],
)
class ProvidesBrowserTypes {
  @ViewChild(BrowserChild)
  BrowserChild? child;
}

@Component(selector: 'uses-root-browser-types', template: '')
class UsesRootBrowserTypes {
  final Window window;
  final Document document;

  UsesRootBrowserTypes(this.window, this.document);
}

@Component(selector: 'injects-host', template: '')
class InjectsHost {
  final HTMLElement element;

  InjectsHost(this.element);
}
