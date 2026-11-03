# Router for Kelicap

[![Kelicap Web Framework](../../assets/branding/kelicap_1_banner.jpeg)](https://github.com/dukefirehawk/kelicap)

![Pub Version (including pre-releases)](https://img.shields.io/pub/v/kelicap_router?include_prereleases)
[![Null Safety](https://img.shields.io/badge/null-safety-brightgreen)](https://dart.dev/null-safety)
[![License](https://img.shields.io/github/license/dukefirehawk/kelicap)](https://github.com/dukefirehawk/kelicap/blob/main/LICENSE)

Routing for Kelicap single-page applications. It maps URLs to components, and shows the component of the current URL in a `<router-outlet>`. It supports route parameters, redirects, nested routes, lazy loading and navigation hooks, with URLs as paths (`/heroes/1`) or as hashes (`/#/heroes/1`).

## Installation

```yaml
dependencies:
  kelicap: ^1.1.2
  kelicap_router: ^1.1.2
```

## Usage

Define the paths and the routes that show a component for each:

```dart
import 'package:kelicap_router/kelicap_router.dart';

import 'home.template.dart' as home;
import 'hero.template.dart' as hero;

class Paths {
  static final home = RoutePath(path: 'home');
  static final hero = RoutePath(path: 'heroes/:id');
}

final appRoutes = [
  RouteDefinition.redirect(path: '', redirectTo: Paths.home.toUrl()),
  RouteDefinition(routePath: Paths.home, component: home.HomeComponentNgFactory),
  RouteDefinition(routePath: Paths.hero, component: hero.HeroComponentNgFactory),
];
```

Show them in your app component, with links between them:

```dart
@Component(
  selector: 'my-app',
  directives: [routerDirectives],
  exports: [Paths],
  template: '''
    <nav>
      <a [routerLink]="Paths.home.toUrl()" routerLinkActive="active">Home</a>
    </nav>
    <router-outlet [routes]="routes"></router-outlet>
  ''',
)
class AppComponent {
  final routes = appRoutes;
}
```

And provide the router in the app's injector, in `web/main.dart`:

```dart
@GenerateInjector([routerProviders])
final InjectorFactory injector = ng.injector$Injector;

void main() {
  runApp(app.AppComponentNgFactory, createInjector: injector);
}
```

`routerProviders` uses paths, which needs the server to answer every route's URL with `index.html`. `routerProvidersHash` uses hashes, which work with any static server, such as `build_runner serve` during development.

A routed component reads its parameters, such as `id`, by implementing `OnActivate`:

```dart
class HeroComponent implements OnActivate {
  @override
  void onActivate(RouterState? previous, RouterState current) {
    var id = current.parameters['id'];
  }
}
```

To navigate from code, inject `Router` and call `router.navigate(Paths.hero.toUrl(parameters: {'id': '1'}))`.
