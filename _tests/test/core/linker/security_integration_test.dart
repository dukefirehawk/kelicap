@TestOn('browser')
library;

import 'dart:js_interop';

import 'package:web/web.dart';

import 'package:kelicap_test/kelicap_test.dart';

import 'package:kelicap/src/security/dom_sanitization_service.dart';
import 'package:test/test.dart';
import 'package:kelicap/kelicap.dart';

import 'security_integration_test.template.dart' as ng;

void main() {
  tearDown(disposeAnyRunningTest);

  test('should escape unsafe attributes', () async {
    const unsafeUrl = 'javascript:alert(1)';
    final testBed = NgTestBed<UnsafeAttributeComponent>(
      ng.createUnsafeAttributeComponentFactory(),
    );
    final testFixture = await testBed.create();
    final a = testFixture.rootElement.querySelector('a') as HTMLAnchorElement;
    expect(a.href, matches(r'.*/hello$'));
    // `update` hands back the component instance, not the host element.
    await testFixture.update((component) {
      component.href = unsafeUrl;
    });
    expect(a.href, equals('unsafe:$unsafeUrl'));
  });

  test('should not escape values marked as trusted', () async {
    final testBed = NgTestBed(ng.createTrustedValueComponentFactory());
    final testFixture = await testBed.create();
    final a = testFixture.rootElement.querySelector('a') as HTMLAnchorElement;
    expect(a.href, 'javascript:alert(1)');
  });

  test('should throw error when using the wrong trusted value', () async {
    final testBed = NgTestBed(ng.createWrongTrustedValueComponentFactory());
    expect(testBed.create(), throwsA(isUnsupportedError));
  });

  test('should escape unsafe styles', () async {
    final testBed = NgTestBed<UnsafeStyleComponent>(
      ng.createUnsafeStyleComponentFactory(),
    );
    final testFixture = await testBed.create();
    final div = testFixture.rootElement.querySelector('div') as HTMLDivElement;
    expect(div.style.background, matches('red'));

    await testFixture.update((component) {
      component.backgroundStyle = 'url(javascript:evil())';
    });
    expect(div.style.background, isNot(contains('javascript')));
  });

  test('should escape unsafe HTML', () async {
    final testBed = NgTestBed<UnsafeHtmlComponent>(
      ng.createUnsafeHtmlComponentFactory(),
    );
    final testFixture = await testBed.create();
    final div = testFixture.rootElement.querySelector('div');
    expect((div?.innerHTML as JSString?)?.toDart, 'some <p>text</p>');
    await testFixture.update((component) {
      component.html = 'ha <script>evil()</script>';
    });
    expect((div?.innerHTML as JSString?)?.toDart, 'ha ');
    await testFixture.update((component) {
      component.html = 'also <img src="x" onerror="evil()"> evil';
    });
    // The whole `<img>` goes, not just its `onerror`: it is absent from the
    // browser sanitizer's default allow-list.
    expect((div?.innerHTML as JSString?)?.toDart, 'also  evil');
    await testFixture.update((component) {
      final srcdoc = '<div></div><script></script>';
      component.html = 'also <iframe srcdoc="$srcdoc"> content</iframe>';
    });
    // As with `<img>`, `<iframe>` is not on the default allow-list, so the
    // element is removed outright rather than kept with `srcdoc` stripped --
    // and its content goes with it.
    expect((div?.innerHTML as JSString?)?.toDart, 'also ');
  });
}

@Component(
  selector: 'unsafe-attribute',
  template: '<a [href]="href">Link Title</a>',
)
class UnsafeAttributeComponent {
  String href = 'hello';
}

@Component(
  selector: 'trusted-value',
  template: '<a [href]="href">Link Title</a>',
  providers: [ClassProvider(DomSanitizationService)],
)
class TrustedValueComponent {
  SafeUrl href;

  TrustedValueComponent(DomSanitizationService sanitizer)
    : href = sanitizer.bypassSecurityTrustUrl('javascript:alert(1)');
}

@Component(
  selector: 'wrong-trusted-value',
  template: '<a [href]="href">Link Title</a>',
  providers: [ClassProvider(DomSanitizationService)],
)
class WrongTrustedValueComponent {
  late SafeHtml href;

  WrongTrustedValueComponent(DomSanitizationService sanitizer) {
    href = sanitizer.bypassSecurityTrustHtml('javascript:alert(1)');
  }
}

@Component(
  selector: 'unsafe-style',
  template: '<div [style.background]="backgroundStyle"></div>',
)
class UnsafeStyleComponent {
  String backgroundStyle = 'red';
}

@Component(selector: 'unsafe-html', template: '<div [innerHtml]="html"></div>')
class UnsafeHtmlComponent {
  String html = 'some <p>text</p>';
}
