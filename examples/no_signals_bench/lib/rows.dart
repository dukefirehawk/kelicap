import 'package:kelicap/kelicap.dart';

/// Counts the rows checked, by a binding in each row's template.
abstract final class RowChecks {
  static var count = 0;
}

/// A row whose value is a plain field.
class Row {
  final String label;
  int value = 0;

  /// The change detector of the OnPush row that renders it, if any.
  ChangeDetectorRef? changeDetector;

  Row(this.label);
}

/// A row rendered with the default change detection: it is checked on every
/// change detection pass.
@Component(
  selector: 'default-row',
  template: '<span>{{row.label}}</span> <b>{{row.value}}</b>{{checked()}}',
)
class DefaultRowComponent {
  @Input()
  late Row row;

  String checked() {
    RowChecks.count++;
    return '';
  }
}

/// A row rendered with OnPush change detection: it is checked only when the
/// code that changes its value calls `markForCheck`.
@Component(
  selector: 'onpush-row',
  template: '<span>{{row.label}}</span> <b>{{row.value}}</b>{{checked()}}',
  changeDetection: ChangeDetectionStrategy.onPush,
)
class OnPushRowComponent {
  final ChangeDetectorRef _changeDetector;

  OnPushRowComponent(this._changeDetector);

  @Input()
  set row(Row value) {
    _row = value..changeDetector = _changeDetector;
  }

  Row get row => _row;
  late Row _row;

  String checked() {
    RowChecks.count++;
    return '';
  }
}

@Component(
  selector: 'default-table',
  template: '<default-row *ngFor="let row of rows" [row]="row"></default-row>',
  directives: [NgFor, DefaultRowComponent],
)
class DefaultTableComponent {
  @Input()
  late List<Row> rows;
}

@Component(
  selector: 'onpush-table',
  template: '<onpush-row *ngFor="let row of rows" [row]="row"></onpush-row>',
  directives: [NgFor, OnPushRowComponent],
  changeDetection: ChangeDetectionStrategy.onPush,
)
class OnPushTableComponent {
  @Input()
  late List<Row> rows;
}
