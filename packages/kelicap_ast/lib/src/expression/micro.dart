import '../ast.dart';
import 'micro/ast.dart';
import 'micro/parser.dart';

export 'micro/ast.dart' show NgMicroAst;

/// `let` as a keyword, followed by the name of a variable, unlike `letter` or
/// `let + 1`, which use an identifier that begins with or is `let`.
final _isLet = RegExp(r'let\s+[a-zA-Z_$]');

/// A key, such as `trackBy` in `trackBy: fn`, is a name directly followed by
/// `:`, unlike `a?b` in the conditional `a?b:c`.
final _isKey = RegExp(r'[a-zA-Z_$][\w$]*:');

/// Returns whether [expression] is a special Kelicap *-star expression.
///
/// This means it won't parse correctly with the standard expression parser, and
/// [parseMicroExpression] is needed to de-sugar the expression into its
/// multiple intents.
bool isMicroExpression(String? expression) =>
    expression != null &&
    (expression.startsWith(_isLet) ||
        expression.startsWith(_isKey) ||
        _hasSeparator(expression));

/// Returns whether [expression] has a `;` that separates micro-syntax, which no
/// expression has, after the start.
///
/// One inside a string or brackets is part of an expression, such as
/// `map['a;b']`, which may also have whitespace, such as `f(a, b); let x`.
bool _hasSeparator(String expression) {
  String? quote;
  var depth = 0;
  for (var i = 0; i < expression.length; i++) {
    final char = expression[i];
    if (quote != null) {
      if (char == r'\') {
        i++;
      } else if (char == quote) {
        quote = null;
      }
      continue;
    }
    switch (char) {
      case '"' || "'":
        quote = char;
      case '(' || '[' || '{':
        depth++;
      case ')' || ']' || '}':
        depth--;
      case ';' when depth <= 0 && expression.substring(0, i).trim().isNotEmpty:
        return true;
    }
  }
  return false;
}

/// Returns a de-sugared micro AST from [expression].
NgMicroAst parseMicroExpression(
  String directive,
  String? expression,
  int? expressionOffset, {
  required String sourceUrl,
  TemplateAst? origin,
}) => const NgMicroParser().parse(
  directive,
  expression,
  expressionOffset,
  sourceUrl: sourceUrl,
  origin: origin,
);
