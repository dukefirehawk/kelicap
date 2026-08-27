import 'package:web/web.dart';

import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:kelicap/kelicap.dart';

import 'package:kelicap_router/kelicap_router.dart';

import 'package:kelicap_test/kelicap_test.dart';

import '../../../../router/test/regression/hash_location_strategy_test.template.dart'
    as ng;

final platformLocation = MockPlatformLocation();

void main() {
  setUp(() {
    reset(platformLocation);
  });

  tearDown(disposeAnyRunningTest);

  test('browser location should match clicked href', () async {
    final testBed = NgTestBed<AppComponent>(
      ng.createAppComponentFactory(),
      rootInjector: injectorFactory,
    );
    final testFixture = await testBed.create();
    expect(
      testFixture.assertOnlyInstance.anchor?.getAttribute('href'),
      '#/foo',
    );
    await testFixture.update((c) {
      c.anchor?.click();
    });
    verify(platformLocation.pushState(any, '', '#/foo')).called(1);
  });
}

PlatformLocation platformLocationFactory() => platformLocation;

class MockPlatformLocation extends Mock implements BrowserPlatformLocation {
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

@GenerateInjector([
  routerProvidersHash,
  FactoryProvider(PlatformLocation, platformLocationFactory),
])
InjectorFactory injectorFactory = ng.injectorFactory$Injector;

@Component(
  selector: 'app',
  template: '''
    <a #routerLink [routerLink]="fooRoute.toUrl()"></a>
    <router-outlet [routes]="routes"></router-outlet>
  ''',
  directives: [RouterLink, RouterOutlet],
)
class AppComponent {
  final RouteDefinition fooRoute = RouteDefinition(
    path: '/foo',
    component: ng.createFooComponentFactory(),
  );
  late final List<RouteDefinition> routes = [fooRoute];

  @ViewChild('routerLink')
  HTMLElement? anchor;
}

@Component(selector: 'foo', template: '')
class FooComponent {}
