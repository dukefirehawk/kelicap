library;

import 'dart:js_interop';

import 'package:test/test.dart';
import 'package:web/web.dart';

import 'package:kelicap/kelicap.dart';

/// Matches textual content of an element including children.
Matcher hasTextContent(String expected) => _HasTextContent(expected);

final throwsNoProviderError = throwsA(_isNoProviderError);
final _isNoProviderError = const TypeMatcher<NoProviderError>();

/// Dart views over the DOM collections that `dart:html` exposed as `Map` and
/// `Iterable`, and that `package:web` exposes as their underlying interfaces.
///
/// `NamedNodeMap` and `DOMTokenList` are neither, so matchers such as
/// `contains` and `containsPair` cannot be applied to them directly.
extension DomCollections on Element {
  /// The element's attributes, keyed by qualified name.
  Map<String, String> get attributeMap {
    final result = <String, String>{};
    for (var i = 0; i < attributes.length; i++) {
      final attribute = attributes.item(i)!;
      result[attribute.name] = attribute.value;
    }
    return result;
  }

  /// The element's classes.
  List<String> get cssClasses => [
    for (var i = 0; i < classList.length; i++) classList.item(i)!,
  ];
}

class _HasTextContent extends Matcher {
  final String expectedText;

  const _HasTextContent(this.expectedText);

  @override
  bool matches(Object? item, void _) => _elementText(item) == expectedText;

  @override
  Description describe(Description description) =>
      description.add(expectedText);

  @override
  Description describeMismatch(
    item,
    Description mismatchDescription,
    void _,
    void _,
  ) {
    mismatchDescription.add(
      'Text content of element: '
      '\'${_elementText(item)}\'',
    );
    return mismatchDescription;
  }
}

String? _elementText(Object? n) {
  if (n == null) {
    return '';
  }

  if (n is Iterable) {
    return n.map(_elementText).join('');
  }

  // The DOM types from `package:web` are extension types over `JSObject`, so
  // `is` erases to the representation type and cannot distinguish them. Runtime
  // checks have to go through `isA`.
  if (n is JSObject) {
    if (n.isA<NodeList>()) {
      final nodes = n as NodeList;
      final text = StringBuffer();
      for (var i = 0; i < nodes.length; i++) {
        text.write(_elementText(nodes.item(i)));
      }
      return text.toString();
    }

    // Comments contribute no text. Angular anchors `*ngIf`/`*ngFor` with them,
    // so they are on the child list of nearly every structural directive.
    if (n.isA<Comment>()) {
      return '';
    }

    if (n.isA<Node>()) {
      final node = n as Node;

      if (n.isA<Element>()) {
        final el = n as Element;
        if (el.shadowRoot != null) {
          return _elementText(el.shadowRoot!.childNodes);
        }
      }

      if (node.childNodes.length > 0) {
        return _elementText(node.childNodes);
      }

      return node.textContent;
    }
  }

  return '$n';
}
