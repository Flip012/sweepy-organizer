import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/task.dart';
import '../../providers/schedule_provider.dart';
import '../../providers/tasks_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/daily_progress_card.dart';
import '../../widgets/streak_badge.dart';
import '../../widgets/task_tile.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedule = ref.watch(scheduleProvider);
    final profile = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Heute'),
        actions: [
          if (profile.value != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: StreakBadge(streak: profile.value!.currentStreak),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(scheduleProvider);
          ref.invalidate(userProfileProvider);
        },
        child: schedule.when(
          data: (state) => _buildContent(context, ref, state),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 16),
                Text('Fehler: $err'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.invalidate(scheduleProvider),
                  child: const Text('Erneut versuchen'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    ScheduleState state,
  ) {
    if (state.tasks.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DailyProgressCard(
            completedPoints: 0,
            totalPoints: 0,
            effortLimit: state.effortLimit,
          ),
          const SizedBox(height: 32),
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Alles erledigt!',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Keine Aufgaben für heute geplant.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      );
    }

    final completedPoints = state.tasks
        .where((t) =>
            t.lastCompletedAt != null &&
            DateTime.now().difference(t.lastCompletedAt!).inHours < 24)
        .fold<int>(0, (sum, t) => sum + t.difficulty);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        DailyProgressCard(
          completedPoints: completedPoints,
          totalPoints: state.totalDifficulty,
          effortLimit: state.effortLimit,
        ),
        const SizedBox(height: 16),
        Text(
          'Aufgaben für heute',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        ...state.tasks.map(
          (task) => TaskTile(
            task: task,
            onComplete: () => _completeTask(ref, task),
          ),
        ),
      ],
    );
  }

  Future<void> _completeTask(WidgetRef ref, Task task) async {
    try {
      await ref.read(tasksProvider.notifier).completeTask(task.id);
      ref.invalidate(scheduleProvider);
      ref.invalidate(userProfileProvider);
    } catch (e) {
      // Error handling in UI
    }
  }
}
