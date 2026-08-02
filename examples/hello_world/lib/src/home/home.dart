import 'package:kelicap/kelicap.dart';

//@Component(selector: 'home-panel', template: '<h1>Welcome Home</h1>')
@Component(
  selector: 'home-panel',
  styleUrls: ['home.css'],
  templateUrl: 'home.html',
  directives: [NgIf],
  providers: [],
  encapsulation: ViewEncapsulation.emulated,
)
class HomeComponent {}
