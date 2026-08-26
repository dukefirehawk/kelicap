import '../expression_parser/ast.dart' as ast;
import '../ir/model.dart' as ir;

bool isInterpolation(ir.BindingSource? source) =>
    source is ir.BoundExpression && source.expression.ast is ast.Interpolation;
