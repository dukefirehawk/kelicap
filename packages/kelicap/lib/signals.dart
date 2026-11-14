/// Signals: values that notify the code that reads them when they change.
///
/// Setting a [WritableSignal] runs change detection, so a component can keep
/// its state in signals, and read them in its template:
///
/// ```dart
/// import 'package:kelicap/kelicap.dart';
/// import 'package:kelicap/signals.dart';
///
/// @Component(
///   selector: 'counter',
///   template: '<button (click)="increment()">{{count()}}</button>',
/// )
/// class CounterComponent {
///   final count = signal(0);
///
///   void increment() => count.update((value) => value + 1);
/// }
/// ```
library;

export 'src/signals/signals.dart'
    show
        EffectCleanupRegisterFn,
        EffectRef,
        Signal,
        ValueEqualityFn,
        WritableSignal,
        batch,
        computed,
        effect,
        signal,
        untracked;
