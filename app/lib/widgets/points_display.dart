import 'package:flutter/material.dart';

class PointsDisplay extends StatelessWidget {
  final int points;
  final bool large;

  const PointsDisplay({super.key, required this.points, this.large = false});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 16 : 10,
        vertical: large ? 8 : 4,
      ),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.emoji_events,
            size: large ? 24 : 16,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Text(
            '$points',
            style: (large ? textTheme.titleLarge : textTheme.labelMedium)
                ?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}
