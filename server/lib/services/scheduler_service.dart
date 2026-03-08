import 'package:server/models/task.dart';

/// Generates a daily task list using a greedy algorithm.
///
/// Tasks are selected based on how overdue they are, respecting the user's
/// daily effort limit. Own tasks are prioritized, then unassigned tasks.
class SchedulerService {
  const SchedulerService();

  /// Generate today's task list for a specific user.
  ///
  /// [tasks] - All tasks in the household
  /// [userId] - The current user's ID
  /// [dailyEffortLimit] - Max difficulty points for the day (default 6)
  List<Task> generateDailySchedule({
    required List<Task> tasks,
    required String userId,
    int dailyEffortLimit = 6,
  }) {
    // Calculate overdue ratio for each task and filter to due/overdue tasks
    final candidates =
        tasks.where((t) => t.overdueRatio >= 0.8).toList()
          ..sort((a, b) {
            // Prioritize: own first, then unassigned
            final aOwn = a.assignedTo == userId
                ? 0
                : (a.assignedTo == null ? 1 : 2);
            final bOwn = b.assignedTo == userId
                ? 0
                : (b.assignedTo == null ? 1 : 2);
            if (aOwn != bOwn) {
              return aOwn.compareTo(bOwn);
            }
            return b.overdueRatio.compareTo(a.overdueRatio);
          });

    // Greedy knapsack: pick tasks until effort limit is reached
    final selected = <Task>[];
    var remainingEffort = dailyEffortLimit;

    for (final task in candidates) {
      // Skip tasks assigned to someone else
      if (task.assignedTo != null && task.assignedTo != userId) continue;

      if (task.difficulty <= remainingEffort) {
        selected.add(task);
        remainingEffort -= task.difficulty;
      }

      if (remainingEffort <= 0) break;
    }

    return selected;
  }
}
