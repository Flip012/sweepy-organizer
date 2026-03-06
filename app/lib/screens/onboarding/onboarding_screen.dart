import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/rooms_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _nameController = TextEditingController();
  bool _isLoading = false;

  static const _defaultRooms = [
    ('Küche', 'kitchen'),
    ('Bad', 'bathroom'),
    ('Wohnzimmer', 'living_room'),
    ('Schlafzimmer', 'bedroom'),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Icon(
                Icons.cleaning_services,
                size: 48,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Willkommen!',
                style: textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Erstelle deinen ersten Raum, um loszulegen.',
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Schnellstart: Wähle Räume aus',
                style: textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _defaultRooms.map((entry) {
                  final (name, icon) = entry;
                  return FilterChip(
                    label: Text(name),
                    selected: true,
                    onSelected: (_) {},
                  );
                }).toList(),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _isLoading ? null : _createDefaultRooms,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Räume erstellen & loslegen'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/'),
                child: const Text('Überspringen'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createDefaultRooms() async {
    setState(() => _isLoading = true);

    try {
      for (final (name, icon) in _defaultRooms) {
        await ref.read(roomsProvider.notifier).createRoom(
              name: name,
              icon: icon,
            );
      }
      if (mounted) context.go('/');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
