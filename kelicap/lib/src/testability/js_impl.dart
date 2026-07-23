part of 'testability.dart';

@JS('ngTestabilityRegistries')
external JSArray<JsTestabilityRegistry>? _ngJsTestabilityRegistries;

@JS('getKelicapTestability')
//external set _jsGetKelicapTestability(
//    Object? Function(Element element) function);
external set _jsGetKelicapTestability(JSFunction function);

@JS('getAllKelicapTestabilities')
//external set _jsGetAllKelicapTestabilities(List<Object> Function() function);
external set _jsGetAllKelicapTestabilities(JSFunction function);

@JS('frameworkStabilizers')
//xternal List<Object?>? _jsFrameworkStabilizers;
external JSArray<JSFunction>? _jsFrameworkStabilizers;

class _JSTestabilityProxy implements _TestabilityProxy {
  const _JSTestabilityProxy();

  @override
  void addToWindow(TestabilityRegistry registry) {
    var registries = _ngJsTestabilityRegistries;
    if (registries == null) {
      //registries = <JsTestabilityRegistry>[];
      registries = JSArray();
      _ngJsTestabilityRegistries = registries;
      /*
      _jsGetKelicapTestability = allowInterop(_getKelicapTestability);
      _jsGetAllKelicapTestabilities = allowInterop(_getAllKelicapTestabilities);
      (_jsFrameworkStabilizers ??= <Object?>[])
          .add(allowInterop(_whenAllStable));
      */
      _jsGetKelicapTestability = _getKelicapTestability.toJS;
      _jsGetAllKelicapTestabilities = _getAllKelicapTestabilities.toJS;
      //(_jsFrameworkStabilizers ??= <Object?>[]).add(_whenAllStable);
      (_jsFrameworkStabilizers ??= JSArray()).add(
        ((JSFunction callback) => _whenAllStable(callback)).toJS,
      );
    }
    registries.add(registry.asJsApi());
  }

  /// For every registered [TestabilityRegistry], tries `getKelicapTestability`.
  static JsTestability? _getKelicapTestability(Element element) {
    final registry = _ngJsTestabilityRegistries;
    if (registry == null) {
      return null;
    }
    for (var i = 0; i < registry.length; i++) {
      final result = registry[i].getKelicapTestability(element);
      if (result != null) {
        return result;
      }
    }
    return null;
  }

  /// For every registered [TestabilityRegistry], returns the JS API for it.
  //static List<JsTestability> _getAllKelicapTestabilities() {
  static JSArray<JsTestability> _getAllKelicapTestabilities() {
    final registry = _ngJsTestabilityRegistries;
    if (registry == null) {
      //return <JsTestability>[];
      return JSArray();
    }
    final result = <JsTestability>[];
    //final result = JSArray();
    for (var i = 0; i < registry.length; i++) {
      final testabilities = registry[i].getAllKelicapTestabilities();
      result.addAll(testabilities.toDart);
    }
    return result.toJS;
  }

  /// For every testability, calls [callback] when they _all_ report stable.
  static void _whenAllStable(JSFunction callback) {
    final testabilities = _getAllKelicapTestabilities();

    var pendingStable = testabilities.length;

    void decrement() {
      pendingStable--;
      if (pendingStable == 0) {
        callback.callAsFunction();
      }
    }

    for (var i = 0; i < testabilities.length; i++) {
      //testabilities[i].whenStable(allowInterop(decrement));
      testabilities[i].whenStable(decrement.toJS);
    }
  }
}

extension on Testability {
  JsTestability asJsApi() {
    return JsTestability(
      //isStable: allowInterop(() => isStable),
      //whenStable: allowInterop(whenStable),
      isStable: (() => isStable).toJS,
      //whenStable: whenStable,
      whenStable:
          ((JSFunction callback) =>
                  //whenStable(callback as void Function())).toJS,
                  whenStable(callback))
              .toJS,
    );
  }
}

extension on TestabilityRegistry {
  JsTestabilityRegistry asJsApi() {
    JsTestability? getKelicapTestability(Element element) {
      final dartTestability = testabilityFor(element);
      return dartTestability?.asJsApi();
    }

    //List<JsTestability> getAllKelicapTestabilities() {
    JSArray<JsTestability> getAllKelicapTestabilities() {
      return allTestabilities
          .map((testability) => testability.asJsApi())
          .toList()
          .toJS;
    }

    return JsTestabilityRegistry(
      //getKelicapTestability: allowInterop(getKelicapTestability),
      //getAllKelicapTestabilities: allowInterop(getAllKelicapTestabilities),
      getKelicapTestability: getKelicapTestability.toJS,
      getAllKelicapTestabilities: getAllKelicapTestabilities.toJS,
    );
  }
}
