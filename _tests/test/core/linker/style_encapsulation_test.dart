import 'package:web/web.dart';

import 'package:test/test.dart';
import 'package:kelicap/kelicap.dart';

import 'package:kelicap_test/kelicap_test.dart';

import 'style_encapsulation_test.template.dart' as ng;

void main() {
  tearDown(() {
    // TODO: Migrate to dart 3.6 (Need to review)
    //document.head!.querySelectorAll('style').forEach((e) => e.remove());
    var el = document.head!.querySelectorAll('style');
    for (var i = el.length - 1; i >= 0; i--) {
      (el.item(i) as HTMLElement).remove();
    }

    return disposeAnyRunningTest();
  });

  String failureReason(Element target) {
    // TODO: Migrate to dart 3.6 (Need to review)
    final lastStyles = document.head!.querySelectorAll('style');
    //final styleText = lastStyles.map((e) => e.text).join('\n');
    var list = [];
    for (var i = 0; i < lastStyles.length; i++) {
      var item = lastStyles.item(i) as HTMLElement;
      list.add(item);
    }
    final styleText = list.join('\n');

    var t = target as HTMLElement;
    return 'HTML:\n\n${t.outerHTML}\nCSS:\n\n$styleText';
  }

  test('should encapsulate usages of [class]=', () async {
    final testBed = NgTestBed<TestSetClassProperty>(
      ng.createTestSetClassPropertyFactory(),
    );
    final fixture = await testBed.create();
    final element = fixture.rootElement.querySelector('div')!;
    expect(
      window.getComputedStyle(element).position,
      'absolute',
      reason: failureReason(element),
    );
  });

  test('should encapsulate usages of [attr.class]=', () async {
    final testBed = NgTestBed<TestSetClassAttribute>(
      ng.createTestSetClassAttributeFactory(),
    );
    final fixture = await testBed.create();
    final element = fixture.rootElement.querySelector('div') as HTMLDivElement;
    expect(
      window.getComputedStyle(element).position,
      'absolute',
      reason: failureReason(element),
    );
  });

  test('should support encapsulation piercing ::ng-deep', () async {
    final testBed = NgTestBed<TestEncapsulationPierce>(
      ng.createTestEncapsulationPierceFactory(),
    );
    final fixture = await testBed.create();
    final element = fixture.rootElement.querySelector('button')!;
    expect(
      window.getComputedStyle(element).textTransform,
      isNot('uppercase'),
      reason: failureReason(element),
    );
  });
}

@Component(
  selector: 'test',
  template: r'''
    <div [class]="className">Hello World</div>
  ''',
  styles: [
    r'''
    .is-fancy {
      position: absolute;
    }
  ''',
  ],
)
class TestSetClassProperty {
  String get className => 'is-fancy';
}

@Component(
  selector: 'test',
  template: r'''
    <div [attr.class]="className">Hello World</div>
  ''',
  styles: [
    r'''
    .is-fancy {
      position: absolute;
    }
  ''',
  ],
)
class TestSetClassAttribute {
  String get className => 'is-fancy';
}

@Component(
  selector: 'test',
  template: r'''
    <child-with-text class="no-uppercase-test"></child-with-text>
  ''',
  directives: [ChildComponentWithUppercaseText],
  styles: [
    r'''
    .no-uppercase-test ::ng-deep .trigger-button {
      text-transform: inherit;
    }
  ''',
  ],
)
class TestEncapsulationPierce {}

@Component(
  selector: 'child-with-text',
  template: r'''
    <button class="trigger-button">Hello World</button>
  ''',
  styles: [
    r'''
    .trigger-button {
      text-transform: uppercase;
    }
  ''',
  ],
)
class ChildComponentWithUppercaseText {}
