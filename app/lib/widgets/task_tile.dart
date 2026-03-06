import 'package:flutter/material.dart';

import '../models/task.dart';

class TaskTile extends StatelessWidget {
  final Task task;
  final VoidCallback? onComplete;
  final VoidCallback? onTap;
  final bool showRoom;

  const TaskTile({
    super.key,
    required this.task,
    this.onComplete,
    this.onTap,
    this.showRoom = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isRecentlyCompleted = task.lastCompletedAt != null &&
        DateTime.now().difference(task.lastCompletedAt!).inHours < 1;

    return Card(
      child: ListTile(
        leading: IconButton(
          onPressed: onComplete,
          icon: Icon(
            isRecentlyCompleted
                ? Icons.check_circle
                : Icons.radio_button_unchecked,
            color: isRecentlyCompleted
                ? colorScheme.primary
                : colorScheme.outline,
          ),
        ),
        title: Text(
          task.name,
          style: TextStyle(
            decoration:
                isRecentlyCompleted ? TextDecoration.lineThrough : null,
            color: isRecentlyCompleted
                ? colorScheme.outline
                : colorScheme.onSurface,
          ),
        ),
        subtitle: Row(
          children: [
            ...List.generate(
              task.difficulty,
              (i) => Icon(Icons.star, size: 14, color: colorScheme.primary),
            ),
            ...List.generate(
              3 - task.difficulty,
              (i) => Icon(Icons.star_border, size: 14, color: colorScheme.outline),
            ),
            const SizedBox(width: 8),
            Text(
              _frequencyLabel(task.frequencyDays),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: _buildOverdueIndicator(context),
        onTap: onTap,
      ),
    );
  }

  Widget? _buildOverdueIndicator(BuildContext context) {
    final ratio = task.overdueRatio;
    if (ratio < 0.8) return null;

    final color = Color.lerp(Colors.orange, Colors.red, (ratio - 0.8) / 0.4)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        ratio >= 1.5 ? 'Überfällig!' : 'Fällig',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  String _frequencyLabel(int days) {
    if (days == 1) return 'Täglich';
    if (days == 7) return 'Wöchentlich';
    if (days == 14) return 'Alle 2 Wochen';
    if (days == 30) return 'Monatlich';
    return 'Alle $days Tage';
  }
}
