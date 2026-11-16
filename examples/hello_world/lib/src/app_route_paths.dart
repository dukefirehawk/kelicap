import 'package:kelicap_router/kelicap_router.dart';

class AppRoutePaths {
  static final login = RoutePath(path: 'login');
  static final dashboard = RoutePath(path: 'dashboard');
  static final home = RoutePath(path: 'home');
  static final user = RoutePath(path: 'user');
  // A path is a regular expression: '.+' matches every path that the routes
  // before it do not, but not the empty one, which redirects to login.
  static final others = RoutePath(path: '.+');
}
