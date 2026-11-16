// Tests the code that the template compiler generates to check the views that
// signals mark for refresh, by compiling a component with the builder that
// build_runner runs.
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import 'package:kelicap/src/build.dart';

const _input = '_tests|lib/marked_views.dart';
const _output = '_tests|lib/marked_views.template.dart';

/// Compiles [source], a library that imports `package:kelicap`, and returns
/// the code of its `.template.dart` file.
Future<String> _compile(String source) async {
  final readerWriter = TestReaderWriter(rootPackage: '_tests');
  await readerWriter.testing.loadIsolateSources();
  final result = await testBuilders(
    [
      templatePlaceholder(BuilderOptions.empty),
      templateCompiler(BuilderOptions.empty),
    ],
    {_input: source},
    rootPackage: '_tests',
    generateFor: {_input},
    readerWriter: readerWriter,
    flattenOutput: true,
  );
  expect(result.succeeded, isTrue, reason: 'the template compiler failed');
  return readerWriter.testing.readString(AssetId.parse(_output));
}

/// Returns the body of the method [name] of the class [className] in [code].
String _method(String code, String className, String name) {
  final classStart = code.indexOf(RegExp('class $className\\b'));
  expect(classStart, isNot(-1), reason: 'no class $className');
  final nextClass = code.indexOf(RegExp(r'\nclass '), classStart + 1);
  final classCode = code.substring(
    classStart,
    nextClass == -1 ? code.length : nextClass,
  );
  final start = classCode.indexOf(RegExp('\\b$name\\(\\)'));
  if (start == -1) return '';
  final open = classCode.indexOf('{', start);
  var depth = 0;
  for (var i = open; i < classCode.length; i++) {
    if (classCode[i] == '{') depth++;
    if (classCode[i] == '}' && --depth == 0) {
      return classCode.substring(open, i + 1);
    }
  }
  fail('$name in $className has no end');
}

void main() {
  late String code;

  setUpAll(() async {
    code = await _compile(r'''
      import 'package:kelicap/kelicap.dart';

      @Component(
        selector: 'child',
        template: '{{value}}',
        changeDetection: ChangeDetectionStrategy.onPush,
      )
      class ChildComponent {
        var value = 0;
      }

      @Component(
        selector: 'checked-child',
        template: '',
      )
      class CheckedChildComponent implements DoCheck, AfterViewChecked {
        @override
        void ngDoCheck() {}

        @override
        void ngAfterViewChecked() {}
      }

      @Component(
        selector: 'parent',
        template: """
          <child></child>
          <checked-child></checked-child>
          <child *ngIf="show"></child>
        """,
        directives: [ChildComponent, CheckedChildComponent, NgIf],
      )
      class ParentComponent {
        var show = true;
      }

      @Component(selector: 'leaf', template: 'Leaf')
      class LeafComponent {}
    ''');
  });

  group('detectChangesInternal', () {
    test('checks child component views with detectChangesDeprecated', () {
      final body = _method(
        code,
        r'ViewParentComponent0',
        'detectChangesInternal',
      );
      expect(
        RegExp(r'\.detectChangesDeprecated\(\)').allMatches(body),
        hasLength(2),
      );
      // The public detectChanges() would also stop the parent from recording
      // the signals that its children read, and costs more.
      expect(body, isNot(contains('.detectChanges()')));
    });
  });

  group('detectChangesInMarkedViews', () {
    late String body;

    setUp(() {
      // With its whitespace collapsed, to compare it with expected code.
      body = _method(
        code,
        r'ViewParentComponent0',
        'detectChangesInMarkedViews',
      ).replaceAll(RegExp(r'\s+'), ' ');
    });

    test('reaches child component views and view containers', () {
      expect(
        body,
        contains('this._appEl_2.detectChangesInMarkedNestedViews();'),
      );
      expect(
        body,
        contains('this._compView_0.detectChangesInMarkedDescendants();'),
      );
      // Only the views below are checked, not this one.
      expect(body, isNot(contains('detectChangesDeprecated')));
      expect(body, isNot(contains('_ctx')));
    });

    test('runs the after-checked hooks of a child only if it is marked', () {
      expect(
        body,
        contains(
          'if (this._compView_1.isMarkedForRefresh) { '
          'this._compView_1.detectChangesInMarkedDescendants(); '
          'if ((!import10.debugThrowIfChanged)) { '
          'this._CheckedChildComponent_1_6.ngAfterViewChecked(); } '
          '} else { this._compView_1.detectChangesInMarkedDescendants(); }',
        ),
      );
    });

    test('does not run ngDoCheck, as this view is not checked', () {
      expect(
        _method(code, r'ViewParentComponent0', 'detectChangesInternal'),
        contains('ngDoCheck()'),
      );
      expect(body, isNot(contains('ngDoCheck')));
    });

    test('is generated in an embedded view with a child component', () {
      final body = _method(
        code,
        r'_ViewParentComponent1',
        'detectChangesInMarkedViews',
      );
      expect(body, contains('.detectChangesInMarkedDescendants()'));
    });

    test('is not generated in a view without views below it', () {
      expect(
        _method(code, r'ViewLeafComponent0', 'detectChangesInMarkedViews'),
        isEmpty,
      );
    });
  });
}
