import 'package:test/test.dart';

// ignore: avoid_relative_lib_imports
import '../../lib/compiler.dart';

import 'package:kelicap_compiler/v2/context.dart';

void main() {
  setUp(CompileContext.overrideForTesting);

  Matcher readsMember(String access) =>
      contains('"$access" reads a member of a DOM event dynamically');

  test('warns on a member of a DOM event in a template', () async {
    await compilesExpecting(
      '''
      import '$ngImport';

      @Component(
        selector: 'test',
        template: r'<button (click)="onClick(\$event.target)"></button>',
      )
      class TestComponent {
        void onClick(Object? target) {}
      }
    ''',
      warnings: [readsMember(r'$event.target')],
    );
  });

  test('warns on a method of a DOM event in a template', () async {
    await compilesExpecting(
      '''
      import '$ngImport';

      @Component(
        selector: 'test',
        template: r'<a (click)="\$event.preventDefault()"></a>',
      )
      class TestComponent {}
    ''',
      warnings: [readsMember(r'$event.preventDefault()')],
    );
  });

  test('warns on a member of a DOM event in a @HostListener', () async {
    await compilesExpecting(
      '''
      import '$ngImport';

      @Directive(selector: '[listener]')
      class ListenerDirective {
        @HostListener('click', [r'\$event.type'])
        void onClick(String type) {}
      }

      @Component(
        selector: 'test',
        template: '<div listener></div>',
        directives: [ListenerDirective],
      )
      class TestComponent {}
    ''',
      warnings: [readsMember(r'$event.type')],
    );
  });

  test(
    'warns on a member of a DOM event in a component @HostListener',
    () async {
      await compilesExpecting(
        '''
      import '$ngImport';

      @Component(selector: 'test', template: '')
      class TestComponent {
        @HostListener('click', [r'\$event.type'])
        void onClick(String type) {}
      }
    ''',
        warnings: [readsMember(r'$event.type')],
      );
    },
  );

  test(
    'warns once on a @HostListener of a directive used many times',
    () async {
      await compilesExpecting(
        '''
      import '$ngImport';

      @Directive(selector: '[listener]')
      class ListenerDirective {
        @HostListener('click', [r'\$event.type'])
        void onClick(String type) {}
      }

      @Component(
        selector: 'test',
        template: '<div listener></div><div listener></div>',
        directives: [ListenerDirective],
      )
      class TestComponent {}

      @Component(
        selector: 'other',
        template: '<div listener></div>',
        directives: [ListenerDirective],
      )
      class OtherComponent {}
    ''',
        warnings: [readsMember(r'$event.type')],
      );
    },
  );

  test(
    'warns on a @HostListener only in the library of its directive',
    () async {
      await compilesExpecting(
        '''
      import '$ngImport';
      import 'listener.dart';

      @Component(
        selector: 'test',
        template: '<div listener></div>',
        directives: [ListenerDirective],
      )
      class TestComponent {}
    ''',
        include: {
          'pkg|lib/listener.dart':
              '''
          import '$ngImport';

          @Directive(selector: '[listener]')
          class ListenerDirective {
            @HostListener('click', [r'\$event.type'])
            void onClick(String type) {}
          }
        ''',
        },
        warnings: [
          allOf(
            readsMember(r'$event.type'),
            contains('package:pkg/listener.dart'),
          ),
        ],
      );
    },
  );

  test('warns on a member of a non-null DOM event', () async {
    await compilesExpecting(
      '''
      import '$ngImport';

      @Component(
        selector: 'test',
        template: r'<button (click)="onClick(\$event!.target)"></button>',
      )
      class TestComponent {
        void onClick(Object? target) {}
      }
    ''',
      warnings: [readsMember(r'$event!.target')],
    );
  });

  test('warns on a key of a DOM event', () async {
    await compilesExpecting(
      '''
      import '$ngImport';

      @Component(
        selector: 'test',
        template:
            r'<button (click)="onClick(\$event[' "'type'" r'])"></button>',
      )
      class TestComponent {
        void onClick(Object? type) {}
      }
    ''',
      warnings: [readsMember(r"$event['type']")],
    );
  });

  test('does not warn on a DOM event passed as a whole', () async {
    await compilesNormally('''
      import '$ngImport';

      @Component(
        selector: 'test',
        template: r'<button (click)="onClick(\$event)"></button>',
      )
      class TestComponent {
        void onClick(Object? event) {}
      }
    ''');
  });

  test('warns on a member of the DOM event of an output', () async {
    await compilesExpecting(
      '''
      import 'dart:async';
      import 'package:web/web.dart';
      import '$ngImport';

      @Component(selector: 'child', template: '')
      class ChildComponent {
        @Output()
        Stream<UIEvent?> get trigger => const Stream.empty();
      }

      @Component(
        selector: 'test',
        template: r'<child (trigger)="onTrigger(\$event.target)"></child>',
        directives: [ChildComponent],
      )
      class TestComponent {
        void onTrigger(Object? target) {}
      }
    ''',
      warnings: [readsMember(r'$event.target')],
    );
  });

  for (final type in ['T', 'Object', 'dynamic']) {
    test('does not warn on a member of the event of a Stream<$type>', () async {
      await compilesNormally('''
        import 'dart:async';
        import '$ngImport';

        @Component(selector: 'child', template: '')
        class ChildComponent<T> {
          @Output()
          Stream<$type> get changed => const Stream.empty();
        }

        @Component(
          selector: 'test',
          template: r'<child (changed)="onChanged(\$event.length)"></child>',
          directives: [ChildComponent],
        )
        class TestComponent {
          void onChanged(Object? length) {}
        }
      ''');
    });
  }

  test('does not warn on a member of the event of an output', () async {
    await compilesNormally('''
      import 'dart:async';
      import '$ngImport';

      @Component(selector: 'child', template: '')
      class ChildComponent {
        @Output()
        Stream<String> get changed => const Stream.empty();
      }

      @Component(
        selector: 'test',
        template: r'<child (changed)="length = \$event.length"></child>',
        directives: [ChildComponent],
      )
      class TestComponent {
        int length = 0;
      }
    ''');
  });
}
