import 'package:kelicap/kelicap.dart';

@Component(
  selector: 'todo-list',
  styleUrls: ['todo.css'],
  templateUrl: 'todo.html',
  directives: [
    coreDirectives,
  ], // Provides *ngFor and core structural directives
)
class TodoComponent {
  List<String> todos = [
    'Learn AngularDart basics',
    'Understand structural directives like *ngIf and *ngFor',
    'Fork the repository into Kelicap',
    'Build awesome web apps',
  ];

  void addTodo(String newTodo) {
    if (newTodo.isNotEmpty) {
      todos.add(newTodo);
    }
  }

  void removeTodo(int index) {
    todos.removeAt(index);
  }
}
