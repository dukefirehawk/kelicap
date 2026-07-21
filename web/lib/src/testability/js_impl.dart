part of 'testability.dart';

@JS('ngTestabilityRegistries')
external JSArray<JsTestabilityRegistry>? _ngJsTestabilityRegistries;

@JS('getAngularTestability')
//external set _jsGetAngularTestability(
//    Object? Function(Element element) function);
external set _jsGetAngularTestability(JSFunction function);

@JS('getAllAngularTestabilities')
//external set _jsGetAllAngularTestabilities(List<Object> Function() function);
external set _jsGetAllAngularTestabilities(JSFunction function);

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
      _jsGetAngularTestability = allowInterop(_getAngularTestability);
      _jsGetAllAngularTestabilities = allowInterop(_getAllAngularTestabilities);
      (_jsFrameworkStabilizers ??= <Object?>[])
          .add(allowInterop(_whenAllStable));
      */
      _jsGetAngularTestability = _getAngularTestability.toJS;
      _jsGetAllAngularTestabilities = _getAllAngularTestabilities.toJS;
      //(_jsFrameworkStabilizers ??= <Object?>[]).add(_whenAllStable);
      (_jsFrameworkStabilizers ??= JSArray())
          .add(((JSFunction callback) => _whenAllStable(callback)).toJS);
    }
    registries.add(registry.asJsApi());
  }

  /// For every registered [TestabilityRegistry], tries `getAngularTestability`.
  static JsTestability? _getAngularTestability(Element element) {
    final registry = _ngJsTestabilityRegistries;
    if (registry == null) {
      return null;
    }
    for (var i = 0; i < registry.length; i++) {
      final result = registry[i].getAngularTestability(element);
      if (result != null) {
        return result;
      }
    }
    return null;
  }

  /// For every registered [TestabilityRegistry], returns the JS API for it.
  //static List<JsTestability> _getAllAngularTestabilities() {
  static JSArray<JsTestability> _getAllAngularTestabilities() {
    final registry = _ngJsTestabilityRegistries;
    if (registry == null) {
      //return <JsTestability>[];
      return JSArray();
    }
    final result = <JsTestability>[];
    //final result = JSArray();
    for (var i = 0; i < registry.length; i++) {
      final testabilities = registry[i].getAllAngularTestabilities();
      result.addAll(testabilities.toDart);
    }
    return result.toJS;
  }

  /// For every testability, calls [callback] when they _all_ report stable.
  static void _whenAllStable(JSFunction callback) {
    final testabilities = _getAllAngularTestabilities();

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
      whenStable: ((JSFunction callback) =>
          //whenStable(callback as void Function())).toJS,
          whenStable(callback)).toJS,
    );
  }
}

extension on TestabilityRegistry {
  JsTestabilityRegistry asJsApi() {
    JsTestability? getAngularTestability(Element element) {
      final dartTestability = testabilityFor(element);
      return dartTestability?.asJsApi();
    }

    //List<JsTestability> getAllAngularTestabilities() {
    JSArray<JsTestability> getAllAngularTestabilities() {
      return allTestabilities
          .map((testability) => testability.asJsApi())
          .toList()
          .toJS;
    }

    return JsTestabilityRegistry(
      //getAngularTestability: allowInterop(getAngularTestability),
      //getAllAngularTestabilities: allowInterop(getAllAngularTestabilities),
      getAngularTestability: getAngularTestability.toJS,
      getAllAngularTestabilities: getAllAngularTestabilities.toJS,
    );
  }
}
