import 'package:kelicap/kelicap.dart';
import 'package:kelicap_forms/kelicap_forms.dart';

@Component(
  selector: 'user-form',
  templateUrl: 'user.html',
  styleUrls: ['user.css'],
  directives: [coreDirectives, formDirectives],
)
class UserFormComponent {
  String userName = 'Guest';

  void resetName() {
    userName = 'Guest';
  }
}
