import 'package:flutter/material.dart';

class DailyProgressCard extends StatelessWidget {
  final int completedPoints;
  final int totalPoints;
  final int effortLimit;

  const DailyProgressCard({
    super.key,
    required this.completedPoints,
    required this.totalPoints,
    required this.effortLimit,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final progress = effortLimit > 0
        ? (completedPoints / effortLimit).clamp(0.0, 1.0)
        : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Tagesfortschritt',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '$completedPoints / $effortLimit Punkte',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 12,
                backgroundColor: colorScheme.primaryContainer,
                valueColor: AlwaysStoppedAnimation(
                  progress >= 1.0 ? Colors.green : colorScheme.primary,
                ),
              ),
            ),
            if (progress >= 1.0) ...[
              const SizedBox(height: 8),
              Text(
                'Tagesziel erreicht!',
                style: textTheme.bodySmall?.copyWith(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
