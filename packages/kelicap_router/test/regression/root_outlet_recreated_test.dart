import 'package:test/test.dart';
import 'package:kelicap/kelicap.dart';

import 'package:kelicap_router/kelicap_router.dart';
import 'package:kelicap_router/testing.dart';

import 'package:kelicap_test/kelicap_test.dart';

import 'root_outlet_recreated_test.template.dart' as ng;

void main() {
  tearDown(disposeAnyRunningTest);

  test('a recreated root outlet navigates without the destroyed components '
      'of the previous one', () async {
    _lifecycleCalls.clear();
    final fixture = await NgTestBed<AppComponent>(
      ng.createAppComponentFactory(),
    ).addInjector(fakeRoot).create();
    expect(fixture.text, contains('Guarded page'));

    await fixture.update((component) => component.showOutlet = false);
    expect(fixture.text, isNot(contains('Guarded page')));

    await fixture.update((component) => component.showOutlet = true);
    expect(fixture.text, contains('Guarded page'));
    expect(_lifecycleCalls, isEmpty);
  });
}

@GenerateInjector([routerProvidersTest])
final fakeRoot = ng.fakeRoot$Injector;

/// The router's calls to [GuardedComponent], which should not get any here.
final _lifecycleCalls = <String>[];

@Component(
  selector: 'app',
  directives: [NgIf, RouterOutlet],
  template:
      '<router-outlet *ngIf="showOutlet" [routes]="routes"></router-outlet>',
)
class AppComponent {
  bool showOutlet = true;

  final List<RouteDefinition> routes = [
    RouteDefinition(
      path: 'guarded',
      useAsDefault: true,
      component: ng.createGuardedComponentFactory(),
    ),
  ];
}

@Component(selector: 'guarded', template: 'Guarded page')
class GuardedComponent implements CanNavigate, CanDeactivate, OnDeactivate {
  @override
  Future<bool> canNavigate() async {
    _lifecycleCalls.add('canNavigate');
    return true;
  }

  @override
  Future<bool> canDeactivate(RouterState current, RouterState next) async {
    _lifecycleCalls.add('canDeactivate');
    return true;
  }

  @override
  void onDeactivate(RouterState current, RouterState next) {
    _lifecycleCalls.add('onDeactivate');
  }
}
