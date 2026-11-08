import '../ast.dart';
import '../exception_handler/exception_handler.dart';
import '../expression/micro.dart';
import '../visitor.dart';

/// Desugars complex nodes such as `[(banana)]` into simpler forms.
///
/// Ignores non-desugrable nodes. This visitor mutates and returns the AST where
/// the original node can be accessed by [SyntheticTemplateAst.origin].
class DesugarVisitor extends IdentityTemplateAstVisitor<void>
    implements TemplateAstVisitor<TemplateAst, void> {
  final ExceptionHandler exceptionHandler;

  /// Create a new visitor.
  DesugarVisitor({ExceptionHandler? exceptionHandler})
    : exceptionHandler = exceptionHandler ?? const ThrowingExceptionHandler();

  @override
  TemplateAst visitContainer(ContainerAst astNode, [_]) {
    astNode = _growableContainer(astNode);
    _visitChildren(astNode);

    if (astNode.stars.isNotEmpty) {
      return _desugarStar(astNode, astNode.stars);
    }

    return astNode;
  }

  @override
  TemplateAst visitElement(ElementAst astNode, [_]) {
    astNode = _growableElement(astNode);
    _visitChildren(astNode);
    if (astNode.bananas.isNotEmpty) {
      _desugarBananas(astNode);
    }
    if (astNode.stars.isNotEmpty) {
      return _desugarStar(astNode, astNode.stars);
    }
    return astNode;
  }

  void _visitChildren(TemplateAst astNode) {
    if (astNode.childNodes.isEmpty) return;
    var newChildren = <StandaloneTemplateAst>[];
    for (var child in astNode.childNodes) {
      newChildren.add(child.accept(this) as StandaloneTemplateAst);
    }
    astNode.childNodes.clear();
    astNode.childNodes.addAll(newChildren);
  }

  @override
  TemplateAst visitEmbeddedContent(EmbeddedContentAst astNode, [_]) => astNode;

  @override
  TemplateAst visitEmbeddedTemplate(EmbeddedTemplateAst astNode, [_]) {
    astNode = _growableTemplate(astNode);
    _visitChildren(astNode);
    return astNode;
  }

  /// Rewrites each banana on [astNode] as an event, property binding pair.
  ///
  /// For example, the banana binding
  ///
  ///     [(foo)]="bar"
  ///
  /// is rewritten as the property binding
  ///
  ///     [foo]="bar"
  ///
  /// and the event binding
  ///
  ///     (fooChange)="bar = $event"
  ///
  /// This clears any banana bindings from [astNode].
  void _desugarBananas(ElementAst astNode) {
    for (var banana in astNode.bananas) {
      if (banana.value == null || banana.value!.trim().isEmpty) {
        // A synthetic banana has no source to report an error at.
        if (!banana.isSynthetic) {
          exceptionHandler.handle(
            KelicapParserException(
              ParserErrorCode.bananaMissingValue,
              banana.sourceSpan.start.offset,
              banana.sourceSpan.length,
            ),
          );
        }
        continue;
      }
      astNode
        ..events.add(
          EventAst.from(
            banana,
            '${banana.name}Change',
            '${banana.value} = \$event',
          ),
        )
        ..properties.add(PropertyAst.from(banana, banana.name, banana.value!));
    }
    astNode.bananas.clear();
  }

  TemplateAst _desugarStar(StandaloneTemplateAst astNode, List<StarAst> stars) {
    var starAst = stars[0];
    var origin = starAst;
    var starExpression = starAst.value?.trim();
    // A synthetic star, such as one created in a test, has no source.
    var expressionOffset = starAst is ParsedStarAst
        ? starAst.valueToken?.innerValue?.offset
        : 0;
    var directiveName = starAst.name;
    EmbeddedTemplateAst newAst;
    var attributesToAdd = <AttributeAst>[];
    var propertiesToAdd = <PropertyAst>[];
    var letBindingsToAdd = <LetBindingAst>[];

    if (isMicroExpression(starExpression)) {
      NgMicroAst micro;
      try {
        micro = parseMicroExpression(
          directiveName,
          starExpression,
          expressionOffset,
          sourceUrl: _sourceUrl(astNode),
          origin: origin,
        );
      } on KelicapParserException catch (e) {
        exceptionHandler.handle(e);
        return astNode;
      }
      propertiesToAdd.addAll(micro.properties);
      letBindingsToAdd.addAll(micro.letBindings);
      // If the micro-syntax did not produce a binding to the left-hand side
      // property, add it as an attribute in case a directive selector
      // depends on it.
      if (!propertiesToAdd.any((p) => p.name == directiveName)) {
        attributesToAdd.add(AttributeAst.from(origin, directiveName));
      }
      newAst = EmbeddedTemplateAst.from(
        origin,
        childNodes: [astNode],
        attributes: attributesToAdd,
        properties: propertiesToAdd,
        letBindings: letBindingsToAdd,
      );
    } else {
      if (starExpression == null) {
        // In the rare case the *-binding has no RHS expression, add the LHS
        // as an attribute rather than a property. This allows matching a
        // directive with an attribute selector, but no input of the same
        // name.
        attributesToAdd.add(AttributeAst.from(origin, directiveName));
      } else {
        propertiesToAdd.add(
          PropertyAst.from(origin, directiveName, starExpression),
        );
      }
      newAst = EmbeddedTemplateAst.from(
        origin,
        childNodes: [astNode],
        attributes: attributesToAdd,
        properties: propertiesToAdd,
      );
    }

    stars.clear();
    return newAst;
  }

  // Desugaring changes the lists of a node in place. Those of a synthetic node,
  // such as one created in a test, may be constant, so such a node is copied
  // with growable lists, keeping its origin.

  static ElementAst _growableElement(ElementAst node) {
    if (node is! SyntheticTemplateAst) return node;
    final origin = (node as SyntheticTemplateAst).origin;
    return origin == null
        ? ElementAst(
            node.name,
            node.closeComplement,
            attributes: [...node.attributes],
            childNodes: [...node.childNodes],
            events: [...node.events],
            properties: [...node.properties],
            references: [...node.references],
            bananas: [...node.bananas],
            stars: [...node.stars],
            annotations: [...node.annotations],
          )
        : ElementAst.from(
            origin,
            node.name,
            node.closeComplement,
            attributes: [...node.attributes],
            childNodes: [...node.childNodes],
            events: [...node.events],
            properties: [...node.properties],
            references: [...node.references],
            bananas: [...node.bananas],
            stars: [...node.stars],
            annotations: [...node.annotations],
          );
  }

  static ContainerAst _growableContainer(ContainerAst node) {
    if (node is! SyntheticTemplateAst) return node;
    final origin = (node as SyntheticTemplateAst).origin;
    final copy = origin == null
        ? ContainerAst(
            annotations: [...node.annotations],
            childNodes: [...node.childNodes],
            stars: [...node.stars],
          )
        : ContainerAst.from(
            origin,
            annotations: [...node.annotations],
            childNodes: [...node.childNodes],
            stars: [...node.stars],
          );
    // Such as the close tag of a dangling `</ng-container>`, recovered.
    return copy..closeComplement = node.closeComplement;
  }

  static EmbeddedTemplateAst _growableTemplate(EmbeddedTemplateAst node) {
    if (node is! SyntheticTemplateAst) return node;
    final origin = (node as SyntheticTemplateAst).origin;
    final copy = origin == null
        ? EmbeddedTemplateAst(
            annotations: [...node.annotations],
            attributes: [...node.attributes],
            childNodes: [...node.childNodes],
            events: [...node.events],
            properties: [...node.properties],
            references: [...node.references],
            letBindings: [...node.letBindings],
          )
        : EmbeddedTemplateAst.from(
            origin,
            annotations: [...node.annotations],
            attributes: [...node.attributes],
            childNodes: [...node.childNodes],
            events: [...node.events],
            properties: [...node.properties],
            references: [...node.references],
            letBindings: [...node.letBindings],
          );
    return copy..closeComplement = node.closeComplement;
  }

  /// The URL of [astNode]'s source, which a synthetic node may not have.
  static String _sourceUrl(TemplateAst astNode) {
    if (astNode is SyntheticTemplateAst && astNode.origin == null) return '';
    return astNode.sourceUrl ?? '';
  }
}
