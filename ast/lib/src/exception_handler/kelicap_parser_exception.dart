part of 'exception_handler.dart';

/// Exception class to be used in KelicapAst parser.
@sealed
class KelicapParserException extends Error {
  /// Length of error segment/token.
  final int? length;

  /// Reasoning for exception to be raised.
  final ParserErrorCode errorCode;

  /// Offset of where the exception was detected.
  final int? offset;

  KelicapParserException(this.errorCode, this.offset, this.length);

  @override
  bool operator ==(Object other) {
    return other is KelicapParserException &&
        errorCode == other.errorCode &&
        length == other.length &&
        offset == other.offset;
  }

  @override
  int get hashCode => Object.hash(errorCode, length, offset);

  @override
  String toString() => 'KelicapParserException{$errorCode}';
}
