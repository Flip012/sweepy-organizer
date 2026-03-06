import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/rooms_provider.dart';

class RoomFormScreen extends ConsumerStatefulWidget {
  final String? roomId;

  const RoomFormScreen({super.key, this.roomId});

  @override
  ConsumerState<RoomFormScreen> createState() => _RoomFormScreenState();
}

class _RoomFormScreenState extends ConsumerState<RoomFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedIcon = 'home';
  bool _isLoading = false;

  bool get _isEditing => widget.roomId != null;

  static const _icons = [
    ('home', 'Allgemein', Icons.home),
    ('kitchen', 'Küche', Icons.kitchen),
    ('bathroom', 'Bad', Icons.bathroom),
    ('bedroom', 'Schlafzimmer', Icons.bed),
    ('living_room', 'Wohnzimmer', Icons.living),
    ('dining_room', 'Esszimmer', Icons.dining),
    ('garage', 'Garage', Icons.garage),
    ('garden', 'Garten', Icons.yard),
    ('office', 'Büro', Icons.work),
    ('laundry', 'Waschküche', Icons.local_laundry_service),
    ('hallway', 'Flur', Icons.door_front_door),
    ('balcony', 'Balkon', Icons.balcony),
  ];

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final rooms = ref.read(roomsProvider).value ?? [];
      final room = rooms.where((r) => r.id == widget.roomId).firstOrNull;
      if (room != null) {
        _nameController.text = room.name;
        _selectedIcon = room.icon;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Raum bearbeiten' : 'Neuer Raum'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'z.B. Küche, Bad, Wohnzimmer',
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Name ist erforderlich' : null,
              autofocus: !_isEditing,
            ),
            const SizedBox(height: 24),
            Text(
              'Symbol',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _icons.map((entry) {
                final (key, label, icon) = entry;
                final isSelected = key == _selectedIcon;
                return FilterChip(
                  selected: isSelected,
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 18),
                      const SizedBox(width: 4),
                      Text(label),
                    ],
                  ),
                  onSelected: (_) => setState(() => _selectedIcon = key),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _isLoading ? null : _save,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEditing ? 'Speichern' : 'Erstellen'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_isEditing) {
        await ref.read(roomsProvider.notifier).updateRoom(
              id: widget.roomId!,
              name: _nameController.text,
              icon: _selectedIcon,
            );
      } else {
        await ref.read(roomsProvider.notifier).createRoom(
              name: _nameController.text,
              icon: _selectedIcon,
            );
      }

      if (mounted) context.pop();
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
