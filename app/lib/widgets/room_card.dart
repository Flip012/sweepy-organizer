import 'package:flutter/material.dart';

import '../models/task.dart';
import 'cleanliness_indicator.dart';

class RoomCard extends StatelessWidget {
  final String name;
  final String icon;
  final List<Task> tasks;
  final VoidCallback? onTap;

  const RoomCard({
    super.key,
    required this.name,
    required this.icon,
    required this.tasks,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final dirtiness = _calculateDirtiness();
    final taskCount = tasks.length;
    final overdueCount = tasks.where((t) => t.overdueRatio >= 1.0).length;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    getIconForRoom(icon),
                    size: 28,
                    color: colorScheme.primary,
                  ),
                  const Spacer(),
                  CleanlinessIndicator(dirtiness: dirtiness),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                name,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '$taskCount Aufgaben${overdueCount > 0 ? ' ($overdueCount fällig)' : ''}',
                style: textTheme.bodySmall?.copyWith(
                  color: overdueCount > 0
                      ? colorScheme.error
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _calculateDirtiness() {
    if (tasks.isEmpty) return 0.0;
    final sum = tasks.fold<double>(0, (s, t) => s + t.dirtiness);
    return sum / tasks.length;
  }

}

/// Maps room icon string names to Material Icons.
IconData getIconForRoom(String iconName) {
  const map = <String, IconData>{
    'home': Icons.home,
    'kitchen': Icons.kitchen,
    'bathroom': Icons.bathroom,
    'bedroom': Icons.bed,
    'living_room': Icons.living,
    'dining_room': Icons.dining,
    'garage': Icons.garage,
    'garden': Icons.yard,
    'office': Icons.work,
    'laundry': Icons.local_laundry_service,
    'hallway': Icons.door_front_door,
    'balcony': Icons.balcony,
  };
  return map[iconName] ?? Icons.home;
}
