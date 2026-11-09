@TestOn('browser')
library;

import 'package:test/test.dart';
import 'package:kelicap/kelicap.dart';
import 'package:kelicap_test/kelicap_test.dart';

import 'package:_tests/matchers.dart';

import 'view_container_move_test.template.dart' as ng;

void main() {
  tearDown(disposeAnyRunningTest);

  group('ViewContainerRef.insert', () {
    test('inserts a view after an empty view', () async {
      final fixture = await NgTestBed<MoveTest>(ng.createMoveTestFactory())
          .create();
      await fixture.update((component) {
        final container = component.container!
          ..createEmbeddedView(component.item!).setLocal('text', 'a')
          ..createEmbeddedView(component.empty!);
        container.createEmbeddedView(component.item!).setLocal('text', 'b');
      });
      expect(fixture.rootElement, hasTextContent('a;b;'));
    });

    test('inserts a view after only empty views', () async {
      final fixture = await NgTestBed<MoveTest>(ng.createMoveTestFactory())
          .create();
      await fixture.update((component) {
        final container = component.container!
          ..createEmbeddedView(component.empty!);
        container.createEmbeddedView(component.item!).setLocal('text', 'a');
      });
      expect(fixture.rootElement, hasTextContent('a;'));
    });
  });

  group('ViewContainerRef.move', () {
    Future<NgTestFixture<MoveTest>> createViews() async {
      final fixture = await NgTestBed<MoveTest>(ng.createMoveTestFactory())
          .create();
      await fixture.update((component) {
        for (final text in ['a', 'b', 'c']) {
          component.container!
              .createEmbeddedView(component.item!)
              .setLocal('text', text);
        }
      });
      expect(fixture.rootElement, hasTextContent('a;b;c;'));
      return fixture;
    }

    test('moves a view to the last index without an index', () async {
      final fixture = await createViews();
      await fixture.update((component) {
        final container = component.container!;
        container.move(container.get(0));
      });
      expect(fixture.rootElement, hasTextContent('b;c;a;'));
    });

    test('keeps the last view in place without an index', () async {
      final fixture = await createViews();
      await fixture.update((component) {
        final container = component.container!;
        container.move(container.get(2));
      });
      expect(fixture.rootElement, hasTextContent('a;b;c;'));
    });

    test('keeps a view in place when given its own index', () async {
      final fixture = await createViews();
      await fixture.update((component) {
        final container = component.container!;
        container.move(container.get(0), 0);
        container.move(container.get(1), 1);
      });
      expect(fixture.rootElement, hasTextContent('a;b;c;'));
    });

    test('throws on an index out of range, leaving the views', () async {
      final fixture = await createViews();
      await fixture.update((component) {
        final container = component.container!;
        expect(() => container.move(container.get(0), 3), throwsRangeError);
        expect(() => container.move(container.get(0), -2), throwsRangeError);
        expect(container.length, 3);
      });
      expect(fixture.rootElement, hasTextContent('a;b;c;'));

      // The views are still in the container, so clearing it removes them.
      await fixture.update((component) => component.container!.clear());
      expect(fixture.rootElement, hasTextContent(''));
    });

    test('moves a view after an empty view', () async {
      final fixture = await createViews();
      await fixture.update((component) {
        final container = component.container!;
        container.insert(component.empty!.createEmbeddedView(), 1);
        container.move(container.get(3), 2);
      });
      expect(fixture.rootElement, hasTextContent('a;c;b;'));
    });

    test('moves a view to the given index', () async {
      final fixture = await createViews();
      await fixture.update((component) {
        final container = component.container!;
        container.move(container.get(2), 0);
      });
      expect(fixture.rootElement, hasTextContent('c;a;b;'));
    });
  });
}

@Component(
  selector: 'move-test',
  template: '''
<template #item let-text="text">{{text}};</template><template #empty></template>
<div #container></div>''',
)
class MoveTest {
  @ViewChild('item')
  TemplateRef? item;

  @ViewChild('empty')
  TemplateRef? empty;

  @ViewChild('container', read: ViewContainerRef)
  ViewContainerRef? container;
}
