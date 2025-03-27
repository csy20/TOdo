import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:ui_2/theme/app_theme.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Todo Model
class Todo {
  final String id;
  final String title;
  bool isCompleted;

  Todo({
    required this.id,
    required this.title,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'isCompleted': isCompleted,
      };

  factory Todo.fromJson(Map<String, dynamic> json) => Todo(
        id: json['id'],
        title: json['title'],
        isCompleted: json['isCompleted'],
      );
}

// Providers
final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

final todoListProvider = StateNotifierProvider<TodoListNotifier, List<Todo>>((ref) {
  return TodoListNotifier(ref.read(sharedPrefsProvider));
});

class TodoListNotifier extends StateNotifier<List<Todo>> {
  final SharedPreferences prefs;
  TodoListNotifier(this.prefs) : super([]) {
    loadTodos();
  }

  void loadTodos() {
    final todosString = prefs.getString('todos');
    if (todosString != null) {
      final List<dynamic> todosJson = jsonDecode(todosString);
      state = todosJson.map((json) => Todo.fromJson(json)).toList();
    }
  }

  void saveTodos() {
    final todosJson = jsonEncode(state.map((todo) => todo.toJson()).toList());
    prefs.setString('todos', todosJson);
  }

  void addTodo(String title) {
    state = [
      ...state,
      Todo(id: DateTime.now().toString(), title: title),
    ];
    saveTodos();
  }

  void toggleTodo(String id) {
    state = state.map((todo) {
      if (todo.id == id) {
        return Todo(
          id: todo.id,
          title: todo.title,
          isCompleted: !todo.isCompleted,
        );
      }
      return todo;
    }).toList();
    saveTodos();
  }

  void deleteTodo(String id) {
    state = state.where((todo) => todo.id != id).toList();
    saveTodos();
  }
}
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(ProviderScope(
    overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
    ],
    child: MyApp(),
  ));
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Improved UI Demo',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      theme: CupertinoThemeData(brightness: Brightness.light),
      home: HomePage(),
    );
  }
}

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const TodoListPage(),
      const CompletedTodosPage(),
    ];

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Todo List'),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(child: pages[_selectedIndex]),
            CupertinoTabBar(
              currentIndex: _selectedIndex,
              onTap: (index) => setState(() => _selectedIndex = index),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.list_bullet),
                  label: 'Todos',
                ),
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.check_mark_circled),
                  label: 'Completed',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class TodoListPage extends ConsumerWidget {
  const TodoListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todos = ref.watch(todoListProvider).where((todo) => !todo.isCompleted).toList();

    return Column(
      children: [
        CupertinoButton(
          child: const Text('Add Todo'),
          onPressed: () => showCupertinoModalPopup(
            context: context,
            builder: (_) => const AddTodoSheet(),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: todos.length,
            itemBuilder: (context, index) {
              final todo = todos[index];
              return CupertinoListTile(
                title: Text(todo.title),
                trailing: CupertinoButton(
                  child: const Icon(CupertinoIcons.delete),
                  onPressed: () => ref.read(todoListProvider.notifier).deleteTodo(todo.id),
                ),
                onTap: () => ref.read(todoListProvider.notifier).toggleTodo(todo.id),
              );
            },
          ),
        ),
      ],
    );
  }
}

class CompletedTodosPage extends ConsumerWidget {
  const CompletedTodosPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todos = ref.watch(todoListProvider).where((todo) => todo.isCompleted).toList();

    return ListView.builder(
      itemCount: todos.length,
      itemBuilder: (context, index) {
        final todo = todos[index];
        return CupertinoListTile(
          title: Text(todo.title, style: const TextStyle(decoration: TextDecoration.lineThrough)),
          trailing: CupertinoButton(
            child: const Icon(CupertinoIcons.delete),
            onPressed: () => ref.read(todoListProvider.notifier).deleteTodo(todo.id),
          ),
          onTap: () => ref.read(todoListProvider.notifier).toggleTodo(todo.id),
        );
      },
    );
  }
}

class AddTodoSheet extends StatefulWidget {
  const AddTodoSheet({super.key});

  @override
  State<AddTodoSheet> createState() => _AddTodoSheetState();
}

class _AddTodoSheetState extends State<AddTodoSheet> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        return CupertinoActionSheet(
          title: const Text('New Todo'),
          actions: [
            CupertinoTextField(
              controller: _controller,
              placeholder: 'Enter todo title',
            ),
            CupertinoActionSheetAction(
              child: const Text('Add'),
              onPressed: () {
                if (_controller.text.isNotEmpty) {
                  ref.read(todoListProvider.notifier).addTodo(_controller.text);
                  Navigator.pop(context);
                }
              },
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
        );
      },
    );
  }
}