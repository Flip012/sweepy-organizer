import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/task.dart';
import 'api_provider.dart';
import 'auth_provider.dart';

class ScheduleState {
  final List<Task> tasks;
  final int totalDifficulty;
  final int effortLimit;

  const ScheduleState({
    this.tasks = const [],
    this.totalDifficulty = 0,
    this.effortLimit = 6,
  });
}

final scheduleProvider =
    AsyncNotifierProvider<ScheduleNotifier, ScheduleState>(
  ScheduleNotifier.new,
);

class ScheduleNotifier extends AsyncNotifier<ScheduleState> {
  @override
  Future<ScheduleState> build() async {
    final auth = ref.watch(authProvider);
    if (!auth.isAuthenticated) return const ScheduleState();

    return _fetch();
  }

  Future<ScheduleState> _fetch() async {
    final api = ref.read(apiClientProvider);
    final data = await api.get('/api/schedule/today');
    return ScheduleState(
      tasks: (data['tasks'] as List)
          .map((t) => Task.fromJson(t as Map<String, dynamic>))
          .toList(),
      totalDifficulty: data['totalDifficulty'] as int? ?? 0,
      effortLimit: data['effortLimit'] as int? ?? 6,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _fetch());
  }
}
