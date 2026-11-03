import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:build/experiments.dart';
import 'package:build_test/build_test.dart';
import 'package:package_config/package_config.dart';

const kelicap = 'package:kelicap/kelicap.dart';

/// A custom package resolver for Kelicap sources.
///
/// This is needed to resolve sources that import Kelicap.
final packageConfigFuture =
    Platform.environment['Kelicap_PACKAGE_CONFIG_PATH'] != null
    ? loadPackageConfigUri(
        Uri.base.resolve(Platform.environment['Kelicap_PACKAGE_CONFIG_PATH']!),
      )
    : Isolate.packageConfig.then((uri) => loadPackageConfigUri(uri!));

/// Resolves [source] code as-if it is implemented with an kelicap import.
///
/// Returns the resolved library as `package:test_lib/test_lib.dart`.
Future<LibraryElement> resolveLibrary(String source) async {
  final packageConfig = await packageConfigFuture;

  var inputSource =
      '''
      library _test;
      import '$kelicap';

      $source
    ''';

  //print(inputSource);
  return withEnabledExperiments(
    () => resolveSource(
      inputSource,
      (resolver) async => (await resolver.findLibraryByName('_test'))!,
      inputId: AssetId('test_lib', 'lib/test_lib.dart'),
      nonInputsToReadFromFilesystem: {
        AssetId('kelicap', 'lib/kelicap.dart'),
        AssetId('kelicap_common', 'lib/kelicap_common.dart'),
        AssetId('kelicap_common', 'lib/src/meta/constants.dart'),
        AssetId('kelicap', 'lib/src/meta/di_modules.dart'),
        AssetId('kelicap', 'lib/src/meta/di_arguments.dart'),
        AssetId('kelicap', 'lib/src/meta/di_generate_injector.dart'),
        AssetId('kelicap', 'lib/src/meta/di_providers.dart'),
        AssetId('kelicap', 'lib/src/meta/di_tokens.dart'),
        AssetId('kelicap', 'lib/src/meta/directives.dart'),
        AssetId('kelicap', 'lib/src/meta/change_detection_link.dart'),
        AssetId('kelicap', 'lib/src/meta/lifecycle_hooks.dart'),
        AssetId('kelicap', 'lib/src/meta/typed.dart'),
      },
      packageConfig: packageConfig,
    ),
    ['non-nullable'],
  );
}

/// Resolves [source] code as-if it is implemented with an kelicap import.
///
/// Returns first `class` in the file, or by [name] if given.
Future<ClassElement?> resolveClass(String source, [String? name]) async {
  final library = await resolveLibrary(source);
  return name != null
      ? library.getClass(name)
      : library.firstFragment.classes.first.element;
}
