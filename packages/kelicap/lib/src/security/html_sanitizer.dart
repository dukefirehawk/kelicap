import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart';

/// Sanitizes the given unsafe, untrusted HTML fragment, and returns HTML text
/// that is safe to add to the DOM in a browser environment.
///
/// Parsing and sanitization are done by the browser's [HTML Sanitizer API][]:
/// `Element.setHTML` on a detached element, then reading `innerHTML` back off
/// it. The allow-list is the browser's own default, which tracks browser
/// security updates rather than a pinned package, and which is deliberately
/// left unconfigured -- every relaxation of it (`allowElement`,
/// `allowAttribute`, `setComments`) is a security decision, and the default is
/// the one the browser vendors maintain.
///
/// Note this differs from the `NodeTreeSanitizer` implementation it replaces in
/// three ways: comments are stripped, `<img>` is dropped (it is the classic
/// `onerror` vector, and the default allow-list excludes it), and processing
/// instructions are serialized as-is rather than as comments.
///
/// This requires `Element.setHTML`, which `package:web` does not yet bind --
/// hence the `callMethodVarArgs` -- and which is available from Chrome 140,
/// Firefox 145 and Safari 26.2. On a browser without it this throws rather than
/// silently returning unsanitized markup.
///
/// [HTML Sanitizer API]: https://developer.mozilla.org/en-US/docs/Web/API/HTML_Sanitizer_API
String? sanitizeHtmlInternal(String value) {
  final inert = document.createElement('div');
  inert.callMethodVarArgs('setHTML'.toJS, [value.toJS]);
  return (inert.innerHTML as JSString?)?.toDart;
}

/*

final _inertFragment = DocumentFragment();

String? sanitizeHtmlInternal(String value) {
  //final inertFragment = _inertFragment..innerHtml = value;
  //final safeHtml = inertFragment.innerHtml;
  //inertFragment.children.clear();

  final inertFragment = _inertFragment..textContent = value;
  final safeHtml = inertFragment.textContent;
  var list = inertFragment.children;
  for (var i = list.length; i > 0; i--) {
    list.item(i)?.remove();
  }

  return safeHtml;
}
*/
