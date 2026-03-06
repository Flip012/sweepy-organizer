import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/household_provider.dart';
import '../../widgets/member_avatar.dart';
import '../../widgets/points_display.dart';
import '../../widgets/streak_badge.dart';

class HouseholdScreen extends ConsumerWidget {
  const HouseholdScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final household = ref.watch(householdProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Haushalt')),
      body: household.when(
        data: (state) {
          if (state.members.isEmpty) {
            return const Center(
              child: Text('Keine Mitglieder gefunden.'),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Haushalt-ID',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        state.householdId ?? 'Unbekannt',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Mitglieder werden über Authentik-Gruppen verwaltet.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Mitglieder (${state.members.length})',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...state.members.map(
                (member) => Card(
                  child: ListTile(
                    leading: MemberAvatar(
                      name: member.displayName,
                      points: member.totalPoints,
                    ),
                    title: Text(member.displayName),
                    subtitle: Text(member.email),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        PointsDisplay(points: member.totalPoints),
                        const SizedBox(height: 4),
                        StreakBadge(streak: member.currentStreak),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Fehler: $err')),
      ),
    );
  }
}
