import 'dart:js_interop';

import 'package:web/web.dart'
    show DocumentFragment, HTMLTemplateElement, document;

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
///
/// [trustedHtml] has already been established as trusted by the caller -- this
/// parses it, and deliberately does not sanitize it. That is what the
/// `NodeTreeSanitizer.trusted` argument meant when this used
/// `DocumentFragment.html` under `dart:html`.
///
/// A `<template>` is the parsing context because its `content` is itself a
/// [DocumentFragment], and because the fragment parsing algorithm does not
/// apply the usual element-nesting restrictions inside one -- markup such as a
/// bare `<tr>` survives, where parsing into a `<div>` would drop it.
///
/// Note this must *parse* the markup. Appending the string to a fragment, as
/// `ParentNode.append` does, inserts it as a text node, and the tags then
/// render as visible characters instead of as elements.
DocumentFragment createTrustedHtml(String trustedHtml) {
  final template = document.createElement('template') as HTMLTemplateElement
    ..setHTMLUnsafe(trustedHtml.toJS);
  return template.content;
}
