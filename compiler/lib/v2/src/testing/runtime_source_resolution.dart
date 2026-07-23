/// At runtime (in command-line VM tests) resolves and instruments Dart source.
///
/// For functional tests that instrument the compiler in ad-hoc fashion; for
/// example to expect that given source code produces an error or other
/// specific output.
library;

import 'dart:async';
import 'dart:isolate';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:build/experiments.dart';
import 'package:build_test/build_test.dart';
import 'package:package_config/package_config.dart';

const _kelicapPkgPath = 'package:';
const _kelicapLibPath = '${_kelicapPkgPath}kelicap/kelicap.dart';
const _defaultLibrary = 'test_lib';
final _defaultAssetId = AssetId(_defaultLibrary, 'lib/$_defaultLibrary.dart');
final _cachedPackageConfig = _loadPackageConfig();

Future<PackageConfig> _loadPackageConfig() {
  var config = Isolate.packageConfig.then((uri) => loadPackageConfigUri(uri!));
  return config;
}

String _assetToPath(AssetId asset) => '${asset.package}|${asset.path}';

/// Resolves [dartSource] as a library `package:test_lib/test_lib.dart`.
///
/// Example:
/// ```
/// lib = await resolveLibrary(
///   '''
///     @Component(
///       selector: 'example',
///       template: 'Hello World',
///     )
///     class ExampleComponent {}
///   ''',
/// );
/// ```
///
/// * [additionalFiles]: May provide additional files available to the program:
///   ```
///   resolveLibrary(
///     '''
///       @Component(
///         selector: 'example',
///         templateUrl: 'example.html',
///       )
///       class ExampleComponent {}
///     ''',
///     additionalFiles: {
///       AssetId(
///         'test_lib',
///         'lib/example.html',
///       ): '''
///         <div>Hello World</div>
///       ''',
///     },
///   )
///   ```
///
/// * [includeKelicapDeps]: Set `false` to not include `import 'kelicap.dart'`.
///   This may be used to simulate scenarios where the user has forgotten to add
///   an import to Kelicap, or where you would want the import specified as an
///   alternative entry-point.
Future<LibraryElement> resolve(
  String dartSource, {
  Map<AssetId, String> additionalFiles = const {},
  bool includeKelicapDeps = true,
}) async {
  // Add library and import directives to the top.
  dartSource = [
    if (includeKelicapDeps) "import '$_kelicapLibPath';",
    '',
    dartSource,
  ].join('\n');
  final sources = {
    // Map<AssetId, String> -> Map<String, String>
    for (final entry in additionalFiles.entries)
      _assetToPath(entry.key): entry.value,

    // Adds an additional file (dartSource).
    _assetToPath(_defaultAssetId): dartSource,
  };
  final config = await _cachedPackageConfig;
  final result = await withEnabledExperiments(
    () => resolveSources(
      sources,
      (resolver) => resolver.libraryFor(_defaultAssetId),
      nonInputsToReadFromFilesystem: {
        AssetId('kelicap', 'lib/kelicap.dart'),
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
      packageConfig: config,
    ),
    ['non-nullable'],
  );
  return result;
}
