@TestOn('browser')
library;

import 'package:test/test.dart';
import 'package:kelicap/kelicap.dart';
import 'package:kelicap_test/kelicap_test.dart';

import 'component_constructor_test.template.dart' as ng;

void main() {
  tearDown(disposeAnyRunningTest);

  test('creates a component with its unnamed constructor', () async {
    final fixture = await NgTestBed<NamedFirstComponent>(
      ng.createNamedFirstComponentFactory(),
    ).create();
    expect(fixture.assertOnlyInstance.zone, isNotNull);
  });
}

@Component(selector: 'named-first', template: '')
class NamedFirstComponent {
  final NgZone? zone;

  /// Declared first, and takes a dependency that nothing provides.
  NamedFirstComponent.named(String unprovided) : zone = null;

  NamedFirstComponent(NgZone this.zone);
}
