import 'package:kelicap/kelicap.dart';
import 'package:kelicap_router/kelicap_router.dart';
//import 'package:kelicap_forms/kelicap_forms.dart';
import 'package:http/browser_client.dart';
import 'package:http/http.dart';

import 'package:hello_world/app.template.dart' as app;

import 'main.template.dart' as ng;

const useHashLS = false;

@GenerateInjector([
  routerProvidersHash, // For development
  // routerProviders, // For Production
  ClassProvider(Client, useClass: BrowserClient),
  testabilityProvider,
])
final InjectorFactory injector = ng.injector$Injector;

void main() {
  runApp(app.MyAppComponentNgFactory, createInjector: injector);
}
