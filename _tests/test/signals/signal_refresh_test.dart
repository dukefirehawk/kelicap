import 'dart:async';

import 'package:test/test.dart';
import 'package:kelicap/kelicap.dart';
import 'package:kelicap/signals.dart';
import 'package:kelicap/src/core/application_ref.dart';
import 'package:kelicap/src/core/linker/app_view_utils.dart';
import 'package:kelicap/src/runtime/dom_events.dart';

import 'signal_refresh_test.template.dart' as ng;

// The state of the components, set up again by each test.
late WritableSignal<int> leaf;
late WritableSignal<int> defaultLeaf;
late WritableSignal<int> loaded;
late WritableSignal<List<int>> items;
late Map<String, int> checks;

/// Counts a check of the view named [name], from a binding in its template.
String countCheck(String name) {
  checks.update(name, (count) => count + 1, ifAbsent: () => 1);
  return '';
}

void main() {
  late NgZone ngZone;
  late ApplicationRef appRef;
  late ComponentRef<RefreshRootComponent> root;

  /// Lets the microtasks that are queued run.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  /// Sets signals outside the zone, so that only they can update the page,
  /// and returns the views checked to render them.
  Future<Map<String, int>> outside(void Function() fn) async {
    checks = {};
    ngZone.runOutsideKelicap(fn);
    await settle();
    return checks;
  }

  String text(String selector) =>
      root.location.querySelector(selector)?.textContent ?? '(none)';

  String itemsText() {
    final items = root.location.querySelectorAll('.item');
    return [for (var i = 0; i < items.length; i++) items.item(i)!.textContent]
        .join(' ');
  }

  setUp(() async {
    leaf = signal(0);
    defaultLeaf = signal(0);
    loaded = signal(0);
    items = signal([1, 2]);
    checks = {};

    ngZone = NgZone();
    appRef = internalCreateApplicationRef(
      ngZone,
      Injector.map({ExceptionHandler: _RethrowingExceptionHandler()}),
    );
    appViewUtils = AppViewUtils('appId', EventManager(ngZone));
    root = appRef.bootstrap<RefreshRootComponent>(
      ng.createRefreshRootComponentFactory(),
    );
    // Loaded after the first check, which loading in it would change.
    ngZone.run(root.instance.load);
    await settle();
  });

  tearDown(() => appRef.dispose());

  test('renders the signals', () {
    expect(text('#leaf'), '0');
    expect(text('#default-leaf'), '0');
    expect(text('#loaded'), '0');
    expect(itemsText(), '1 2');
  });

  test('refreshes the view that read a signal, not those above it', () async {
    final checked = await outside(() => leaf.set(1));
    expect(text('#leaf'), '1');
    expect(checked, {'leaf': greaterThan(0)});
  });

  test('refreshes a view in an *ngFor, not the *ngFor', () async {
    final checked = await outside(() => leaf.set(1));
    expect(checked.keys, isNot(contains('row')));
    expect(checked.keys, isNot(contains('list')));
  });

  test('refreshes a default view below an OnPush view', () async {
    final checked = await outside(() => defaultLeaf.set(1));
    expect(text('#default-leaf'), '1');
    expect(checked, {'default-leaf': greaterThan(0)});
  });

  test('refreshes a view loaded into a container', () async {
    final checked = await outside(() => loaded.set(1));
    expect(text('#loaded'), '1');
    expect(checked, {'loaded': greaterThan(0)});
  });

  test('checks the views on the way when they read it too', () async {
    final checked = await outside(() => items.set([3, 4, 5]));
    expect(itemsText(), '3 4 5');
    expect(checked.keys, containsAll(['list', 'row']));
    // A leaf whose signal did not change is not checked.
    expect(checked.keys, isNot(contains('leaf')));
  });

  test('refreshes views marked by different signals together', () async {
    final checked = await outside(() {
      leaf.set(1);
      loaded.set(2);
      defaultLeaf.set(3);
    });
    expect(
      [text('#leaf'), text('#loaded'), text('#default-leaf')],
      ['1', '2', '3'],
    );
    expect(checked.keys, unorderedEquals(['leaf', 'loaded', 'default-leaf']));
  });

  test('markForCheck() still checks the views above', () async {
    checks = {};
    // In a turn of the zone, which runs change detection when it ends.
    ngZone.run(() => LeafComponent.last!.markAncestors());
    await settle();
    expect(checks.keys, containsAll(['root', 'list', 'leaf']));
  });
}

