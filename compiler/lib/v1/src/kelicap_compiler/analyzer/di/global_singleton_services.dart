import '../link.dart';

const _globalSingletonServices = [
  TypeLink('ApplicationRef', 'asset:kelicap/lib/src/core/application_ref.dart'),
  TypeLink(
    'AppViewUtils',
    'asset:kelicap/lib/src/core/linker/app_view_utils.dart',
  ),
  TypeLink('NgZone', 'asset:kelicap/lib/src/core/zone/ng_zone.dart'),
  TypeLink(
    'Testability',
    'asset:kelicap/lib/src/testability/implementation.dart',
  ),
];

bool isGlobalSingletonService(TypeLink service) =>
    _globalSingletonServices.contains(service);
