import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/rooms_provider.dart';
import '../../providers/tasks_provider.dart';
import '../../widgets/cleanliness_indicator.dart';
import '../../widgets/task_tile.dart';

class RoomDetailScreen extends ConsumerWidget {
  final String roomId;

  const RoomDetailScreen({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rooms = ref.watch(roomsProvider);
    final roomTasks = ref.watch(tasksByRoomProvider(roomId));

    final room = rooms.value?.where((r) => r.id == roomId).firstOrNull;

    if (room == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final dirtiness = roomTasks.isEmpty
        ? 0.0
        : roomTasks.fold<double>(0, (s, t) => s + t.dirtiness) /
            roomTasks.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(room.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.go('/rooms/$roomId/edit'),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/tasks/new?roomId=$roomId'),
        icon: const Icon(Icons.add),
        label: const Text('Aufgabe'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Room header with cleanliness
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CleanlinessIndicator(dirtiness: dirtiness, size: 56),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dirtiness < 0.3
                              ? 'Sauber'
                              : dirtiness < 0.7
                                  ? 'Geht so'
                                  : 'Braucht Aufmerksamkeit',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${roomTasks.length} Aufgaben',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (roomTasks.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'Noch keine Aufgaben in diesem Raum.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            )
          else
            ...roomTasks.map(
              (task) => TaskTile(
                task: task,
                onComplete: () async {
                  await ref.read(tasksProvider.notifier).completeTask(task.id);
                },
                onTap: () => context.go('/tasks/${task.id}/edit'),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Raum löschen?'),
        content: const Text(
          'Alle Aufgaben in diesem Raum werden ebenfalls gelöscht.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(roomsProvider.notifier).deleteRoom(roomId);
      if (context.mounted) context.go('/rooms');
    }
  }
}
