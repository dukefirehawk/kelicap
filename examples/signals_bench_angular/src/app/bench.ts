import {
  ApplicationRef,
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  inject,
} from '@angular/core';

import {
  FieldRow,
  FieldTableComponent,
  rowChecks,
  SignalRow,
  SignalTableComponent,
} from './rows';

type Mode = 'fields' | 'signals';

/** The result of a scenario, in one mode, as the Kelicap benchmark reports it. */
interface Result {
  mode: Mode;
  scenario: string;
  medianMs: number;
  meanMs: number;
  rowsCheckedPerOp: number;
}

/**
 * Measures change detection of the same table, rendered from plain fields
 * with eager change detection, and from signals with OnPush.
 *
 * Each operation is a change, as an event handler of the root component would
 * make it, followed by a change detection pass, the equivalent of an NgZone
 * turn of the Kelicap benchmark. So the time of an operation is that of the
 * change and of the pass that renders it.
 *
 * Without zone.js, the default in Angular 22, `ApplicationRef.tick()` checks
 * only the views marked for check, by an event handler, `markForCheck()` or a
 * signal: an event handler marks its view, the root, so `pass()` does too.
 */
@Component({
  selector: 'bench-app',
  imports: [FieldTableComponent, SignalTableComponent],
  template: `
    <h1>Signals benchmark (Angular)</h1>
    <p>
      {{ rowCount }} rows, rendered from plain fields with eager change
      detection, and from signals with OnPush. Add
      <code>?rows=10000</code> to the URL to change the number of rows.
    </p>
    <button (click)="run()" [disabled]="running">Run</button>
    <span>{{ status }}</span>
    @if (results.length > 0) {
      <table>
        <tr>
          <th>Mode</th><th>Scenario</th><th>Median (ms)</th><th>Mean (ms)</th>
          <th>Rows checked per operation</th>
        </tr>
        @for (result of results; track result) {
          <tr>
            <td>{{ result.mode }}</td><td>{{ result.scenario }}</td>
            <td>{{ result.medianMs.toFixed(3) }}</td>
            <td>{{ result.meanMs.toFixed(3) }}</td>
            <td>{{ result.rowsCheckedPerOp.toFixed(1) }}</td>
          </tr>
        }
      </table>
    }
    <pre id="results">{{ json }}</pre>
    @if (mode === 'fields') {
      <field-table [rows]="fieldRows" />
    }
    @if (mode === 'signals') {
      <signal-table [rows]="signalRows" />
    }
  `,
  // Its plain fields are rendered on each pass, as OnPush is the default.
  changeDetection: ChangeDetectionStrategy.Eager,
})
export class BenchAppComponent {
  private readonly appRef = inject(ApplicationRef);
  private readonly changeDetector = inject(ChangeDetectorRef);

  /** The number of rows in each table, from `?rows=` in the URL. */
  readonly rowCount =
    Number(new URL(location.href).searchParams.get('rows')) || 1000;

  readonly fieldRows = Array.from(
    {length: this.rowCount},
    (_, i) => new FieldRow(`Row ${i}`),
  );
  readonly signalRows = Array.from(
    {length: this.rowCount},
    (_, i) => new SignalRow(`Row ${i}`),
  );

  /** The table on the page, if any. */
  mode: Mode | null = null;
  running = false;
  status = '';
  results: Result[] = [];
  json = '';

  /** Runs the benchmark, synchronously. */
  run(): void {
    this.render(() => {
      this.running = true;
      this.status = 'Running…';
    });
    // The first round warms up the JavaScript engine, and is not reported.
    for (const reported of [false, true]) {
      const round = [...this.measure('fields'), ...this.measure('signals')];
      if (reported) {
        this.render(() => {
          this.results = round;
          this.json = JSON.stringify(round, null, 2);
        });
      }
    }
    this.render(() => {
      this.mode = null;
      this.running = false;
      this.status = 'Done.';
    });
  }

  private measure(mode: Mode): Result[] {
    this.render(() => (this.mode = mode));
    const fields = mode === 'fields';
    let next = 1;

    const setRow = (index: number) => {
      const value = next++;
      if (fields) {
        this.fieldRows[index].value = value;
      } else {
        this.signalRows[index].value.set(value);
      }
    };

    return [
      this.time(mode, 'Update one row', 50, 20, (i) =>
        setRow((i * 7) % this.rowCount),
      ),
      this.time(mode, 'Update all rows', 20, 1, () => {
        for (let i = 0; i < this.rowCount; i++) {
          setRow(i);
        }
      }),
      this.time(mode, 'No change', 50, 20, () => {}),
    ];
  }

  /**
   * Times `samples` batches of `batch` operations, and returns the time of
   * one, as the Kelicap benchmark does.
   *
   * A batch is timed as a whole, as browsers round `performance.now()`, to
   * 0.1 ms in Chrome, which is about the time of an operation.
   */
  private time(
    mode: Mode,
    scenario: string,
    samples: number,
    batch: number,
    operation: (i: number) => void,
  ): Result {
    const times: number[] = [];
    rowChecks.count = 0;
    let i = 0;
    for (let sample = 0; sample < samples; sample++) {
      const start = performance.now();
      for (const end = i + batch; i < end; i++) {
        operation(i);
        this.pass();
      }
      times.push((performance.now() - start) / batch);
    }
    const checks = rowChecks.count;
    times.sort((a, b) => a - b);
    const mean = times.reduce((a, b) => a + b, 0) / samples;
    return {
      mode,
      scenario,
      medianMs: times[Math.floor(samples / 2)],
      meanMs: mean,
      rowsCheckedPerOp: checks / i,
    };
  }

  /** Changes the page, and renders it. */
  private render(change: () => void): void {
    change();
    this.pass();
  }

  /**
   * Runs a change detection pass after an event in the root, which marks the
   * root for check, as an event handler does.
   */
  private pass(): void {
    this.changeDetector.markForCheck();
    this.appRef.tick();
  }
}
