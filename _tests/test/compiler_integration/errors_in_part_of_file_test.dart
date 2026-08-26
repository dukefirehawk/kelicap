import 'package:test/test.dart';

// ignore: avoid_relative_lib_imports
import '../../lib/compiler.dart';

import '../../../packages/kelicap_compiler/lib/v2/context.dart';

void main() {
  CompileContext.overrideForTesting();

  test(
    'should throw meaningful error message if it is in part of dart file',
    () async {
      await compilesExpecting(
        """
      import '$ngImport';

      part 'rest.dart';

      @Component(
        selector: 'major',
        template: '',
      )
      class MajorComp {}
    """,
        include: {
          'pkg|lib/rest.dart': """
        part of 'input.dart';

        @Component(
          selector: 'rest',
          template: '',
          styleUrls: ['rest.scss'],
        )
        class RestComp {}
        """,
        },
        errors: [
          allOf(
            contains('Unsupported extension in styleUrls:'),
            contains('Only ".css" is supported'),
          ),
        ],
      );
    },
  );
}
