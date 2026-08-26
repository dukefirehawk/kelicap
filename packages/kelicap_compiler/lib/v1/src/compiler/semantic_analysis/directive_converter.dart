import 'package:source_span/source_span.dart';

import '../compile_metadata.dart';
import '../expression_parser/ast.dart' as ast;
import '../ir/model.dart' as ir;
import '../schema/element_schema_registry.dart';
import 'binding_converter.dart';
import '../template_ast.dart' as ast;
import '../template_parser.dart';

/// Converts [CompileDirectiveMetadata] objects into
/// [ir.Directive] instances.
///
/// This is part of the semantic analysis phase of the Kelicap compiler.
class DirectiveConverter {
  final ElementSchemaRegistry _schemaRegistry;

  DirectiveConverter(this._schemaRegistry);

  ir.Directive convertDirectiveToIR(CompileDirectiveMetadata directiveMeta) =>
      ir.Directive(
        name: directiveMeta.identifier!.name,
        typeParameters: directiveMeta.originType!.typeParameters,
        hostProperties: _hostProperties(
          directiveMeta.hostProperties,
          directiveMeta,
        ),
        metadata: directiveMeta,
      );

  List<ir.Binding> _hostProperties(
    Map<String, ast.AST> hostProps,
    CompileDirectiveMetadata? compileDirectiveMetadata,
  ) {
    // TODO(b/130184376): Create better HostProperties representation in
    //  CompileMetadata.
    final hostProperties = hostProps.entries.map((entry) {
      final property = entry.key;
      final expression = entry.value;
      return createElementPropertyAst(
        _securityContextElementName,
        property,
        ast.BoundExpression(ast.ASTWithSource.missingSource(expression)),
        _emptySpan,
        _schemaRegistry,
      );
    }).toList();

    return convertAllToBinding(
      hostProperties,
      compileDirectiveMetadata: compileDirectiveMetadata,
    );
  }

  static const _securityContextElementName = 'div';
  static final _emptySpan = SourceSpan(
    SourceLocation(0),
    SourceLocation(0),
    '',
  );
}
