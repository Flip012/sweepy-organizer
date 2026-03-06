import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/rooms_provider.dart';
import '../../providers/tasks_provider.dart';
import '../../widgets/room_card.dart';

class RoomsScreen extends ConsumerWidget {
  const RoomsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rooms = ref.watch(roomsProvider);
    final allTasks = ref.watch(tasksProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Räume')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/rooms/new'),
        icon: const Icon(Icons.add),
        label: const Text('Raum hinzufügen'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(roomsProvider);
          ref.invalidate(tasksProvider);
        },
        child: rooms.when(
          data: (roomList) {
            if (roomList.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.room_preferences_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Noch keine Räume',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    const Text('Erstelle deinen ersten Raum!'),
                  ],
                ),
              );
            }

            final taskList = allTasks.value ?? [];

            return LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: roomList.length,
                  itemBuilder: (context, index) {
                    final room = roomList[index];
                    final roomTasks =
                        taskList.where((t) => t.roomId == room.id).toList();
                    return RoomCard(
                      name: room.name,
                      icon: room.icon,
                      tasks: roomTasks,
                      onTap: () => context.go('/rooms/${room.id}'),
                    );
                  },
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Fehler: $err')),
        ),
      ),
    );
  }
}
