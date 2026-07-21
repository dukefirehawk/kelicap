/// NOTE: As of 2020-08-12, this library is DEPRECATED.
///
/// The actual deprecation notice is on the user-visible import located in
/// //third_party/dart/angular/lib/di.dart, which exports this file.
///
/// See go/angular-di.dart-deprecated.
library;

export 'src/di/injector.dart' show Injector, InjectorFactory;
export 'src/meta/change_detection_constants.dart';
export 'src/meta/change_detection_link.dart';
export 'src/meta/di_arguments.dart';
export 'src/meta/di_generate_injector.dart';
export 'src/meta/di_modules.dart';
export 'src/meta/di_providers.dart';
export 'src/meta/di_tokens.dart';
export 'src/meta/directives.dart';
export 'src/meta/lifecycle_hooks.dart';
export 'src/meta/typed.dart';
export 'src/meta/view.dart';
export 'src/meta/visibility.dart';

// export 'src/meta.dart'
//     show
//         ClassProvider,
//         Component,
//         Directive,
//         ExistingProvider,
//         FactoryProvider,
//         GenerateInjector,
//         Host,
//         Input,
//         Inject,
//         Injectable,
//         Module,
//         MultiToken,
//         OpaqueToken,
//         Optional,
//         Output,
//         Pipe,
//         Provider,
//         Self,
//         SkipSelf,
//         ValueProvider,
//         provide,
//         noValueProvided;
