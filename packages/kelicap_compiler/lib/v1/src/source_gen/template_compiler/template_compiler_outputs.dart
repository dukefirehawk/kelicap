import '../../../compiler.dart';
import '../../compiler/source_module.dart';

/// Elements of a `.template.dart` file to be written to disk.
class TemplateCompilerOutputs {
  /// For each `@GenerateInjector`, how to generate those injectors.
  final List<InjectorReader> injectorsOutput;

  /// For each `@Component`, how to generate the backing views.
  final DartSourceOutput? templateSource;

  const TemplateCompilerOutputs(this.templateSource, this.injectorsOutput);
}
