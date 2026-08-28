import 'package:kelicap_common/kelicap_common.dart';

import '../analyzed_class.dart';
import '../compile_metadata.dart';
import '../ir/model.dart' as ir;
import '../optimize_ir/merge_events.dart';
import 'binding_converter.dart';
import '../template_ast.dart' as ast;
import '../view_compiler/compile_element.dart';
import '../view_compiler/ir/provider_source.dart';

/// Converts a list of [ast.DirectiveAst] nodes into [ir.MatchedDirective]
/// instances.
///
/// [CompileElement] represents the element in the template that the directive
/// has matched.
///
/// [AnalyzedClass] represents the Component class that is currently being
/// compiled.
List<ir.MatchedDirective> convertMatchedDirectives(
  Iterable<ast.DirectiveAst> directives,
  CompileElement compileElement,
  CompileDirectiveMetadata compileDirectiveMetadata,
) {
  final matchedDirectives = <ir.MatchedDirective>[];
  var index = -1;
  for (var directive in directives) {
    index++;
    var providerSource = compileElement.directiveInstances[index];
    matchedDirectives.add(
      convertMatchedDirective(
        directive,
        providerSource,
        compileElement,
        compileDirectiveMetadata,
      ),
    );
  }
  return matchedDirectives;
}

/// Converts a single [ast.DirectiveAst] node into a [ir.MatchedDirective]
/// instance.
///
/// [ProviderSource] represents the underlying Directive instance that has been
/// matched.
///
/// [CompileElement] represents the element in the template that the directive
/// has matched.
///
/// [AnalyzedClass] represents the Component class that is currently being
/// compiled.
ir.MatchedDirective convertMatchedDirective(
  ast.DirectiveAst directive,
  ProviderSource? providerSource,
  CompileElement compileElement,
  CompileDirectiveMetadata compileDirectiveMetadata,
) {
  var inputs = convertAllToBinding(
    directive.inputs,
    directive: directive.directive,
    compileDirectiveMetadata: compileDirectiveMetadata,
    compileElement: compileElement,
  );

  var outputs = convertAllToBinding(
    directive.outputs,
    directive: directive.directive,
    compileDirectiveMetadata: compileDirectiveMetadata,
    compileElement: compileElement,
  );
  outputs = mergeEvents(outputs);

  return ir.MatchedDirective(
    providerSource: providerSource,
    inputs: inputs,
    outputs: outputs,
    hasInputs: directive.directive.inputs.isNotEmpty,
    hasHostProperties: directive.hasHostProperties,
    isComponent: directive.directive.isComponent,
    isOnPush:
        directive.directive.changeDetection == ChangeDetectionStrategy.onPush,
    lifecycles: _lifecycles(directive.directive),
  );
}

Set<ir.Lifecycle> _lifecycles(CompileDirectiveMetadata directive) => ir
    .Lifecycle
    .values
    .where(
      (lifecycle) =>
          directive.lifecycleHooks.contains(_lifecyclesAsIr[lifecycle]),
    )
    .toSet();

const _lifecyclesAsIr = {
  ir.Lifecycle.afterChanges: LifecycleHooks.afterChanges,
  ir.Lifecycle.onInit: LifecycleHooks.onInit,
  ir.Lifecycle.doCheck: LifecycleHooks.doCheck,
  ir.Lifecycle.afterContentInit: LifecycleHooks.afterContentInit,
  ir.Lifecycle.afterContentChecked: LifecycleHooks.afterContentChecked,
  ir.Lifecycle.afterViewInit: LifecycleHooks.afterViewInit,
  ir.Lifecycle.afterViewChecked: LifecycleHooks.afterViewChecked,
  ir.Lifecycle.onDestroy: LifecycleHooks.onDestroy,
};
