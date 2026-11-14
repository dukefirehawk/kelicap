import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// Counts the rows checked, by each row's `build`.
abstract final class RowChecks {
  static var count = 0;
}

/// A row whose value is a plain field.
class FieldRow {
  final String label;
  int value = 0;

  FieldRow(this.label);
}

/// A row whose value is a [ValueNotifier], Jaspr's observable value, in place
/// of a signal, which Jaspr does not have.
class SignalRow {
  final String label;
  final value = ValueNotifier(0);

  SignalRow(this.label);
}

/// A row rebuilt whenever its parent is, Jaspr's default: it is checked on
/// every pass that rebuilds the root.
class FieldRowComponent extends StatelessComponent {
  final FieldRow row;

  const FieldRowComponent(this.row);

  @override
  Component build(BuildContext context) {
    RowChecks.count++;
    return Component.element(
      tag: 'field-row',
      children: [
        span([Component.text(row.label)]),
        const Component.text(' '),
        b([Component.text('${row.value}')]),
      ],
    );
  }
}

/// A row rebuilt only when its value changes: the equivalent of OnPush, with
/// [shouldRebuild] comparing its input, and its own [State.setState] when its
/// value notifies it.
class SignalRowComponent extends StatefulComponent {
  final SignalRow row;

  const SignalRowComponent(this.row);

  @override
  State<SignalRowComponent> createState() => _SignalRowState();
}

class _SignalRowState extends State<SignalRowComponent> {
  @override
  void initState() {
    super.initState();
    component.row.value.addListener(_changed);
  }

  @override
  void didUpdateComponent(SignalRowComponent oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (oldComponent.row != component.row) {
      oldComponent.row.value.removeListener(_changed);
      component.row.value.addListener(_changed);
    }
  }

  @override
  void dispose() {
    component.row.value.removeListener(_changed);
    super.dispose();
  }

  void _changed() => setState(() {});

  @override
  bool shouldRebuild(SignalRowComponent newComponent) =>
      newComponent.row != component.row;

  @override
  Component build(BuildContext context) {
    RowChecks.count++;
    final row = component.row;
    return Component.element(
      tag: 'signal-row',
      children: [
        span([Component.text(row.label)]),
        const Component.text(' '),
        b([Component.text('${row.value.value}')]),
      ],
    );
  }
}

class FieldTableComponent extends StatelessComponent {
  final List<FieldRow> rows;

  const FieldTableComponent(this.rows);

  @override
  Component build(BuildContext context) => Component.element(
    tag: 'field-table',
    children: [for (final row in rows) FieldRowComponent(row)],
  );
}

/// The table of signal rows, rebuilt only when its list of rows changes.
class SignalTableComponent extends StatelessComponent {
  final List<SignalRow> rows;

  const SignalTableComponent(this.rows);

  @override
  bool shouldRebuild(SignalTableComponent newComponent) =>
      newComponent.rows != rows;

  @override
  Component build(BuildContext context) => Component.element(
    tag: 'signal-table',
    children: [for (final row in rows) SignalRowComponent(row)],
  );
}
