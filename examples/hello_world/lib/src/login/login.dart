import 'package:kelicap/kelicap.dart';

@Component(
  selector: 'login-page',
  styleUrls: ['login.css'],
  templateUrl: 'login.html',
  directives: [coreDirectives],
  providers: [],
  encapsulation: ViewEncapsulation.emulated,
)
class LoginComponent {
  bool isLoggedIn = true;
  String username = 'Developer';

  void toggleLogin() {
    isLoggedIn = !isLoggedIn;
  }
}
