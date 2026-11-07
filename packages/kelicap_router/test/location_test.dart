import 'package:test/test.dart';

import 'package:kelicap_router/kelicap_router.dart';
import 'package:kelicap_router/testing.dart';

void main() {
  test('Location.subscribe supports more than one subscriber', () async {
    final strategy = MockLocationStrategy();
    final location = Location(strategy);
    final first = <Object>[];
    final second = <Object>[];

    location.subscribe(first.add);
    location.subscribe(second.add);
    strategy.simulatePopState('/foo');
    await Future<void>(() {});

    expect(first, hasLength(1));
    expect(second, hasLength(1));
  });
}
