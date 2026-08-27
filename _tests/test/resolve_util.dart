import 'dart:io';
import 'dart:isolate';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:build/experiments.dart';
import 'package:build_test/build_test.dart';

import 'package:kelicap_compiler/v1/src/compiler/template_compiler.dart';
import 'package:kelicap_compiler/v1/src/source_gen/template_compiler/component_visitor_exceptions.dart';
import 'package:kelicap_compiler/v1/src/source_gen/template_compiler/find_components.dart';

import 'package:package_config/package_config.dart';
import 'package:source_gen/source_gen.dart';

//import 'package:kelicap_compiler/v2/src/compiler/template_compiler.dart';
//import 'package:kelicap_compiler/v2/src/source_gen/template_compiler/component_visitor_exceptions.dart';
//import 'package:kelicap_compiler/v2/src/source_gen/template_compiler/find_components.dart';

// Use custom package config for angular sources if specified.
//
// Read into a local first: an index expression is not promoted by a null check,
// so `Platform.environment[...]` stays `String?` at the use site.
final _customPackageConfigPath =
    Platform.environment['ANGULAR_PACKAGE_CONFIG_PATH'];

final _packageConfigFuture = _customPackageConfigPath != null
    ? loadPackageConfigUri(Uri.base.resolve(_customPackageConfigPath!))
    // `Isolate.packageConfig` is a `Future<Uri?>`, and `loadPackageConfigUri`
    // takes a non-null `Uri` plus optional named parameters, so it can no
    // longer be torn off directly as a `Function(Uri?)`.
    : Isolate.packageConfig.then((uri) => loadPackageConfigUri(uri!));

Future<LibraryElement> resolve(
  String source, [
  PackageConfig? packageConfig,
]) async {
  final testAssetId = AssetId('_tests', 'lib/resolve.dart');
  return await withEnabledExperiments(
    () => resolveSource(
      source,
      (resolver) => resolver.libraryFor(testAssetId),
      inputId: testAssetId,
      packageConfig: packageConfig,
    ),
    ['non-nullable'],
  );
}

Future<NormalizedComponentWithViewDirectives> resolveAndFindComponent(
  String source,
) async {
  final library = await resolve(
    "import 'package:kelicap/kelicap.dart';"
    '$source',
    await _packageConfigFuture,
  );
  final artifacts = findComponentsAndDirectives(
    LibraryReader(library),
    ComponentVisitorExceptionHandler(),
  );
  return artifacts.components.first;
}