/// The root, OnPush, with a list of rows, a default view, and a container
/// that a component is loaded into.
@Component(
  selector: 'refresh-root',
  template: '''
    {{check()}}
    <refresh-list></refresh-list>
    <default-parent></default-parent>
    <template #location></template>
  ''',
  directives: [RefreshListComponent, DefaultParentComponent],
  changeDetection: ChangeDetectionStrategy.onPush,
)
class RefreshRootComponent {
  final ChangeDetectorRef _changeDetector;

  @ViewChild('location', read: ViewContainerRef)
  ViewContainerRef? location;

  RefreshRootComponent(this._changeDetector);

  String check() => countCheck('root');

  /// Loads a component that loads another next to itself, so that its host
  /// view has a view container too.
  void load() {
    location!.createComponent(ng.createLoaderComponentFactory());
    _changeDetector.markForCheck();
  }
}

/// An OnPush list, whose rows are in an *ngFor.
@Component(
  selector: 'refresh-list',
  template: '''
    {{check()}}
    <refresh-row *ngFor="let item of items()" [item]="item"></refresh-row>
  ''',
  directives: [NgFor, RefreshRowComponent],
  changeDetection: ChangeDetectionStrategy.onPush,
)
class RefreshListComponent {
  List<int> items() => _items();

  String check() => countCheck('list');
}

List<int> _items() => items();

@Component(
  selector: 'refresh-row',
  template: '''
    {{check()}}<b class="item">{{item}}</b>
    <leaf *ngIf="item == 1"></leaf>
  ''',
  directives: [NgIf, LeafComponent],
  changeDetection: ChangeDetectionStrategy.onPush,
)
class RefreshRowComponent {
  @Input()
  late int item;

  String check() => countCheck('row');
}

@Component(
  selector: 'leaf',
  template: '<span id="leaf">{{value()}}</span>{{check()}}',
  changeDetection: ChangeDetectionStrategy.onPush,
)
class LeafComponent {
  static LeafComponent? last;

  final ChangeDetectorRef _changeDetector;

  LeafComponent(this._changeDetector) {
    last = this;
  }

  int value() => leaf();

  String check() => countCheck('leaf');

  void markAncestors() => _changeDetector.markForCheck();
}

/// An OnPush parent of a view with the default change detection.
@Component(
  selector: 'default-parent',
  template: '{{check()}}<default-leaf></default-leaf>',
  directives: [DefaultLeafComponent],
  changeDetection: ChangeDetectionStrategy.onPush,
)
class DefaultParentComponent {
  String check() => countCheck('default-parent');
}

@Component(
  selector: 'default-leaf',
  template: '<span id="default-leaf">{{value()}}</span>{{check()}}',
)
class DefaultLeafComponent {
  int value() => defaultLeaf();

  String check() => countCheck('default-leaf');
}

/// Loads [LoadedComponent] next to itself, into a view container of its host
/// view.
@Component(
  selector: 'loader',
  template: '{{check()}}',
  changeDetection: ChangeDetectionStrategy.onPush,
)
class LoaderComponent {
  LoaderComponent(ComponentLoader loader) {
    loader.loadNextTo<LoadedComponent>(ng.createLoadedComponentFactory());
  }

  String check() => countCheck('loader');
}

@Component(
  selector: 'loaded',
  template: '<span id="loaded">{{value()}}</span>{{check()}}',
  changeDetection: ChangeDetectionStrategy.onPush,
)
class LoadedComponent {
  int value() => loaded();

  String check() => countCheck('loaded');
}

class _RethrowingExceptionHandler implements ExceptionHandler {
  @override
  void call(exception, [stackTrace, String? reason]) => throw exception;
}
