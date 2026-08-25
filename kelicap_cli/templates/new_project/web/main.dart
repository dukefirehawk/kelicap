import 'package:kelicap/kelicap.dart';
import 'package:kelicap_components/kelicap_components.dart';
import 'package:__projectName__/app_component.template.dart' as ng;

import 'main.template.dart' as self;

// Example of a [root injector]
// [popupModule] is used in [MaterialTooltipDirective]
@GenerateInjector([popupModule])
final InjectorFactory rootInjector = self.rootInjector$Injector;

void main() {
  runApp(ng.AppComponentNgFactory, createInjector: rootInjector);
}
