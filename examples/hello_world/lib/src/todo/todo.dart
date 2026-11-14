import 'package:kelicap/kelicap.dart';
import 'package:kelicap/signals.dart';
import 'package:web/web.dart';

/// A list of tasks, kept in a signal.
///
/// It uses OnPush change detection: it is checked only when [todos] changes,
/// such as when a task is added or deleted.
@Component(
  selector: 'todo-list',
  styleUrls: ['todo.css'],
  templateUrl: 'todo.html',
  directives: [
    coreDirectives,
  ], // Provides *ngFor and core structural directives
  changeDetection: ChangeDetectionStrategy.onPush,
)
class TodoComponent {
  final todos = signal([
    'Learn AngularDart basics',
    'Understand structural directives like *ngIf and *ngFor',
    'Fork the repository into Kelicap',
    'Build awesome web apps',
  ]);

  /// The number of tasks, derived from [todos].
  late final remaining = computed(() => todos().length);

  /// Adds the task typed in [input], and clears it.
  void addTodo(HTMLInputElement input) {
    final newTodo = input.value.trim();
    if (newTodo.isNotEmpty) {
      // A new list, as the signal tells its readers only of a new value.
      todos.update((todos) => [...todos, newTodo]);
    }
    input.value = '';
  }

  void removeTodo(int index) {
    todos.update((todos) => [...todos]..removeAt(index));
  }
}
