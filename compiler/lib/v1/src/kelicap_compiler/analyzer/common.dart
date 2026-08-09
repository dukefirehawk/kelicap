import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:source_gen/src/utils.dart';

/// Returns the import URL for [type].
String getTypeImport(DartType type) {
  var aliasElement = type.alias?.element;
  if (aliasElement != null) {
    return normalizeUrl(
      aliasElement.library.firstFragment.source.uri,
    ).toString();
  }
  if (type is DynamicType) {
    return 'dart:core';
  }
  if (type is InterfaceType) {
    return normalizeUrl(
      type.element.library.firstFragment.source.uri,
    ).toString();
  }
  throw UnimplementedError('(${type.runtimeType}) $type');
}

/// Forwards and backwards-compatible method of getting the "name" of [type].
String? getTypeName(DartType? type) {
  var aliasElement = type?.alias?.element;
  if (aliasElement != null) {
    return aliasElement.name;
  }
  if (type is DynamicType) {
    return 'dynamic';
  }
  if (type is FunctionType) {
    return null;
  }
  if (type is InterfaceType) {
    return type.element.name;
  }
  if (type is VoidType) {
    return 'void';
  }
  throw UnimplementedError('(${type.runtimeType}) $type');
}

/// Returns the type of the constant [object], without extension type erasure.
///
/// The analyzer's constant evaluator erases extension types: for
/// `const OpaqueToken<HTMLElement>(...)`, `DartObject.type` reports
/// `OpaqueToken<JSObject>`, because `JSObject` is `HTMLElement`'s representation
/// type. That is right for constant *identity*, but wrong for code generation.
/// `JSObject` is declared in `dart:_interceptors` (`dart:js_interop` only
/// re-exports it), so emitting it puts a private SDK import into the generated
/// `.template.dart`. `build_web_compilers` treats any library importing a
/// `dart:_` library as non-importable, and then silently skips every entrypoint
/// that transitively reaches it -- for both ddc and dart2js -- reporting an
/// *empty* list of offending libraries, because the library it wants to name is
/// exactly the one it could not write a `.module.library` for.
///
/// Use this wherever the result is emitted as a *reference*: a token, or a type
/// argument. Sites that need a constructible class -- anything that casts the
/// element to `ClassElement` -- must keep using [DartObject.type], since an
/// extension type has an `ExtensionTypeElement`, not a `ClassElement`.
///
/// The accessor is `@experimental`, but it is the API the analyzer added for
/// precisely this case -- see the comment on `TypeState.typeNotExtensionTypeErased`
/// in `analyzer/lib/src/dart/constant/value.dart`. Confining the use to this one
/// function keeps the blast radius to a single line if it is ever renamed.
DartType? unerasedTypeOf(DartObject object) =>
    // ignore: experimental_member_use
    object.typeNotExtensionTypeErased ?? object.type;

/// Returns the `Type` value of the constant [object], without extension type
/// erasure.
///
/// The [unerasedTypeOf] problem, but for `Type` literal tokens such as the
/// `Window` in `FactoryProvider(Window, getWindow)`, which otherwise reaches
/// codegen as `JSObject`. Note that erasure also collapses `Document`, `Window`
/// and `Location` onto the *same* token, so two providers in one injector become
/// indistinguishable `identical(token, JSObject)` branches.
DartType? unerasedTypeValueOf(DartObject object) =>
    // ignore: experimental_member_use
    object.toTypeValueNotExtensionTypeErased() ?? object.toTypeValue();

/// Returns the bound [DartType] from the instance [object].
///
/// For example for the following code:
/// ```
/// const foo = const <String>[];
/// const bar = const ['A string'];
/// ```
///
/// ... both `foo` and `bar` should return the [DartType] for `String`.
DartType typeArgumentOf(DartObject object, [int index = 0]) {
  var type = object.type;
  if (type is ParameterizedType) {
    var typeArguments = type.typeArguments;
    if (typeArguments.isNotEmpty) {
      return type.typeArguments[index];
    }
  }
  return DynamicTypeImpl.instance;
}

String? typeToCode(DartType? type) {
  if (type == null) {
    return null;
  } else if (type is DynamicType) {
    return 'dynamic';
  } else if (type is InterfaceType) {
    var typeArguments = type.typeArguments;
    if (typeArguments.isEmpty) {
      return type.element.name;
    } else {
      final typeArgumentsStr = typeArguments.map(typeToCode).join(', ');
      return '${type.element.name}<$typeArgumentsStr>';
    }
  } else if (type is TypeParameterType) {
    return type.element.name;
  } else if (type is VoidType) {
    return 'void';
  } else {
    throw UnimplementedError('(${type.runtimeType}) $type');
  }
}

/// Returns a canonical URL pointing to [element].
///
/// For example:
///  * `List` would be `'dart:core#List'`,
///  * `Duration.zero` would be `'dart:core#Duration.zero'`.
Uri urlOf(Element? element, [String? name]) {
  if (element?.library?.firstFragment.source == null) {
    return Uri(scheme: 'dart', path: 'core', fragment: 'dynamic');
  }

  var fragment = name ?? element!.name;

  // ORI: final enclosing = element!.enclosingElement;
  final enclosing = element!.enclosingElement;
  if (enclosing is ClassElement) {
    fragment = '${enclosing.name}.$fragment';
  }

  // NOTE: element.source.uri might be a file that is not importable (i.e. is
  // a "part"), while element.library.source.uri is always importable.
  return normalizeUrl(
    element.library!.firstFragment.source.uri,
  ).replace(fragment: fragment);
}
