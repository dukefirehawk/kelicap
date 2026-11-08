@TestOn('browser')
library;

import 'package:test/test.dart';
import 'package:kelicap/kelicap.dart';
import 'package:kelicap_test/kelicap_test.dart';

import 'null_literal_input_test.template.dart' as ng;

void main() {
  tearDown(disposeAnyRunningTest);

  test('an input bound to null is set once, with null', () async {
    final fixture = await NgTestBed<NullLiteralInputTest>(
      ng.createNullLiteralInputTestFactory(),
    ).create();
    await fixture.update();
    expect(fixture.assertOnlyInstance.recorder!.values, [null]);
  });

  test('an input bound to null calls ngAfterChanges once', () async {
    final fixture = await NgTestBed<NullLiteralAfterChangesTest>(
      ng.createNullLiteralAfterChangesTestFactory(),
    ).create();
    final directive = fixture.assertOnlyInstance.directive!;
    expect(directive.afterChanges, 1);
    await fixture.update();
    expect(directive.afterChanges, 1, reason: 'null does not change again');
  });

  test('an element property bound to null sets nothing', () async {
    final fixture = await NgTestBed<NullLiteralInputTest>(
      ng.createNullLiteralInputTestFactory(),
    ).create();
    final span = fixture.rootElement.querySelector('span')!;
    expect(span.hasAttribute('title'), isFalse);
  });
}

@Directive(selector: '[recorder]')
class RecorderDirective {
  final values = <Object?>[];

  @Input()
  set value(Object? value) {
    values.add(value);
  }
}

@Component(
  selector: 'null-literal-input-test',
  directives: [RecorderDirective],
  template: '<div recorder [value]="null"></div><span [title]="null"></span>',
)
class NullLiteralInputTest {
  @ViewChild(RecorderDirective)
  RecorderDirective? recorder;
}

@Directive(selector: '[after-changes]')
class AfterChangesDirective implements AfterChanges {
  var afterChanges = 0;

  @Input()
  Object? value;

  @override
  void ngAfterChanges() {
    afterChanges++;
  }
}

@Component(
  selector: 'null-literal-after-changes-test',
  directives: [AfterChangesDirective],
  template: '<div after-changes [value]="null"></div>',
)
class NullLiteralAfterChangesTest {
  @ViewChild(AfterChangesDirective)
  AfterChangesDirective? directive;
}
