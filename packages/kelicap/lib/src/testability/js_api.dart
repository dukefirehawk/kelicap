@JS()
library;

import 'dart:js_interop';

import 'package:web/web.dart';

/// A JavaScript interface for interacting with Kelicap's `Testability` API.
///
/// This interfaces with a running Kelicap application.
//@JS()
//@anonymous
extension type JsTestability._(JSObject _) implements JSObject {
  external factory JsTestability({
    //required bool Function() isStable,
    //required void Function(void Function()) whenStable,
    required JSFunction isStable,
    required JSFunction whenStable,
  });

  /// Returns whether the application is considered stable.
  ///
  /// Stability is determined when the DOM is unlikely to change due to the
  /// framework. By default, this is determined by no known asynchronous tasks
  /// (microtasks, or timers) being present but not yet executed within the
  /// framework context.
  external bool isStable();

  /// Invokes the provided [callback] when the application [isStable].
  ///
  /// If the application was already stable at the time of this function being
  /// invoked, [callback] is invoked with a value of `false` for `didWork`,
  /// indicating that no asynchronous work was awaited before execution.
  /// Otherwise a value of `true` is passed.
  //external void whenStable(void Function() callback);
  external void whenStable(JSFunction callback);
}

/// A JavaScript interface for interacting with Kelicap's `TestabilityRegistry` API.
///
/// A global registry of `Testability` instances given an app root element.
//@JS()
//@anonymous
//abstract class JsTestabilityRegistry {
extension type JsTestabilityRegistry._(JSObject _) implements JSObject {
  external factory JsTestabilityRegistry({
    //required JsTestability? Function(Element) getKelicapTestability,
    //required List<JsTestability> Function() getAllKelicapTestabilities,
    required JSFunction getKelicapTestability,
    required JSFunction getAllKelicapTestabilities,
  });

  /// Returns the registered testability instance for [appRoot], or `null`.
  external JsTestability? getKelicapTestability(Element appRoot);

  /// Returns all testability instances registered.
  //external List<JsTestability> getAllKelicapTestabilities();
  external JSArray<JsTestability> getAllKelicapTestabilities();
}
