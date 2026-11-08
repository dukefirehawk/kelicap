import 'package:string_scanner/string_scanner.dart';

import '../../exception_handler/exception_handler.dart';
import 'token.dart';

class NgMicroScanner {
  static final _findBeforeAssignment = RegExp(r':(\s*)');
  static final _findEndExpression = RegExp(r';\s*');
  // A key, such as `trackBy` in `trackBy: fn`, is a name directly followed by
  // `:`, unlike `a?b` in the conditional `a?b:c`.
  static final _findKey = RegExp(r'[a-zA-Z_$][\w$]*(?=:)');
  static final _findLetKeyword = RegExp(r'let(?=\s)');
  static final _findImplicitBind = RegExp(r'[^\s]+');
  static final _findLetAssignmentBefore = RegExp(r'\s*=\s*');
  static final _findLetIdentifier = RegExp(r'[^\s=;]+');
  static final _findWhitespace = RegExp(r'\s+');

  final StringScanner _scanner;
  late int _expressionOffset;
  late int _expressionLength;

  _NgMicroScannerState _state = _NgMicroScannerState.scanInitial;

  factory NgMicroScanner(String html, {sourceUrl}) {
    return NgMicroScanner._(StringScanner(html, sourceUrl: sourceUrl));
  }

  NgMicroScanner._(this._scanner) {
    _scanner.scan(_findWhitespace);
    _expressionOffset = _scanner.position;
    _expressionLength = _scanner.string.length - _expressionOffset;
  }

  NgMicroToken? scan() {
    switch (_state) {
      case _NgMicroScannerState.hasError:
        throw StateError('An error occurred');
      case _NgMicroScannerState.isEndOfFile:
        return null;
      case _NgMicroScannerState.scanAfterEndExpression:
        // A trailing `;` ends the expression, as in `let x of xs;`.
        if (_scanner.isDone) {
          _state = _NgMicroScannerState.isEndOfFile;
          return null;
        }
        return _scanInitial();
      case _NgMicroScannerState.scanAfterBindIdentifier:
        return _scanAfterBindIdentifier();
      case _NgMicroScannerState.scanAfterLetIdentifier:
        return _scanAfterLetIdentifier();
      case _NgMicroScannerState.scanAfterLetKeyword:
        return _scanAfterLetKeyword();
      case _NgMicroScannerState.scanBeforeBindExpression:
        return _scanBeforeBindExpression();
      case _NgMicroScannerState.scanBindExpression:
        return _scanBindExpression();
      case _NgMicroScannerState.scanEndExpression:
        return _scanEndExpression();
      case _NgMicroScannerState.scanImplicitBind:
        return _scanImplicitBind();
      case _NgMicroScannerState.scanInitial:
        return _scanInitial();
      case _NgMicroScannerState.scanLetAssignment:
        return _scanLetAssignment();
      case _NgMicroScannerState.scanLetIdentifier:
        return _scanLetIdentifier();
      //default:
      //  throw _unexpected();
    }
  }

  String _lexeme(int offset) => _scanner.substring(offset);

  NgMicroToken _scanAfterBindIdentifier() {
    var offset = _scanner.position;
    if (_scanner.scan(_findBeforeAssignment)) {
      _state = _NgMicroScannerState.scanBindExpression;
      return NgMicroToken.bindExpressionBefore(offset, _lexeme(offset));
    }
    throw _unexpected();
  }

  NgMicroToken _scanAfterLetIdentifier() {
    var offset = _scanner.position;
    if (_scanner.scan(_findEndExpression)) {
      _state = _NgMicroScannerState.scanAfterEndExpression;
      return NgMicroToken.endExpression(offset, _lexeme(offset));
    }
    if (_scanner.scan(_findLetAssignmentBefore)) {
      _state = _NgMicroScannerState.scanLetAssignment;
      return NgMicroToken.letAssignmentBefore(offset, _lexeme(offset));
    }
    if (_scanner.scan(_findWhitespace)) {
      _state = _NgMicroScannerState.scanImplicitBind;
      return NgMicroToken.endExpression(offset, _lexeme(offset));
    }
    throw _unexpected();
  }

  NgMicroToken _scanAfterLetKeyword() {
    var offset = _scanner.position;
    if (_scanner.scan(_findWhitespace)) {
      _state = _NgMicroScannerState.scanLetIdentifier;
      return NgMicroToken.letKeywordAfter(offset, _lexeme(offset));
    }
    throw _unexpected();
  }

