/// The primary library for the [Kelicap web framework][Kelicap].
///
/// Import this library as follows:
///
/// ```
/// import 'package:kelicap/kelicap.dart';
/// ```
///
/// For help using this library, see the Kelicap documentation:
///
/// * [Kelicap guide][]
/// * [Kelicap cheat sheet][cheatsheet]
///
/// [Kelicap]: https://webdev.dartlang.org/kelicap
/// [Kelicap guide]: https://webdev.dartlang.org/kelicap/guide
/// [cheatsheet]: https://webdev.dartlang.org/kelicap/cheatsheet

library;

export 'src/bootstrap/run.dart' show runApp, runAppAsync;
export 'src/common/directives.dart';
export 'src/common/pipes.dart';
export 'src/core/application_ref.dart' show ApplicationRef;
export 'src/core/application_tokens.dart' show appId;
export 'src/core/change_detection.dart';
export 'src/core/exception_handler.dart' show ExceptionHandler;
export 'src/core/linker.dart';
export 'src/core/zone/ng_zone.dart' show NgZone, UncaughtError;
export 'src/devtools.dart' show enableDevTools, registerContentRoot;
export 'src/di/errors.dart' show InjectionError, NoProviderError;
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
export 'src/meta/visible_for_template.dart';

// export 'src/meta.dart'
//     show
//         AfterChanges,
//         AfterContentChecked,
//         AfterContentInit,
//         AfterViewChecked,
//         AfterViewInit,
//         Attribute,
//         ChangeDetectionStrategy,
//         ChangeDetectorState,
//         ClassProvider,
//         Component,
//         ContentChild,
//         ContentChildren,
//         Directive,
//         DoCheck,
//         ExistingProvider,
//         FactoryProvider,
//         GenerateInjector,
//         Host,
//         HostBinding,
//         HostListener,
//         Inject,
//         Injectable,
//         Input,
//         Module,
//         MultiToken,
//         OnDestroy,
//         OnInit,
//         OpaqueToken,
//         Optional,
//         Output,
//         Pipe,
//         Provider,
//         Self,
//         SkipSelf,
//         Typed,
//         ValueProvider,
//         ViewChild,
//         ViewChildren,
//         ViewEncapsulation,
//         Visibility,
//         noValueProvided,
//         provide,
//         visibleForTemplate;
export 'src/runtime/check_binding.dart' show debugCheckBindings;
// TODO(b/116697059): Move to a testonly=1 library.
export 'src/testability.dart'
    show testabilityProvider, Testability, TestabilityRegistry;
