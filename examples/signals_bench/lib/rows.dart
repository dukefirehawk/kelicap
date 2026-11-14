import 'package:kelicap/kelicap.dart';
import 'package:kelicap/signals.dart';

/// Counts the rows checked, by a binding in each row's template.
abstract final class RowChecks {
  static var count = 0;
}

/// A row whose value is a plain field.
class FieldRow {
  final String label;
  int value = 0;

  FieldRow(this.label);
}

/// A row whose value is a signal.
class SignalRow {
  final String label;
  final value = signal(0);

  SignalRow(this.label);
}

/// A row rendered with the default change detection: it is checked on every
/// change detection pass.
@Component(
  selector: 'field-row',
  template: '<span>{{row.label}}</span> <b>{{row.value}}</b>{{checked()}}',
)
class FieldRowComponent {
  @Input()
  late FieldRow row;

  String checked() {
    RowChecks.count++;
    return '';
  }
}

/// A row rendered with OnPush change detection: it is checked only when its
/// value, a signal, changes.
@Component(
  selector: 'signal-row',
  template: '<span>{{row.label}}</span> <b>{{row.value()}}</b>{{checked()}}',
  changeDetection: ChangeDetectionStrategy.onPush,
)
class SignalRowComponent {
  @Input()
  late SignalRow row;

  String checked() {
    RowChecks.count++;
    return '';
  }
}

@Component(
  selector: 'field-table',
  template: '<field-row *ngFor="let row of rows" [row]="row"></field-row>',
  directives: [NgFor, FieldRowComponent],
)
class FieldTableComponent {
  @Input()
  late List<FieldRow> rows;
}

@Component(
  selector: 'signal-table',
  template: '<signal-row *ngFor="let row of rows" [row]="row"></signal-row>',
  directives: [NgFor, SignalRowComponent],
  changeDetection: ChangeDetectionStrategy.onPush,
)
class SignalTableComponent {
  @Input()
  late List<SignalRow> rows;
}
