import 'package:kelicap/kelicap.dart';
import 'package:kelicap_router/kelicap_router.dart';

import 'login/login.template.dart' as login_template;
import 'dashboard/dashboard.template.dart' as dashboard_template;
import 'home/home.template.dart' as home_template;
import 'error/not_found.template.dart' as not_found_template;
import 'user/user.template.dart' as user_template;

import 'app_route_paths.dart' as paths;

@Injectable()
class AppRoute {
  RoutePath get login => paths.AppRoutePaths.login;
  RoutePath get dashboard => paths.AppRoutePaths.dashboard;
  RoutePath get home => paths.AppRoutePaths.home;
  RoutePath get others => paths.AppRoutePaths.others;

  final all = <RouteDefinition>[
    RouteDefinition.redirect(
      path: '',
      redirectTo: paths.AppRoutePaths.login.toUrl(),
    ),
    RouteDefinition(
      routePath: paths.AppRoutePaths.login,
      component: login_template.LoginComponentNgFactory,
    ),
    RouteDefinition(
      routePath: paths.AppRoutePaths.dashboard,
      component: dashboard_template.DashboardComponentNgFactory,
    ),
    RouteDefinition(
      routePath: paths.AppRoutePaths.home,
      component: home_template.HomeComponentNgFactory,
    ),
    RouteDefinition(
      routePath: paths.AppRoutePaths.user,
      component: user_template.UserFormComponentNgFactory,
    ),
    RouteDefinition(
      routePath: paths.AppRoutePaths.others,
      component: not_found_template.NotFoundComponentNgFactory,
    ),
  ];
}
