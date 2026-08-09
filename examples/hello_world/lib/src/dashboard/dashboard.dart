import 'package:hello_world/src/todo/todo.dart';
import 'package:kelicap/kelicap.dart';

@Component(
  selector: 'dashboard-panel',
  styleUrls: ['dashboard.css'],
  templateUrl: 'dashboard.html',
  directives: [coreDirectives, TodoComponent],
  providers: [],
  encapsulation: ViewEncapsulation.emulated,
)
class DashboardComponent {}
