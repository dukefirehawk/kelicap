import '../expression_parser/ast.dart';
import 'constants.dart';

enum HandlerType { simpleNoArgs, simpleOneArg, notSimple }

/// Classifies this event binding by it's form.
///
/// The simple form looks like
///
///     (event)="handler($event)"
///
/// or
///
///     (event)="handler()"
///
/// Since these types of handlers are so common, we can optimize the code
/// generated for them.
HandlerType handlerTypeFromExpression(AST handler) {
  var eventHandler = handler;
  if (eventHandler is! MethodCall) {
    return HandlerType.notSimple;
  }
  var call = eventHandler;
  if (call.receiver is! ImplicitReceiver || call.namedArgs.isNotEmpty) {
    return HandlerType.notSimple;
  }
  if (call.args.isEmpty) {
    return HandlerType.simpleNoArgs;
  }
  if (call.args.length != 1) {
    return HandlerType.notSimple;
  }
  var singleArg = call.args.single;
  if (singleArg is! PropertyRead) {
    return HandlerType.notSimple;
  }
  if (isEventVariable(singleArg)) {
    return HandlerType.simpleOneArg;
  } else {
    return HandlerType.notSimple;
  }
}

/// Whether [expression] reads the `$event` variable of an event handler.
bool isEventVariable(AST expression) =>
    expression is PropertyRead &&
    expression.name == EventHandlerVars.event.name &&
    expression.receiver is ImplicitReceiver;

/// Returns the first use of a member of `$event` in [handler], such as
/// `$event.target`, or `null` if it uses none.
String? findEventMember(AST handler) {
  final finder = _EventMemberFinder();
  handler.visit(finder);
  return finder.member;
}

class _EventMemberFinder extends RecursiveAstVisitor<void> {
  String? member;

  /// Records [access] if [receiver] is `$event`, or `$event!`.
  void _found(AST receiver, String access) {
    if (member != null) return;
    var event = r'$event';
    if (receiver is PostfixNotNull) {
      receiver = receiver.expression;
      event = r'$event!';
    }
    if (isEventVariable(receiver)) member = '$event$access';
  }

  static String _key(AST key) => key is LiteralPrimitive && key.value is String
      ? "['${key.value}']"
      : '[...]';

  @override
  void visitPropertyRead(PropertyRead ast, _) {
    _found(ast.receiver, '.${ast.name}');
    super.visitPropertyRead(ast, null);
  }

  @override
  void visitSafePropertyRead(SafePropertyRead ast, _) {
    _found(ast.receiver, '?.${ast.name}');
    super.visitSafePropertyRead(ast, null);
  }

  @override
  void visitPropertyWrite(PropertyWrite ast, _) {
    _found(ast.receiver, '.${ast.name}');
    super.visitPropertyWrite(ast, null);
  }

  @override
  void visitMethodCall(MethodCall ast, _) {
    _found(ast.receiver, '.${ast.name}()');
    super.visitMethodCall(ast, null);
  }

  @override
  void visitSafeMethodCall(SafeMethodCall ast, _) {
    _found(ast.receiver, '?.${ast.name}()');
    super.visitSafeMethodCall(ast, null);
  }

  @override
  void visitKeyedRead(KeyedRead ast, _) {
    _found(ast.receiver, _key(ast.key));
    super.visitKeyedRead(ast, null);
  }

  @override
  void visitKeyedWrite(KeyedWrite ast, _) {
    _found(ast.receiver, _key(ast.key));
    super.visitKeyedWrite(ast, null);
  }
}

/// The warning for a handler of a DOM event that uses [member] of `$event`.
///
/// `$event` is `dynamic` in the generated code, so its members are read
/// dynamically. A DOM event is a JavaScript object, from which a release build
/// (dart2js) cannot read them, unlike the event of an `@Output()`, which is a
/// Dart object.
String eventMemberWarning(String member) =>
    '"$member" reads a member of a DOM event dynamically, which fails in a '
    'release build (dart2js). Pass "\$event" to a method that takes a typed '
    'Event, and read it there.';
