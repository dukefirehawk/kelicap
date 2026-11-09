@TestOn('browser')
library;

import 'dart:js_interop';

import 'package:test/test.dart';
import 'package:web/web.dart';
import 'package:kelicap/src/runtime/dom_helpers.dart';

void main() {
  late HTMLDivElement parent;

  /// Adds a `<span>` with [text] to the end of [parent].
  Node span(String text) =>
      parent.appendChild((document.createElement('span')..textContent = text));

  String order() => parent.textContent!;

  setUp(() {
    parent = document.createElement('div') as HTMLDivElement;
  });

  group('insertNodesAsSibling', () {
    test('inserts nodes after a sibling, before the next one', () {
      final sibling = span('s');
      span('x');
      final nodes = [
        document.createTextNode('a'),
        document.createTextNode('b'),
      ];
      insertNodesAsSibling(nodes, sibling);
      expect(order(), 'sabx');
    });

    test('appends nodes after the last sibling', () {
      final sibling = span('s');
      final nodes = [
        document.createTextNode('a'),
        document.createTextNode('b'),
      ];
      insertNodesAsSibling(nodes, sibling);
      expect(order(), 'sab');
    });

    test('keeps the order of nodes already after the sibling', () {
      final sibling = span('s');
      final nodes = [span('a'), span('b')];
      span('x');
      insertNodesAsSibling(nodes, sibling);
      expect(order(), 'sabx');
    });

    test('keeps the order of the last nodes already after the sibling', () {
      final sibling = span('s');
      final nodes = [span('a'), span('b')];
      insertNodesAsSibling(nodes, sibling);
      expect(order(), 'sab');
    });

    test('gathers nodes after the sibling around another node', () {
      final sibling = span('s');
      final a = span('a');
      span('x');
      final b = span('b');
      insertNodesAsSibling([a, b], sibling);
      expect(order(), 'sabx');
    });

    test('puts nodes in order that follow the sibling in reverse', () {
      final sibling = span('s');
      final b = span('b');
      final a = span('a');
      span('x');
      insertNodesAsSibling([a, b], sibling);
      expect(order(), 'sabx');
    });

    test('puts nodes in order when a later one follows the sibling', () {
      final sibling = span('s');
      final b = span('b');
      final c = span('c');
      final a = document.createTextNode('a');
      insertNodesAsSibling([a, b, c], sibling);
      expect(order(), 'sabc');
    });

    test('leaves nodes already in place in the DOM', () {
      final sibling = span('s');
      final nodes = [span('a'), span('b')];
      span('x');
      final observer = MutationObserver(
        ((JSArray<MutationRecord> _, MutationObserver _) {}).toJS,
      )..observe(parent, MutationObserverInit(childList: true));
      insertNodesAsSibling(nodes, sibling);
      final records = observer.takeRecords().toDart;
      observer.disconnect();
      expect(records, isEmpty);
      expect(order(), 'sabx');
    });

    test('moves nodes from before the sibling', () {
      final nodes = [span('a'), span('b')];
      final sibling = span('s');
      span('x');
      insertNodesAsSibling(nodes, sibling);
      expect(order(), 'sabx');
    });
  });
}
