import 'package:meta/meta.dart';

part 'kelicap_parser_exception.dart';
part 'exceptions.dart';

abstract class ExceptionHandler {
  void handle(KelicapParserException? e);
}

@sealed
class ThrowingExceptionHandler implements ExceptionHandler {
  @override
  void handle(KelicapParserException? e) {
    if (e != null) {
      throw e;
    }
  }

  @literal
  const ThrowingExceptionHandler();
}

class RecoveringExceptionHandler implements ExceptionHandler {
  final exceptions = <KelicapParserException>[];

  @override
  void handle(KelicapParserException? e) {
    if (e != null) {
      exceptions.add(e);
    }
  }
}
