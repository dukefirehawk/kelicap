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
