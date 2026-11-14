import {ChangeDetectionStrategy, Component, Input, signal} from '@angular/core';

/** Counts the rows checked, by a binding in each row's template. */
export const rowChecks = {count: 0};

/** A row whose value is a plain field. */
export class FieldRow {
  value = 0;

  constructor(readonly label: string) {}
}

/** A row whose value is a signal. */
export class SignalRow {
  readonly value = signal(0);

  constructor(readonly label: string) {}
}

/**
 * A row rendered with eager change detection, the default before Angular 22:
 * it is checked on every change detection pass.
 */
@Component({
  selector: 'field-row',
  template: `<span>{{ row.label }}</span> <b>{{ row.value }}</b>{{ checked() }}`,
  changeDetection: ChangeDetectionStrategy.Eager,
})
export class FieldRowComponent {
  @Input({required: true}) row!: FieldRow;

  checked(): string {
    rowChecks.count++;
    return '';
  }
}

/**
 * A row rendered with OnPush change detection: it is checked only when its
 * value, a signal, changes.
 */
@Component({
  selector: 'signal-row',
  template: `<span>{{ row.label }}</span> <b>{{ row.value() }}</b>{{ checked() }}`,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class SignalRowComponent {
  @Input({required: true}) row!: SignalRow;

  checked(): string {
    rowChecks.count++;
    return '';
  }
}

@Component({
  selector: 'field-table',
  imports: [FieldRowComponent],
  template: `@for (row of rows; track row) {
    <field-row [row]="row" />
  }`,
  changeDetection: ChangeDetectionStrategy.Eager,
})
export class FieldTableComponent {
  @Input({required: true}) rows!: FieldRow[];
}

@Component({
  selector: 'signal-table',
  imports: [SignalRowComponent],
  template: `@for (row of rows; track row) {
    <signal-row [row]="row" />
  }`,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class SignalTableComponent {
  @Input({required: true}) rows!: SignalRow[];
}
