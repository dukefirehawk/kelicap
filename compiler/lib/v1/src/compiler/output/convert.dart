import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:kelicap_compiler/v1/compiler.dart';
import 'package:kelicap_compiler/v1/src/source_gen/common/url_resolver.dart';
import 'package:source_gen/source_gen.dart';

import '../compile_metadata.dart';
import 'output_ast.dart' as o;

/// Creates an AST for code generation from [dartType].
///
/// If [resolveBounds] is false, type parameters will not be resolved to their
/// bound.
///
/// Note that private types aren't visible to generated code and will be
/// replaced with dynamic.
o.OutputType? fromDartType(DartType? dartType, {bool resolveBounds = true}) {
  if (dartType == null) {
    // Some analyzer APIs may return a null `DartType` to signify the absence of
    // an explicit type, such as a generic type parameter bound.
    return null;
  }
  if (dartType is VoidType) {
    return o.voidType;
  }
  if (dartType.isDartCoreNull) {
    return o.nullType;
  }
  if (dartType is NeverType) {
    return o.neverType;
  }
  if (dartType is FunctionType) {
    return fromFunctionType(dartType);
  }
  if (dartType.element!.isPrivate) {
    return o.dynamicType;
  }
  if (dartType is TypeParameterType && resolveBounds) {
    // Resolve generic type to its bound or dynamic if it has none.
    //
    // `resolveToBound` moved from `DartType` to `TypeSystem`, and now takes the
    // type to resolve rather than the bound to fall back to. Passing the
    // fallback, as this used to, resolves `dynamic` to itself and so collapsed
    // *every* type parameter to `dynamic`. An unbounded type parameter resolves
    // to `Object?` there, so keep falling back to `dynamic` explicitly to
    // preserve the original behaviour.
    final library = dartType.element.library!;
    dartType = dartType.element.bound == null
        ? library.typeProvider.dynamicType
        : library.typeSystem.resolveToBound(dartType);
  }
  // Note this check for dynamic should come after the check for a type
  // parameter, since a type parameter could resolve to dynamic.
  if (dartType is DynamicType) {
    return o.dynamicType;
  }
  final typeArguments = <o.OutputType>[];
  if (dartType is ParameterizedType) {
    for (final typeArgument in dartType.typeArguments) {
      if (typeArgument is TypeParameterType && resolveBounds) {
        // Temporary hack to avoid a stack overflow for <T extends List<T>>.
        //
        typeArguments.add(o.dynamicType);
      } else {
        typeArguments.add(fromDartType(typeArgument, resolveBounds: false)!);
      }
    }
  }
  var outputType = o.ExternalType(
    CompileIdentifierMetadata(
      name: dartType.element?.name ?? dartType.getDisplayString(),
      moduleUrl: moduleUrl(dartType.element!),
      // Most o.ExternalTypes are not created, but those that are (like
      // OpaqueToken<...> need this generic type.
      typeArguments: typeArguments,
    ),
    typeArguments,
  );
  if (dartType.nullabilitySuffix == NullabilitySuffix.question) {
    outputType = outputType.asNullable();
  }
  return outputType;
}

/// Creates an AST from code generation from [typeLink].
o.OutputType fromTypeLink(TypeLink? typeLink, LibraryReader library) {
  if (typeLink == null || typeLink.isDynamic || typeLink.isPrivate) {
    return o.dynamicType;
  }
  var typeArguments = <o.OutputType>[];
  for (var i = 0; i < typeLink.generics.length; i++) {
    typeArguments.add(fromTypeLink(typeLink.generics[i], library));
  }
  // When `typeLink` represents a type parameter, it doesn't require an import.
  final importUrl = typeLink.import != null
      ? library.pathToUrl(typeLink.import).toString()
      : null;
  var outputType = o.ExternalType(
    CompileIdentifierMetadata(
      name: typeLink.symbol,
      moduleUrl: importUrl,
      typeArguments: typeArguments,
    ),
    typeArguments,
  );
  if (typeLink.isNullable) {
    outputType = outputType.asNullable();
  }
  return outputType;
}

/// Creates an AST for code generation from [functionType]
o.FunctionType fromFunctionType(FunctionType functionType) {
  final returnType = fromDartType(functionType.returnType);
  final paramTypes = <o.OutputType>[];
  for (var parameter in functionType.formalParameters) {
    paramTypes.add(fromDartType(parameter.type)!);
  }
  var outputType = o.FunctionType(returnType, paramTypes);
  if (functionType.nullabilitySuffix == NullabilitySuffix.question) {
    outputType = outputType.asNullable();
  }
  return outputType;
}
