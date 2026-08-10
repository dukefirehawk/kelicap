import 'dart:async';

import 'package:test/test.dart';
import 'package:kelicap/kelicap.dart';
import 'package:kelicap_test/kelicap_test.dart';

import 'mock_like_directive_test.template.dart' as ng;

void main() {
  tearDown(disposeAnyRunningTest);

  test('should support null @Output if mock-like', () async {
    final testBed = NgTestBed(ng.createTestMockNotificationComponentFactory());
    await testBed.create();
  });

  test("shouldn't support null @Output if not mock-like", () async {
    final testBed = NgTestBed(ng.createTestFakeNotificationComponentFactory());
    expect(testBed.create(), throwsA(const TypeMatcher<NoSuchMethodError>()));
  });
}

@Component(selector: 'notifier', template: '')
class NotifierComponent {
  final StreamController<String> _notificationsController =
      StreamController<String>();

  @Output()
  Stream<String> get notifications => _notificationsController.stream;
}

@Component(selector: 'notifier', template: '')
class MockNotifierComponent implements NotifierComponent {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

@Component(
  selector: 'test-mock-notifier',
  template: '''
    <notifier (notifications)="notify(\$event)">
    </notifier>''',
  directives: [MockNotifierComponent],
)
class TestMockNotificationComponent {
  void notify(String notification) {}
}

@Component(selector: 'notifier', template: '')
class FakeNotifierComponent extends NotifierComponent {
  // Deliberately returns null despite the non-nullable return type: the test
  // asserts that a null @Output on a non-mock-like directive throws.
  @override
  Stream<String> get notifications => null as dynamic;
}

@Component(
  selector: 'test-fake-notifier',
  template: '''
    <notifier (notifications)="notify(\$event)">
    </notifier>''',
  directives: [FakeNotifierComponent],
)
class TestFakeNotificationComponent {
  void notify(String notification) {}
}
