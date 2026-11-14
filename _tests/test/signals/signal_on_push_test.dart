import 'dart:async';

import 'package:test/test.dart';
import 'package:kelicap/kelicap.dart';
import 'package:kelicap/signals.dart';
import 'package:kelicap/src/core/application_ref.dart';
import 'package:kelicap/src/core/linker/app_view_utils.dart';
import 'package:kelicap/src/runtime/dom_events.dart';

import 'signal_on_push_test.template.dart' as ng;

// The state of the components, set up again by each test.
late WritableSignal<int> first;
late WritableSignal<int> second;
late WritableSignal<bool> show;
late WritableSignal<String> inIf;
late WritableSignal<int> effectSource;
late List<int> effectRuns;
var firstChecks = 0;
var secondChecks = 0;

void main() {
  late NgZone ngZone;
  late ApplicationRef appRef;
  late ComponentRef<OnPushRootComponent> root;

  /// Lets the microtasks that are queued run.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  /// Sets signals outside the zone, so that only they can update the page.
  Future<void> outside(void Function() fn) async {
    ngZone.runOutsideKelicap(fn);
    await settle();
  }

  String text(String selector) =>
      root.location.querySelector(selector)?.textContent ?? '(none)';

  setUp(() async {
    first = signal(0);
    second = signal(0);
    show = signal(false);
    inIf = signal('a');
    effectSource = signal(0);
    effectRuns = [];
    firstChecks = secondChecks = 0;

    ngZone = NgZone();
    appRef = internalCreateApplicationRef(
      ngZone,
      Injector.map({ExceptionHandler: _RethrowingExceptionHandler()}),
    );
    appViewUtils = AppViewUtils('appId', EventManager(ngZone));
    root = appRef.bootstrap<OnPushRootComponent>(
      ng.createOnPushRootComponentFactory(),
    );
    await settle();
  });

  tearDown(() => appRef.dispose());

  test('renders the signals', () {
    expect(text('first-child'), '0');
    expect(text('second-child'), '0');
    expect(text('#in-if'), '(none)');
  });

  test('a signal updates the OnPush component that reads it', () async {
    await outside(() => first.set(1));
    expect(text('first-child'), '1');
  });

  test('a signal does not check an OnPush sibling', () async {
    final (firstBefore, secondBefore) = (firstChecks, secondChecks);
    await outside(() => first.set(1));
    expect(firstChecks, greaterThan(firstBefore));
    expect(secondChecks, secondBefore);
  });

  test('signals of siblings set together update both', () async {
    // Both mark their parent, in either order.
    await outside(() {
      first.set(1);
      second.set(2);
    });
    expect(text('first-child'), '1');
    expect(text('second-child'), '2');
    await outside(() {
      second.set(3);
      first.set(4);
    });
    expect(text('first-child'), '4');
    expect(text('second-child'), '3');
  });

  test('a signal read by an *ngIf updates it', () async {
    await outside(() => show.set(true));
    expect(text('#in-if'), 'a');
    await outside(() => show.set(false));
    expect(text('#in-if'), '(none)');
  });

  test('a signal read in an embedded view updates it', () async {
    await outside(() => show.set(true));
    await outside(() => inIf.set('b'));
    expect(text('#in-if'), 'b');
  });

  test('a signal no longer read does not check the view', () async {
    await outside(() => show.set(true));
    await outside(() => show.set(false));
    // Only the embedded view, now destroyed, read inIf.
    await outside(() => inIf.set('b'));
    expect(text('#in-if'), '(none)');
  });

  test('an effect created during a check survives the next checks', () async {
    await outside(() => show.set(true));
    expect(effectRuns, [0]);
    // Checks the root, which created the component that created the effect.
    await outside(() => inIf.set('b'));
    await outside(() => effectSource.set(1));
    expect(effectRuns, [0, 1]);
  });

  test('an effect is destroyed with its component', () async {
    await outside(() => show.set(true));
    await outside(() => show.set(false));
    await outside(() => effectSource.set(1));
    expect(effectRuns, [0]);
  });
}

@Component(
  selector: 'on-push-root',
  template: '''
    <first-child></first-child>
    <second-child></second-child>
    <div *ngIf="show()">
      <span id="in-if">{{inIf()}}</span>
      <effect-child></effect-child>
    </div>
  ''',
  directives: [FirstChild, SecondChild, EffectChild, NgIf],
  changeDetection: ChangeDetectionStrategy.onPush,
)
class OnPushRootComponent {
  bool show() => _show();
  String inIf() => _inIf();
}

bool _show() => show();
String _inIf() => inIf();

@Component(
  selector: 'first-child',
  template: '{{value()}}{{checked()}}',
  changeDetection: ChangeDetectionStrategy.onPush,
)
class FirstChild {
  int value() => first();

  String checked() {
    firstChecks++;
    return '';
  }
}

@Component(
  selector: 'second-child',
  template: '{{value()}}{{checked()}}',
  changeDetection: ChangeDetectionStrategy.onPush,
)
class SecondChild {
  int value() => second();

  String checked() {
    secondChecks++;
    return '';
  }
}

/// A component that creates an effect, while the view of the *ngIf that
/// creates it is checked.
@Component(selector: 'effect-child', template: '')
class EffectChild implements OnDestroy {
  final EffectRef _effect = effect((_) => effectRuns.add(effectSource()));

  @override
  void ngOnDestroy() => _effect.destroy();
}

class _RethrowingExceptionHandler implements ExceptionHandler {
  @override
  void call(exception, [stackTrace, String? reason]) => throw exception;
}
