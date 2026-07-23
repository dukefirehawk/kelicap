import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:meta/meta.dart';
import 'package:source_gen/source_gen.dart';
import 'package:kelicap_compiler/v2/context.dart';

import '../types.dart';

/// Utility class for visiting important methods and fields in an `@Directive`.
///
/// **NOTE**: This code is transitional, as much of the view compiler code lives
/// currently within the `Kelicap` package. As such, this helps, but does not
/// completely implement compiler logic.
class DirectiveVisitor {
  static void _noopClassMember(Element _, DartObject _) {}
  static void _noopClassMethod(MethodElement _, DartObject _) {}

  /// Invoked for every _valid_ member annotated with `@HostBinding`.
  ///
  /// Invalid annotations are rejected and throw a compile-time error.
  @protected
  final void Function(Element, DartObject) onHostBinding;

  /// Invoked for every _valid_ member annotated with `@HostListener`.
  ///
  /// Invalid annotations are rejected and throw a compile-time error.
  @protected
  final void Function(MethodElement, DartObject) onHostListener;

  const DirectiveVisitor({
    this.onHostBinding = _noopClassMember,
    this.onHostListener = _noopClassMethod,
  });

  /// Throws a [BuildError] if [element] is not an instance-level member.
  static void _assertInstance(Element element, String message) {
    //if (element is ClassMemberElement && !element.isStatic) {
    //if (element is PropertyAccessorElement && !element.isStatic) {
    if (element is MethodElement && !element.isStatic) {
      return;
    }
    throw BuildError.forElement(element, message);
  }

  /// Throws a [BuildError] if [element] is not publicly accessible.
  static void _assertPublic(Element element, String message) {
    if (element.isPublic) {
      return;
    }
    throw BuildError.forElement(element, message);
  }

  static bool _isRequired(FormalParameterElement e) => e.isRequiredPositional;

  static void _assertExactArgs(Element element, String message, int exactArgs) {
    if (element is MethodElement &&
        element.formalParameters.where(_isRequired).length != exactArgs) {
      throw BuildError.forElement(element, message);
    }
  }

  /// Visits an `@Directive`-annotated class [element].
  ///
  /// For class members that are annotated, calls, in kind:
  /// * [onHostBinding]
  /// * [onHostListener]
  ///
  /// **NOTE**: There is no verification [element] has the annotation.
  void visitDirective(ClassFragment fragment) {
    for (final superType in fragment.element.allSupertypes.reversed) {
      _visitDirectiveOrSupertype(superType.element);
    }
    _visitDirectiveOrSupertype(fragment.element);
  }

  void _visitDirectiveOrSupertype(InterfaceElement element) {
    for (final accessor in element.getters) {
      _visitMember(accessor);
    }
    for (final accessor in element.setters) {
      _visitMember(accessor);
    }
    for (final method in element.methods) {
      _visitMember(method);
    }
    for (final field in element.fields) {
      _visitMember(field);
    }
  }

  void _visitMember(Element member) {
    for (final hostBinding in $HostBinding.annotationsOfExact(
      member,
      throwOnUnresolved: false,
    )) {
      _visitHostBinding(member, hostBinding);
    }
    for (final hostListener in $HostListener.annotationsOfExact(
      member,
      throwOnUnresolved: false,
    )) {
      _visitHostListener(member, hostListener);
    }
  }

  void _visitHostBinding(Element member, DartObject annotation) {
    _assertPublic(member, '@HostBinding must be on a public member');
    onHostBinding(member, annotation);
  }

  void _visitHostListener(Element member, DartObject annotation) {
    _assertInstance(member, '@HostListener must be on a non-static member');
    _assertPublic(member, '@HostListener must be on a public member');

    final hostListenerArgs = ConstantReader(annotation).read('args');
    if (hostListenerArgs.isList) {
      final inferredParamCount = hostListenerArgs.listValue.length;
      _assertExactArgs(
        member,
        '@HostListener expected a method with $inferredParamCount parameter(s)',
        inferredParamCount,
      );
    }

    onHostListener(member as MethodElement, annotation);
  }
}
