import 'dart:async';

import 'package:test/test.dart';
import 'package:kelicap/kelicap.dart';
import 'package:kelicap_test/kelicap_test.dart';
import 'package:kelicap_test/src/errors/will_never_stabilize.dart';

import 'stabilizer_test.template.dart' as template;

void main() {
  test('should throw error when stabilization threshold is exceeded', () async {
    final testBed = NgTestBed<WillNeverStabilizeComponent>(
      template.createWillNeverStabilizeComponentFactory(),
    );
    expect(testBed.create, throwsA(TypeMatcher<WillNeverStabilizeError>()));
  }, skip: 'b/140626607');
}

@Component(selector: 'test', template: '')
class WillNeverStabilizeComponent implements DoCheck {
  @override
  void ngDoCheck() {
    // This creates an infinite change detection loop.
    scheduleMicrotask(() {});
  }
}
