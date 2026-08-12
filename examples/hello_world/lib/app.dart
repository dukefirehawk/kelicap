import 'package:kelicap/kelicap.dart';
//import 'package:kelicap_router/kelicap_router.dart';
//import 'package:kelicap_forms/kelicap_forms.dart';
import 'package:hello_world/src/dashboard/dashboard.dart';
import 'package:hello_world/src/login/login.dart';
import 'package:hello_world/src/todo/todo.dart';
import 'package:hello_world/src/app_route.dart';
import 'package:hello_world/src/user/user.dart';

import 'package:kelicap_router/kelicap_router.dart';

import 'src/home/home.dart';

@Component(
  selector: 'my-app',
  styleUrls: ['app.css'],
  //template: '<h1>Welcome Home</h1>',
  templateUrl: 'app.html',
  directives: [
    HomeComponent,
    LoginComponent,
    DashboardComponent,
    TodoComponent,
    UserFormComponent,
    routerDirectives,
  ],
  providers: [ClassProvider(AppRoute)],
  exports: [AppRoute],
)
class MyAppComponent {
  final AppRoute routes;

  MyAppComponent(this.routes);
}