  NgMicroToken _scanBeforeBindExpression() {
    var offset = _scanner.position;
    if (_scanner.scan(_findWhitespace)) {
      _state = _NgMicroScannerState.scanBindExpression;
      return NgMicroToken.bindExpressionBefore(offset, _lexeme(offset));
    }
    throw _unexpected();
  }

  NgMicroToken _scanBindExpression() {
    var offset = _scanner.position;
    if (_scanExpression()) {
      _state = _NgMicroScannerState.scanEndExpression;
      return NgMicroToken.bindExpression(offset, _lexeme(offset));
    }
    throw _unexpected();
  }

  /// Scans an expression, which ends at a `;` outside of its strings and
  /// brackets, as in `m['a;b']`, and returns whether it is not empty.
  bool _scanExpression() {
    final string = _scanner.string;
    final start = _scanner.position;
    String? quote;
    var depth = 0;
    var end = start;
    for (; end < string.length; end++) {
      final char = string[end];
      if (quote != null) {
        if (char == r'\') {
          end++;
        } else if (char == quote) {
          quote = null;
        }
      } else if (char == '"' || char == "'") {
        quote = char;
      } else if (char == '(' || char == '[' || char == '{') {
        depth++;
      } else if (char == ')' || char == ']' || char == '}') {
        depth--;
      } else if (char == ';' && depth <= 0) {
        break;
      }
    }
    // An escape at the end of the string may have passed it.
    if (end > string.length) end = string.length;
    if (end == start) return false;
    _scanner.position = end;
    return true;
  }

  NgMicroToken? _scanEndExpression() {
    if (_scanner.isDone) {
      _state = _NgMicroScannerState.isEndOfFile;
      return null;
    }
    var offset = _scanner.position;
    if (_scanner.scan(_findEndExpression)) {
      _state = _NgMicroScannerState.scanAfterEndExpression;
      return NgMicroToken.endExpression(offset, _lexeme(offset));
    }
    throw _unexpected();
  }

  NgMicroToken _scanImplicitBind() {
    var offset = _scanner.position;
    if (_scanner.scan(_findImplicitBind)) {
      _state = _NgMicroScannerState.scanBeforeBindExpression;
      return NgMicroToken.bindIdentifier(offset, _lexeme(offset));
    }
    throw _unexpected();
  }

  NgMicroToken _scanInitial() {
    var offset = _scanner.position;
    if (_scanner.scan(_findLetKeyword)) {
      _state = _NgMicroScannerState.scanAfterLetKeyword;
      return NgMicroToken.letKeyword(offset, _lexeme(offset));
    }
    if (_scanner.scan(_findKey)) {
      _state = _NgMicroScannerState.scanAfterBindIdentifier;
      return NgMicroToken.bindIdentifier(offset, _lexeme(offset));
    }
    // An expression bound to the directive, such as `a?b:c` or `f(a, b)`.
    if (_scanExpression()) {
      _state = _NgMicroScannerState.scanEndExpression;
      return NgMicroToken.bindExpression(offset, _lexeme(offset));
    }
    throw _unexpected();
  }

  NgMicroToken _scanLetAssignment() {
    var offset = _scanner.position;
    if (_scanExpression()) {
      _state = _NgMicroScannerState.scanEndExpression;
      return NgMicroToken.letAssignment(offset, _lexeme(offset));
    }
    throw _unexpected();
  }

  NgMicroToken _scanLetIdentifier() {
    var offset = _scanner.position;
    if (_scanner.scan(_findLetIdentifier)) {
      if (_scanner.isDone) {
        _state = _NgMicroScannerState.isEndOfFile;
      } else {
        _state = _NgMicroScannerState.scanAfterLetIdentifier;
      }
      return NgMicroToken.letIdentifier(offset, _lexeme(offset));
    }
    throw _unexpected();
  }

  KelicapParserException _unexpected() {
    _state = _NgMicroScannerState.hasError;
    return KelicapParserException(
      ParserErrorCode.invalidMicroExpression,
      _expressionOffset,
      _expressionLength,
    );
  }
}

enum _NgMicroScannerState {
  hasError,
  isEndOfFile,
  scanAfterEndExpression,
  scanAfterLetIdentifier,
  scanAfterLetKeyword,
  scanAfterBindIdentifier,
  scanBeforeBindExpression,
  scanBindExpression,
  scanEndExpression,
  scanImplicitBind,
  scanInitial,
  scanLetAssignment,
  scanLetIdentifier,
}
