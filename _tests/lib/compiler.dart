import 'dart:io';

import 'package:build/build.dart';
import 'package:build/experiments.dart';
import 'package:build_test/build_test.dart';
import 'package:glob/glob.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';
import 'package:kelicap_compiler/v2/context.dart';
import 'package:kelicap/src/build.dart';

/// A 'test' build process (similar to the normal one).
///
/// These are the same builder factories `build.yaml` registers. They used to be
/// composed with a `MultiplexingBuilder`, which no longer exists in `build` 4;
/// `testBuilders` takes the list directly instead.
final List<Builder> _testAngularBuilders = [
  templateCompiler(BuilderOptions({})),
  stylesheetCompiler(BuilderOptions({})),
];

// Here to be configurable.
//
// We could use a better PackageAssetReader if necessary in some platforms.
final Future<PackageAssetReader> _packageAssets = (() async {
  final runfiles = Platform.environment['RUNFILES'];
  if (runfiles == null) {
    return PackageAssetReader.currentIsolate();
  }
  final root = Platform.environment['PKG_ANGULAR_ROOT'];
  final path = '$runfiles/$root';
  if (!FileSystemEntity.isFileSync('$path/kelicap/lib/angular.dart')) {
    throw StateError('Could not find $path/kelicap/lib/angular.dart');
  }
  final pathToMeta = '$path/kelicap/lib/src/meta.dart';
  if (!FileSystemEntity.isFileSync(pathToMeta)) {
    throw StateError('Could not find $pathToMeta');
  }
  print('file://$path/kelicap/lib');
  return PackageAssetReader.forPackages({
    ngPackage: '$path/kelicap/',
    ngCompiler: '$path/ngcompiler/',
  });
})();

// The locations of the import for AngularDart source code.
//
// **NOTE**: Be very careful changing this, there are hard-coded transformation
// rules as part of open sourcing process to make sure this works both
// externally and internally.
const ngPackage = 'kelicap';
const ngCompiler = 'kelicap_compiler';
const ngImport = 'package:$ngPackage/kelicap.dart';
final _ngFiles = Glob('lib/**.dart');

/// Modeled after `package:build_test/build_test.dart#testBuilders`.
Future<void> _testBuilder(
  List<Builder> builders,
  Map<String, String> sourceAssets, {
  List<AssetId>? runBuilderOn,
  required void Function(LogRecord) onLog,
  String? rootPackage,
}) async {
  // Sanity check that the framework itself is readable.
  final packages = await _packageAssets;
  if (!await packages.canRead(AssetId(ngPackage, 'lib/kelicap.dart'))) {
    throw StateError('Unable to read "$ngImport".');
  }

  if (sourceAssets.isEmpty) {
    throw ArgumentError.value(sourceAssets, 'No inputs', 'sourceAssets');
  }

  final generateFor = runBuilderOn?.map((id) => id.toString()).toSet();

  // The framework has to be readable so the analyzer can resolve
  // `package:kelicap` -- without it every annotation fails to resolve instead of
  // producing the diagnostic under test -- but it must not be *built*.
  // `testBuilders` derives the packages it builds from `sourceAssets` and reads
  // everything else from `readerWriter`, so the framework goes in the latter.
  // TODO: Can we cache and re-use this once per test suite?
  final readerWriter = TestReaderWriter(rootPackage: rootPackage);
  await for (final file in packages.findAssets(_ngFiles, package: ngPackage)) {
    readerWriter.testing.writeString(file, await packages.readAsString(file));
  }

  await runWithContext(
    // This is test-only code (just not in "test/").
    // ignore: invalid_use_of_visible_for_testing_member
    CompileContext.forTesting(),
    () {
      return withEnabledExperiments(
        () => testBuilders(
          builders,
          sourceAssets,
          rootPackage: rootPackage,
          generateFor: generateFor,
          readerWriter: readerWriter,
          onLog: onLog,
        ),
        ['non-nullable'],
      );
    },
  );
}

/// Returns a future that completes, asserting potential end states.
///
/// File [input] is treated as the primary input source. Additional
/// sources can be added via the [include] and [inputSource] properties:
/// ```
/// compilesExpect('...',
///   inputSource: 'pkg|lib/input.dart',
///   include: {
///     'pkg|lib/input.html': '...',
///     'pkg|lib/other.dart': '...',
///   }
/// )
/// ```
///
/// Note that `package:kelicap/**.dart` is always included.
Future<void> compilesExpecting(
  String input, {
  String? inputSource,
  Set<AssetId>? runBuilderOn,
  Map<String, String>? include,
  Object? /*Matcher|Iterable<Matcher>*/ errors,
  Object? /*Matcher|Iterable<Matcher>*/ warnings,
  Object? /*Matcher|Iterable<Matcher>*/ notices,
  Object? /*Matcher|Map<String, Matcher>*/ outputs,
}) async {
  // Default values.
  //
  // We do not use constructor defaults, because then we'd have to specify them
  // twice, once here, and again in 'compilesNormally' (+ additional times
  // wherever we want variants).
  inputSource ??= 'pkg|lib/input.dart';
  include ??= const {};

  // Complete list of input sources.
  final sources = <String, String>{inputSource: input}..addAll(include);

  // Run the builder.
  final records = <Level, List<LogRecord>>{};
  await _testBuilder(
    _testAngularBuilders,
    sources,
    runBuilderOn: runBuilderOn?.toList(),
    onLog: (record) {
      records.putIfAbsent(record.level, () => []).add(record);
    },
  );

  expectLogRecords(records[Level.SEVERE], errors, 'Errors');
  expectLogRecords(records[Level.WARNING], warnings, 'Warnings');
  expectLogRecords(records[Level.INFO], notices, 'Notices');

  if (outputs != null) {
    // TODO: Add an output verification or consider a golden file mechanism.
    throw UnimplementedError();
  }
}

void expectLogRecords(List<LogRecord>? logs, matcher, String reasonPrefix) {
  if (matcher == null) {
    return;
  }
  logs ??= [];
  expect(
    logs.map(formattedLogMessage),
    matcher,
    reason:
        '$reasonPrefix: \n${logs.map((l) => '${formattedLogMessage(l)} at:\n ${l.stackTrace}')}',
  );
}

String formattedLogMessage(LogRecord record) {
  var message = record.message;
  if (record.error != null) {
    message += '\nERROR: ${record.error}';
  }
  return message;
}

/// Returns a future that completes, asserting no errors or warnings occur.
///
/// An alias [compilesExpecting] with `errors` and `warnings` asserting empty.
Future<void> compilesNormally(
  String input, {
  String? inputSource,
  Map<String, String>? include,
  Set<AssetId>? runBuilderOn,
}) => compilesExpecting(
  input,
  inputSource: inputSource,
  runBuilderOn: runBuilderOn,
  include: include,
  errors: isEmpty,
  warnings: isEmpty,
);

/// Match for a source location, but don't require tests to manage package
/// names.
Matcher containsSourceLocation(int line, int column) =>
    contains('line $line, column $column of ');
