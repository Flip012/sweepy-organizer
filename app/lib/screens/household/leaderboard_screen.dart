import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/household_provider.dart';
import '../../widgets/member_avatar.dart';
import '../../widgets/streak_badge.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboard = ref.watch(leaderboardProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Rangliste')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(leaderboardProvider),
        child: leaderboard.when(
          data: (entries) {
            if (entries.isEmpty) {
              return const Center(
                child: Text('Noch keine Punkte gesammelt.'),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                final rank = index + 1;

                return Card(
                  color: rank == 1
                      ? colorScheme.primaryContainer.withValues(alpha: 0.5)
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Rank
                        SizedBox(
                          width: 40,
                          child: Text(
                            rank <= 3 ? ['', '1.', '2.', '3.'][rank] : '$rank.',
                            style: textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: rank == 1
                                  ? Colors.amber.shade700
                                  : rank == 2
                                      ? Colors.grey.shade600
                                      : rank == 3
                                          ? Colors.brown.shade400
                                          : colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        MemberAvatar(
                          name: entry.displayName,
                          points: entry.totalPoints,
                          size: 48,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.displayName,
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              StreakBadge(streak: entry.currentStreak),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${entry.totalPoints}',
                              style: textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                            Text(
                              'Punkte',
                              style: textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
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
