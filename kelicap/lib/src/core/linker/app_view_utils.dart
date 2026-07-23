import 'dart:js_interop';

//import 'package:web/web.dart' show DocumentFragment, NodeTreeSanitizer;
import 'package:sanitize_html/sanitize_html.dart';
import 'package:web/web.dart' show DocumentFragment;

import '../../core/application_tokens.dart' as tokens show appId;
import '../../runtime/dom_events.dart' show EventManager;

/// Application wide view utilities.
late AppViewUtils appViewUtils;

/// Utilities to create unique RenderComponentType instances for AppViews and
/// provide access to root dom renderer.
class AppViewUtils {
  final String appId;
  final EventManager eventManager;

  AppViewUtils(@tokens.appId this.appId, this.eventManager);
}

/// Creates a document fragment from [trustedHtml].
DocumentFragment createTrustedHtml(String trustedHtml) {
  //return DocumentFragment.html(
  //  trustedHtml,
  //  treeSanitizer: NodeTreeSanitizer.trusted,
  //);

  // TODO: Migrate to 3.6 (Need review)
  var doc = DocumentFragment();
  doc.append(sanitizeHtml(trustedHtml).toJS);
  return doc;
}

class NodeTreeSanitizer {}
