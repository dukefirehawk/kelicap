import '../../meta/directives.dart';

/// Implements uppercase transforms to text.
@Pipe('uppercase')
class UpperCasePipe {
  String? transform(String? value) => value?.toUpperCase();

  const UpperCasePipe();
}
