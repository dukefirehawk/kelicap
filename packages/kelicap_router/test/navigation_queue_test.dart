import 'dart:async';

import 'package:test/test.dart';
import 'package:kelicap/kelicap.dart';

import 'package:kelicap_router/kelicap_router.dart';
import 'package:kelicap_router/testing.dart';

import 'package:kelicap_test/kelicap_test.dart';

// ignore: uri_has_not_been_generated
import '../../../router/test/navigation_queue_test.template.dart' as ng;

const firstToken = OpaqueToken<Future<void>>('first');
const secondToken = OpaqueToken<Future<void>>('second');
const thirdToken = OpaqueToken<Future<void>>('third');

void main() {
  tearDown(disposeAnyRunningTest);

  test('navigation should complete in requested order', () async {
    // These are used to delay route activation guards.
    final firstCompleter = Completer<void>();
    final secondCompleter = Completer<void>();
    final thirdCompleter = Completer<void>();

    final testBed = NgTestBed<TestComponent>(ng.createTestComponentFactory())
        .addInjector(
          (i) => Injector.map({
            firstToken: firstCompleter.future,
            secondToken: secondCompleter.future,
            thirdToken: thirdCompleter.future,
          }, i),
        );

    final testFixture = await testBed.create();
    final router = testFixture.assertOnlyInstance.router;
    final requests = router.onRouteActivated.map((state) => state.path);

    unawaited(router.navigate('/first'));
    unawaited(router.navigate('/second'));
    unawaited(router.navigate('/third'));
    // Expect navigation to complete in order requested.
    expect(requests, emitsInOrder(['/first', '/second', '/third']));

    // Allow activation in reverse order. It's necessary to complete these
    // activations in multiple events loops, to ensure the activation guards
    // are checked incrementally as each activation is allowed. If all
    // activations are permitted in the same event loop, the pending awaited
    // activation guards will execute in the original order.
    thirdCompleter.complete();
    unawaited(Future(secondCompleter.complete));
    unawaited(Future(firstCompleter.complete));
  });
}

@Component(
  selector: 'test',
  template: '<router-outlet [routes]="routes"></router-outlet>',
  directives: [RouterOutlet],
  providers: [routerProvidersTest],
)
class TestComponent {
  final Router router;
  final List<RouteDefinition> routes = [
    RouteDefinition(
      path: '/first',
      component: ng.createFirstComponentFactory(),
    ),
    RouteDefinition(
      path: '/second',
      component: ng.createSecondComponentFactory(),
    ),
    RouteDefinition(
      path: '/third',
      component: ng.createThirdComponentFactory(),
    ),
    RouteDefinition(
      path: '/',
      component: ng.createDefaultComponentFactory(),
      useAsDefault: true,
    ),
  ];

  TestComponent(this.router);
}

@Component(selector: 'default', template: 'Default')
class DefaultComponent {}

abstract class DelayedActivation implements CanActivate {
  final Future<void>? _future;

  DelayedActivation(this._future);

  @override
  Future<bool> canActivate(_, _) =>
      _future?.then((_) => true) ?? Future.value(true);
}

@Component(selector: 'first', template: 'First')
class FirstComponent extends DelayedActivation {
  FirstComponent(@Optional() @firstToken super.future);
}

@Component(selector: 'second', template: 'Second')
class SecondComponent extends DelayedActivation {
  SecondComponent(@Optional() @secondToken super.future);
}

@Component(selector: 'third', template: 'Third')
class ThirdComponent extends DelayedActivation {
  ThirdComponent(@Optional() @thirdToken super.future);
}
