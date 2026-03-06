import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/points_display.dart';
import '../../widgets/streak_badge.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: profile.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Profil nicht gefunden.'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Profile card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: colorScheme.primaryContainer,
                        child: Text(
                          user.displayName.isNotEmpty
                              ? user.displayName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user.displayName,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text(
                        user.email,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          PointsDisplay(points: user.totalPoints, large: true),
                          const SizedBox(width: 12),
                          StreakBadge(streak: user.currentStreak),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Effort limit
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tägliches Aufwandslimit',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Wie viele Punkte möchtest du pro Tag schaffen?',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Slider(
                        value: user.dailyEffortLimit.toDouble(),
                        min: 1,
                        max: 15,
                        divisions: 14,
                        label: '${user.dailyEffortLimit} Punkte',
                        onChangeEnd: (value) async {
                          await ref
                              .read(userProfileProvider.notifier)
                              .updateProfile(
                                dailyEffortLimit: value.round(),
                              );
                        },
                        onChanged: (_) {},
                      ),
                      Center(
                        child: Text(
                          '${user.dailyEffortLimit} Punkte',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(color: colorScheme.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Navigation items
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.group),
                      title: const Text('Haushalt'),
                      subtitle: const Text('Mitglieder verwalten'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.go('/profile/household'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.history),
                      title: const Text('Verlauf'),
                      subtitle: const Text('Erledigte Aufgaben'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.go('/profile/history'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Logout
              OutlinedButton.icon(
                onPressed: () => ref.read(authProvider.notifier).logout(),
                icon: const Icon(Icons.logout),
                label: const Text('Abmelden'),
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
