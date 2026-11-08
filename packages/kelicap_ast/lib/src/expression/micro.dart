import '../ast.dart';
import 'micro/ast.dart';
import 'micro/parser.dart';

export 'micro/ast.dart' show NgMicroAst;

/// `let` as a keyword, followed by the name of a variable, unlike `letter` or
/// `let + 1`, which use an identifier that begins with or is `let`.
final _isLet = RegExp(r'let\s+[a-zA-Z_$]');

/// Returns whether [expression] is a special Kelicap *-star expression.
///
/// This means it won't parse correctly with the standard expression parser, and
/// [parseMicroExpression] is needed to de-sugar the expression into its
/// multiple intents.
bool isMicroExpression(String? expression) =>
    expression != null &&
    (expression.startsWith(_isLet) || _startsWithBinding(expression));

/// Returns whether [expression] has a `:` or a `;` that ends a micro-syntax key
/// or expression, before any whitespace, as the first one cannot contain any.
///
/// One inside a string or brackets is part of an expression, such as
/// `map['a:b']` or `check(x: 1)`, and a `:` can be part of a conditional, such
/// as `a?b:c`.
bool _startsWithBinding(String expression) {
  String? quote;
  var depth = 0;
  var conditionals = 0;
  for (var i = 0; i < expression.length; i++) {
    final char = expression[i];
    if (_whitespace.hasMatch(char)) return false;
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
      case '?' when depth == 0:
        // `?.` and `??` are operators of their own, not conditionals.
        final next = i + 1 < expression.length ? expression[i + 1] : '';
        if (next == '.' || next == '?') {
          i++;
        } else {
          conditionals++;
        }
      case ':' when depth == 0 && conditionals > 0:
        conditionals--;
      case ':' || ';' when depth == 0 && i > 0:
        return true;
    }
  }
  return false;
}

final _whitespace = RegExp(r'\s');

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
