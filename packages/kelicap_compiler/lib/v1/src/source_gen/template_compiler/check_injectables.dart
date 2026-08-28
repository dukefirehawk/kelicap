import 'package:analyzer/dart/element/element.dart';

import '../../../../v2/context.dart';
import '../../../compiler.dart';

const DependencyReader dependencyReader = DependencyReader();

// TODO: try to inline
// Temporary replace for `resolveReflectables` which is also
// checks elements with `@Injectable()` annotation.
void checkInjectables(LibraryElement library) {
  for (var unit in allUnits(library)) {
    var clazz = unit.libraryFragment?.classes ?? [];
    for (var type in clazz) {
      checkClass(type.element);
      checkFunctions(type.element.methods);
    }

    var topLevelFunctions = unit.libraryFragment?.functions ?? [];
    checkFunctions(topLevelFunctions.map((e) => e.element));
  }
}

Iterable<Fragment> allUnits(LibraryElement library) sync* {
  yield library.firstFragment;
  yield* library.fragments;
}

void checkClass(ClassElement element) {
  if ($Injectable.hasAnnotationOfExact(element)) {
    if (element.isPrivate) {
      throw BuildError.forElement(
        element,
        'Private classes can not be @Injectable',
      );
    }

    dependencyReader.parseDependencies(element);
  }
}

void checkFunction(ExecutableElement element) {
  if ($Injectable.firstAnnotationOfExact(element) == null) {
    return;
  }

  if (!element.isStatic) {
    throw BuildError.forElement(
      element,
      'Non-static functions can not be @Injectable',
    );
  }

  if (element.isPrivate) {
    throw BuildError.forElement(
      element,
      'Private functions can not be @Injectable',
    );
  }

  dependencyReader.parseDependencies(element);
}

void checkFunctions(Iterable<ExecutableElement> elements) {
  for (var element in elements) {
    checkFunction(element);
  }
}
