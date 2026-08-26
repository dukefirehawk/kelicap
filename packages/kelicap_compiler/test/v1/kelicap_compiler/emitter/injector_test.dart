import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';

import '../../../../lib/v1/compiler.dart';

void main() {
  final dartfmt = DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  );
  EqualsDart.format = dartfmt.format;

  TokenElement dummyToken = TypeTokenElement(TypeLink('Token', null));
  late InjectorEmitter emitter;

  /*
  void printClass(Class clazz) {
    print('Class: ${clazz.name}');

    if (clazz.extend != null) {
      print('extends: ${clazz.extend?.symbol}');
    }

    if (clazz.implements.isNotEmpty) {
      print('implements: ');
      for (var c in clazz.implements) {
        print('- ${c.symbol}');
      }
    }

    if (clazz.constructors.isNotEmpty) {
      print('constructors: ');
      for (var c in clazz.constructors) {
        print('- ${c.name}');
      }
    }

    if (clazz.methods.isNotEmpty) {
      print('methods: ');
      for (var m in clazz.methods) {
        if (m.annotations.isNotEmpty) {
          print('  annotations: ');
          for (var a in m.annotations) {
            print('  - ${(a as Reference).symbol}');
          }
        }
        print('  name: ${m.name}');
      }
    }
  }
  */

  setUp(() {
    emitter = InjectorEmitter()..visitMeta('FooInjector', 'fooInjector');
  });

  test('createFactory should return a factory function', () {
    emitter.visitMeta('FooInjector', 'fooInjector');
    expect(
      Library((b) => b.body.add(emitter.createFactory())),
      equalsDart(r'''
        Injector fooInjector(Injector parent) => FooInjector._(parent);
      '''),
    );
  });

  group('createClass should return a class', () {
    test('empty case', () {
      var result = emitter.createClass();

      expect(
        result,
        equalsDart(r'''
        class FooInjector extends HierarchicalInjector implements Injector {
          FooInjector._(Injector parent) : super(parent);

          @override
          Object? injectFromSelfOptional(
            Object token, [
            Object orElse = throwIfNotFound,
          ]) {
            return orElse;
          }
        }
      '''),
      );
    });
  });

  group('createInjectSelfOptional', () {
    test('should support returning a ClassProvider', () {
      // provide(Foo, useClass: FooImpl)
      emitter.visitProvideClass(
        0,
        dummyToken,
        refer('Foo'),
        refer('FooImpl'),
        null,
        [
          refer('this.get').call([refer('Dep1')]),
          refer('this.get').call([refer('Dep2')]),
        ],
        false,
      );

      var result = emitter.createClass();
      expect(
        result,
        equalsDart(r'''
        class FooInjector extends HierarchicalInjector implements Injector {
          FooInjector._(Injector parent) : super(parent);

          FooImpl _field0;

          FooImpl _getFooImpl$0() => _field0 ??= FooImpl(
            this.get(Dep1),
            this.get(Dep2),
          );

          @override
          Object? injectFromSelfOptional(
            Object token, [
            Object orElse = throwIfNotFound,
          ]) {
            if (identical(token, Foo)) {
              return _getFooImpl$0();
            }
            return orElse;
          }
        }
        '''),
      );
    });

    test('should support returning a ExistingProvider', () {
      // provide(FooPrime, useExisting: Foo)
      emitter.visitProvideExisting(
        0,
        dummyToken,
        refer('FooPrime'),
        refer('Foo'),
        refer('Foo'),
        false,
      );
      expect(
        emitter.createClass(),
        equalsDart(r'''
        class FooInjector extends HierarchicalInjector implements Injector {
          FooInjector._(Injector parent) : super(parent);

          Foo _getExisting$0() => this.get(Foo);

          @override
          Object? injectFromSelfOptional(
            Object token, [
            Object orElse = throwIfNotFound,
          ]) {
            if (identical(token, FooPrime)) {
              return _getExisting$0();
            }
            return orElse;
          }
        }
        '''),
      );
    });

    test('should support returning a FactoryProvider', () {
      // provide(Foo, useFactory: createFoo)
      emitter.visitProvideFactory(
        0,
        dummyToken,
        refer('Foo'),
        refer('Foo'),
        refer('createFoo'),
        [
          refer('this.get').call([refer('Dep1')]),
          refer('this.get').call([refer('Dep2')]),
        ],
        false,
      );

      var result = emitter.createClass();

      expect(
        result,
        equalsDart(r'''
        class FooInjector extends HierarchicalInjector implements Injector {
          FooInjector._(Injector parent) : super(parent);

          Foo _field0;

          Foo _getFoo$0() => _field0 ??= createFoo(
            this.get(Dep1),
            this.get(Dep2),
          );

          @override
          Object? injectFromSelfOptional(
            Object token, [
            Object orElse = throwIfNotFound,
          ]) {
            if (identical(token, Foo)) {
              return _getFoo$0();
            }
            return orElse;
          }
        }
        '''),
      );
    });

    test('should support returning a ValueProvider', () {
      // provide(Foo, useValue: const Foo())
      emitter.visitProvideValue(
        0,
        null,
        refer('Foo'),
        refer('Foo'),
        refer('Foo').constInstance([]),
        false,
      );
      expect(
        emitter.createClass(),
        equalsDart(r'''
        class FooInjector extends HierarchicalInjector implements Injector {
          FooInjector._(Injector parent) : super(parent);

          Foo _getFoo$0() => const Foo();

          @override
          Object? injectFromSelfOptional(
            Object token, [
            Object orElse = throwIfNotFound,
          ]) {
            if (identical(token, Foo)) {
              return _getFoo$0();
            }
            return orElse;
          }
        }
        '''),
      );
    });

    test('should support a MultiToken', () {
      final someToken = OpaqueTokenElement(
        'someToken',
        isMultiToken: true,
        classUrl: TypeLink(
          'MultiToken',
          ''
              'package:kelicap'
              '/src/core/di/opaque_token.dart',
        ),
      );
      emitter.visitProvideValue(
        0,
        someToken,
        refer('someToken'),
        refer('int'),
        literal(1),
        true,
      );
      emitter.visitProvideValue(
        1,
        someToken,
        refer('someToken'),
        refer('int'),
        literal(2),
        true,
      );
      expect(
        emitter.createClass(),
        equalsDart(r'''
        class FooInjector extends HierarchicalInjector implements Injector {
          FooInjector._(Injector parent) : super(parent);

          int _getint$0() => 1;

          int _getint$1() => 2;

          @override
          Object? injectFromSelfOptional(
            Object token, [
            Object orElse = throwIfNotFound,
          ]) {
            if (identical(token, someToken)) {
              return [
                _getint$0(),
                _getint$1(),
              ];
            }
            return orElse;
          }
        }
        '''),
      );
    });
  });
}
