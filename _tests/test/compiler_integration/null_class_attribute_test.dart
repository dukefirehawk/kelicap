import 'package:test/test.dart';

// ignore: avoid_relative_lib_imports
import '../../lib/compiler.dart';

import '../../../packages/kelicap_compiler/lib/v2/context.dart';

void main() {
  CompileContext.overrideForTesting();

  test('should not crash on null class names', () async {
    await compilesNormally("""
      import '$ngImport';

      @Component(
        selector: 'null-class',
        template: '<div class></div>',
      )
      class NullClassComponent {}
    """);
  });
}
