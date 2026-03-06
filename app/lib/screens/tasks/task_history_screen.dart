import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/task_log_provider.dart';

class TaskHistoryScreen extends ConsumerWidget {
  const TaskHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(taskLogProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Verlauf')),
      body: logs.when(
        data: (logList) {
          if (logList.isEmpty) {
            return const Center(
              child: Text('Noch keine erledigten Aufgaben.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: logList.length,
            itemBuilder: (context, index) {
              final log = logList[index];
              final dateFormat = DateFormat('dd.MM.yyyy HH:mm');

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text('${log.pointsEarned}'),
                  ),
                  title: Text(log.taskName),
                  subtitle: Text(
                    '${log.completedByName} - ${dateFormat.format(log.completedAt.toLocal())}',
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Fehler: $err')),
      ),
    );
  }
}
