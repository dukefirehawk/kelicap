# Issue 1

STACKTRACE: 
main.template.dart 90:45                                                                              [_getObject$2]
main.template.dart 149:14                                                                             injectFromSelfOptional
package:kelicap/src/di/injector.dart 79:18                                                            provideUntyped
package:kelicap/src/di/injector.dart 185:20                                                           get
package:kelicap/src/core/linker/views/host_view.dart 216:28                                           injectFromAncestry
package:kelicap/src/core/linker/views/view.dart 219:16                                                inject
package:kelicap/src/core/linker/views/render_view.dart 118:7                                          injectFromAncestry
package:kelicap/src/core/linker/views/view.dart 219:16                  …
exception_handler.dart:69:5
    call exception_handler.dart:69
    handleUncaughtException application_ref.dart:137
    load__packages__kelicap__kelicap/application_ref.ApplicationRef.__/this[_onErrorSub]< application_ref.dart:38
    NgZone ng_zone.dart:118
    _rootRunUnary zone_root.dart:56
    tear operations.dart:118
    runUnary zone_delegate.dart:89
    _runUnary ng_zone.dart:115
    tear operations.dart:118
    runUnary zone.dart:816
    runUnaryGuarded zone.dart:710
    _sendData stream_impl.dart:381
    _add stream_impl.dart:312
    _sendData broadcast_stream_controller.dart:385
    add broadcast_stream_controller.dart:257
    _handleUncaughtError ng_zone.dart:169
    tear operations.dart:118
    _processUncaughtError zone.dart:563
    handleUncaughtError zone.dart:789
    _propagateToListeners future_impl.dart:848
    _completeErrorObject future_impl.dart:738
    _completeErrorObject future_impl.dart:117
    completeError future_impl.dart:82
    tear operations.dart:118
    NgZone ng_zone.dart:138
    _rootRunBinary zone_root.dart:70
    tear operations.dart:118
    runBinary zone_delegate.dart:101
    _runBinary ng_zone.dart:133
    tear operations.dart:118
    runBinary zone.dart:822
    handleError future_impl.dart:237
    handleError future_impl.dart:960
    _propagateToListeners future_impl.dart:981
    _completeErrorObject future_impl.dart:738
    _completeError future_impl.dart:742
    completeError async_patch.dart:506
    _asyncRethrow async_patch.dart:577
    36async_navigate router_outlet_directive.ddc.js:1830
    $protected dart_sdk.js:49837
    _wrapJsFunctionForAsync async_patch.dart:643
    errorCallback async_patch.dart:593
    NgZone ng_zone.dart:138
    _rootRunBinary zone_root.dart:70
    tear operations.dart:118
    runBinary zone_delegate.dart:101
    _runBinary ng_zone.dart:133
    tear operations.dart:118
    runBinary zone.dart:822
    handleError future_impl.dart:237
    handleError future_impl.dart:960
    _propagateToListeners future_impl.dart:981
    _completeErrorObject future_impl.dart:738
    _completeError future_impl.dart:742
    completeError async_patch.dart:506
    _asyncRethrow async_patch.dart:577
    36async_resolveStateForOutlet router_outlet_directive.ddc.js:1967
    $protected dart_sdk.js:49837
    _wrapJsFunctionForAsync async_patch.dart:643
    thenCallback async_patch.dart:589
    NgZone ng_zone.dart:118
    _rootRunUnary zone_root.dart:48
    tear operations.dart:118
    runUnary zone_delegate.dart:89
    _runUnary ng_zone.dart:115
    tear operations.dart:118
    runUnary zone.dart:816
    handleValue future_impl.dart:222
    handleValueCallback future_impl.dart:948
    _propagateToListeners future_impl.dart:977
    _completeWithValue future_impl.dart:720
    complete async_patch.dart:499
    _asyncReturn async_patch.dart:566
    load__packages__kelicap_components_example__gallery__gallery_route_library/get galleryRoutes/<.loader</t$36asyncBody< gallery_route_library.ddc.js:677
    $protected dart_sdk.js:49837
    _wrapJsFunctionForAsync async_patch.dart:643
    thenCallback async_patch.dart:589
    NgZone ng_zone.dart:118
    _rootRunUnary zone_root.dart:48
    tear operations.dart:118
    runUnary zone_delegate.dart:89
    _runUnary ng_zone.dart:115
    tear operations.dart:118
    runUnary zone.dart:816
    handleValue future_impl.dart:222
    handleValueCallback future_impl.dart:948
    _propagateToListeners future_impl.dart:977
    _complete future_impl.dart:711
    new future.dart:265
    NgZone ng_zone.dart:101
    _rootRun zone_root.dart:27
    tear operations.dart:118
    run zone_delegate.dart:83
    _run ng_zone.dart:98
    tear operations.dart:118
    run zone.dart:810
    runGuarded zone.dart:702
    bindCallbackGuarded zone.dart:743
    callback ng_zone.dart:187
    NgZone ng_zone.dart:101
    _rootRun zone_root.dart:35
    tear operations.dart:118
    run zone_delegate.dart:83
    _run ng_zone.dart:98
    tear operations.dart:118
    run zone.dart:810
    bindCallback zone.dart:726
    internalCallback isolate_helper.dart:47
