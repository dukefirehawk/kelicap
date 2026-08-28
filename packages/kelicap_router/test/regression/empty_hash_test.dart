import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'package:kelicap_router/kelicap_router.dart';

class MockPlatformLocation extends Mock implements PlatformLocation {
  @override
  String get pathname => super.noSuchMethod(
    Invocation.getter(#pathname),
    returnValue: '',
    returnValueForMissingStub: '',
  ) as String;

  @override
  String get search => super.noSuchMethod(
    Invocation.getter(#search),
    returnValue: '',
    returnValueForMissingStub: '',
  ) as String;

  @override
  String get hash => super.noSuchMethod(
    Invocation.getter(#hash),
    returnValue: '',
    returnValueForMissingStub: '',
  ) as String;
}

void main() {
  late LocationStrategy locationStrategy;
  late MockPlatformLocation platformLocation;

  group("empty URL doesn't overwrite query parameters", () {
    setUp(() {
      platformLocation = MockPlatformLocation();
      locationStrategy = HashLocationStrategy(platformLocation, null);
      when(platformLocation.pathname).thenReturn('/foo');
      when(platformLocation.search).thenReturn('?bar=baz');
    });

    test('on push', () {
      locationStrategy.pushState(null, '', '', '');
      verify(platformLocation.pushState(null, '', '/foo?bar=baz'));
    });

    test('on replace', () {
      locationStrategy.replaceState(null, '', '', '');
      verify(platformLocation.replaceState(null, '', '/foo?bar=baz'));
    });
  });
}
