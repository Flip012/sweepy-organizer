import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/task.dart';
import 'api_provider.dart';
import 'auth_provider.dart';

final tasksProvider =
    AsyncNotifierProvider<TasksNotifier, List<Task>>(TasksNotifier.new);

class TasksNotifier extends AsyncNotifier<List<Task>> {
  @override
  Future<List<Task>> build() async {
    final auth = ref.watch(authProvider);
    if (!auth.isAuthenticated) return [];

    final api = ref.read(apiClientProvider);
    final data = await api.get('/api/tasks');
    return (data['tasks'] as List)
        .map((t) => Task.fromJson(t as Map<String, dynamic>))
        .toList();
  }

  Future<Task> createTask({
    required String roomId,
    required String name,
    int difficulty = 1,
    int frequencyDays = 7,
    String? assignedTo,
  }) async {
    final api = ref.read(apiClientProvider);
    final data = await api.post('/api/tasks', body: {
      'roomId': roomId,
      'name': name,
      'difficulty': difficulty,
      'frequencyDays': frequencyDays,
      // ignore: use_null_aware_elements
      if (assignedTo != null) 'assignedTo': assignedTo,
    });
    final task = Task.fromJson(data);
    state = AsyncData([...state.value ?? [], task]);
    return task;
  }

  Future<void> updateTask({
    required String id,
    String? name,
    int? difficulty,
    int? frequencyDays,
    String? assignedTo,
    bool clearAssignment = false,
  }) async {
    final api = ref.read(apiClientProvider);
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (difficulty != null) body['difficulty'] = difficulty;
    if (frequencyDays != null) body['frequencyDays'] = frequencyDays;
    if (assignedTo != null) body['assignedTo'] = assignedTo;
    if (clearAssignment) body['clearAssignment'] = true;

    final data = await api.put('/api/tasks/$id', body: body);
    final updated = Task.fromJson(data);
    state = AsyncData(
      (state.value ?? []).map((t) => t.id == id ? updated : t).toList(),
    );
  }

  Future<Map<String, dynamic>> completeTask(String id) async {
    final api = ref.read(apiClientProvider);
    final data = await api.post('/api/tasks/$id/complete');
    final updatedTask = Task.fromJson(data['task'] as Map<String, dynamic>);
    state = AsyncData(
      (state.value ?? []).map((t) => t.id == id ? updatedTask : t).toList(),
    );
    return data;
  }

  Future<void> deleteTask(String id) async {
    final api = ref.read(apiClientProvider);
    await api.delete('/api/tasks/$id');
    state = AsyncData(
      (state.value ?? []).where((t) => t.id != id).toList(),
    );
  }
}

/// Provider that filters tasks by room
final tasksByRoomProvider = Provider.family<List<Task>, String>((ref, roomId) {
  final tasks = ref.watch(tasksProvider).value ?? [];
  return tasks.where((t) => t.roomId == roomId).toList();
});
