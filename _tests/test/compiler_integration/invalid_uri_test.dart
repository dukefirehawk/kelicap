import 'package:test/test.dart';
// ignore: avoid_relative_lib_imports
import '../../lib/compiler.dart';
import 'package:kelicap_compiler/v2/context.dart';

void main() {
  CompileContext.overrideForTesting();

  test('should ignore on unrecognized import URLs', () async {
    await compilesNormally("""
      import 'dart:badpackage/bad.dart';
    """);
  });

  test('should ignore on unrecognized export URLs', () async {
    await compilesNormally("""
      export 'dart:badpackage/bad.dart';
    """);
  });

  test('should ignore on unrecognized part URLs', () async {
    await compilesNormally("""
      part 'dart:badpackage/bad.dart';
    """);
  });
}
