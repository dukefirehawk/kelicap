import 'package:test/test.dart';
import 'package:kelicap/kelicap.dart';

import '../../lib/kelicap_router.dart';
import '../../lib/testing.dart';

import '../../../kelicap_test/lib/kelicap_test.dart';

// ignore: uri_has_not_been_generated
import '../../../../router/test/regression/empty_path_test.template.dart' as ng;

void main() {
  tearDown(disposeAnyRunningTest);

  test('navigation to empty path should fail', () async {
    final testBed = NgTestBed<TestComponent>(ng.createTestComponentFactory());
    final testFixture = await testBed.create();
    final router = testFixture.assertOnlyInstance.router;
    final result = await router?.navigate('/');
    expect(result, NavigationResult.invalidRoute);
  });
}

@Component(selector: 'test', template: '', providers: routerProvidersTest)
class TestComponent {
  final Router? router;

  TestComponent(@Optional() this.router);
}
