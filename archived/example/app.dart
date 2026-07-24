import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:package_config/package_config.dart';

import '../../compiler/test/v1/kelicap_compiler/src/resolve.dart';

// final _packageConfigFuture = Platform
//           .environment['KELICAP_PACKAGE_CONFIG_PATH'] !=
//       null
//   ? loadPackageConfigUri(
//       Uri.base.resolve(Platform.environment['KELICAP_PACKAGE_CONFIG_PATH']!))
//   : Isolate.packageConfig.then(loadPackageConfigUri);

void main() async {
  _testResolveModuleRaw();
  _testResolveModule();
}

/* 
 * Attempt to resolve module with includes and providers
*/
void _testResolveModule() async {
  final packageConfig = await packageConfigFuture;

  final inputSource = r'''
      library test;

      import 'package:kelicap/kelicap.dart';

      class Dependency {}

      const someToken = const OpaqueToken('someToken');

      const newModuleA = Module(
        provide: [
          Provider(Dependency)
        ],
      );

      const newModuleB = Module(
        include: [
          newModuleA,
        ],

        provide: [
          Provider(Example),
        ],
      );

      const newModuleC = Module(
        include: [
          newModuleB,
        ],

        provide: [
          Provider(Example, useClass: ExamplePrime),
        ],
      );

      @newModuleA
      @newModuleB
      @newModuleC
      @Injectable()
      class Example {}

      class ExamplePrime extends Example {}

      @Component(
        selector: 'example',
        template: 'Hello World',
      )
      class Example2 {}
    ''';

  var testLib = await resolveSource(
    inputSource,
    (resolver) async => (await resolver.findLibraryByName('test'))!,
    //inputId: AssetId('test_lib', 'lib/test_lib.dart'),
    //inputId: AssetId('kelicap', 'lib/kelicap.dart'),
    nonInputsToReadFromFilesystem: {
      AssetId('kelicap', 'lib/kelicap.dart'),
      //   AssetId('kelicap', 'lib/src/meta.dart'),
      AssetId('kelicap', 'lib/src/meta/di_modules.dart'),
      AssetId('kelicap', 'lib/src/meta/di_arguments.dart'),
      AssetId('kelicap', 'lib/src/meta/change_detection_constants.dart'),
      AssetId('kelicap', 'lib/src/meta/change_detection_link.dart'),
      AssetId('kelicap', 'lib/src/meta/di_generate_injector.dart'),
      AssetId('kelicap', 'lib/src/meta/di_modules.dart'),
      AssetId('kelicap', 'lib/src/meta/di_providers.dart'),
      AssetId('kelicap', 'lib/src/meta/di_tokens.dart'),
      AssetId('kelicap', 'lib/src/meta/directives.dart'),
      AssetId('kelicap', 'lib/src/meta/lifecycle_hooks.dart'),
      AssetId('kelicap', 'lib/src/meta/typed.dart'),
      AssetId('kelicap', 'lib/src/meta/view.dart'),
      AssetId('kelicap', 'lib/src/meta/visibility.dart'),
    },
    packageConfig: packageConfig,
  );
  var example = testLib.getClass('Example')!;
  var example2 = testLib.getClass('Example2')!;
  var dependency = testLib.getClass('Dependency')!;
}

/* 
 * Working version of resolve module test
*/
void _testResolveModuleRaw() async {
  final inputSource = r'''
      library test;

      import 'package:kelicap/kelicap.dart';

      class Dependency {}

      const newModuleA = Module();

      const newModuleB = Module(
        include: [
          newModuleA
        ]
      );

      const newModuleC = Module(
        include: [
          newModuleB,
        ]
      );

      const listModule = [
        Example,
        newModuleA,
      ];

      // A parameter metadata that marks a dependency.
      //class Injectable {
      //  const Injectable();
      //}

      @listModule
      @newModuleA
      @newModuleB
      @newModuleC
      @Injectable()
      class Example {}

      class ExamplePrime extends Example {}

    ''';

  // final config = PackageConfig([
  //   Package(
  //     'kelicap',
  //     Uri.parse('file:///home/thii/dart_workspace/kelicap/kelicap/'),
  //     packageUriRoot: Uri.parse(
  //       'file:///home/thii/dart_workspace/kelicap/kelicap/lib/',
  //     ),
  //   ),
  // ]);

  final config = await loadPackageConfigUri(
    Uri.base.resolve(
      'file:///home/thii/dart_workspace/kelicap/.dart_tool/package_config.json',
    ),
  );

  //final testAssetId = AssetId('test', 'lib/resolve.dart');

  var testLib = await resolveSource(
    inputSource,
    (resolver) async {
      return await resolver.findLibraryByName('test');
    },
    //inputId: testAssetId,
    nonInputsToReadFromFilesystem: {
      AssetId('kelicap', 'lib/kelicap.dart'),
      AssetId('kelicap', 'lib/src/meta.dart'),
      AssetId('kelicap', 'lib/src/meta/di_modules.dart'),
      AssetId('kelicap', 'lib/src/meta/di_arguments.dart'),
    },
    packageConfig: config,
  );
  var example = testLib?.getClass('Example')!;
  var dependency = testLib?.getClass('Dependency')!;
}

/*
      class Module {
        final List<Module> include;

        @literal
        const factory Module({List<Module> include}) = Module._;

        const Module._({this.include = const []});
      }

*/
/*
      class Dependency {}

      const listModule = [
        Example,
        newModuleA,
      ];

      const newModuleA = Module(
        provide: [
          Provider(Dependency)
        ],
      );

      const newModuleB = Module(
        include: [
          newModuleA,
        ],

        provide: [
          Provider(Example),
        ],
      );

      const newModuleC = Module(
        include: [
          newModuleB,
        ],

        provide: [
          Provider(Example, useClass: ExamplePrime),
        ],
      );

      @listModule
      @newModuleA
      @newModuleB
      @newModuleC
      @Injectable()
      class Example {}

      class ExamplePrime extends Example {}
*/
