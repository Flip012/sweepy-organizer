import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/household_provider.dart';
import '../../providers/rooms_provider.dart';
import '../../providers/tasks_provider.dart';
import '../../widgets/difficulty_selector.dart';

class TaskFormScreen extends ConsumerStatefulWidget {
  final String? taskId;
  final String? roomId;

  const TaskFormScreen({super.key, this.taskId, this.roomId});

  @override
  ConsumerState<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends ConsumerState<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  int _difficulty = 1;
  int _frequencyDays = 7;
  String? _selectedRoomId;
  String? _assignedTo;
  bool _isLoading = false;

  bool get _isEditing => widget.taskId != null;

  static const _frequencies = [
    (1, 'Täglich'),
    (2, 'Alle 2 Tage'),
    (3, 'Alle 3 Tage'),
    (7, 'Wöchentlich'),
    (14, 'Alle 2 Wochen'),
    (30, 'Monatlich'),
  ];

  @override
  void initState() {
    super.initState();
    _selectedRoomId = widget.roomId;

    if (_isEditing) {
      final tasks = ref.read(tasksProvider).value ?? [];
      final task = tasks.where((t) => t.id == widget.taskId).firstOrNull;
      if (task != null) {
        _nameController.text = task.name;
        _difficulty = task.difficulty;
        _frequencyDays = task.frequencyDays;
        _selectedRoomId = task.roomId;
        _assignedTo = task.assignedTo;
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
    final rooms = ref.watch(roomsProvider).value ?? [];
    final household = ref.watch(householdProvider).value;
    final members = household?.members ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Aufgabe bearbeiten' : 'Neue Aufgabe'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Aufgabe',
                hintText: 'z.B. Boden wischen, Staub wischen',
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Name ist erforderlich' : null,
              autofocus: !_isEditing,
            ),
            const SizedBox(height: 24),

            // Room selector
            DropdownButtonFormField<String>(
              initialValue: _selectedRoomId,
              decoration: const InputDecoration(labelText: 'Raum'),
              items: rooms
                  .map((r) => DropdownMenuItem(value: r.id, child: Text(r.name)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedRoomId = v),
              validator: (v) => v == null ? 'Raum auswählen' : null,
            ),
            const SizedBox(height: 24),

            // Difficulty
            Text('Schwierigkeit',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            DifficultySelector(
              value: _difficulty,
              onChanged: (v) => setState(() => _difficulty = v),
            ),
            const SizedBox(height: 24),

            // Frequency
            Text('Häufigkeit', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _frequencies.map((entry) {
                final (days, label) = entry;
                return ChoiceChip(
                  selected: _frequencyDays == days,
                  label: Text(label),
                  onSelected: (_) => setState(() => _frequencyDays = days),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Assignment
            if (members.length > 1) ...[
              DropdownButtonFormField<String?>(
                initialValue: _assignedTo,
                decoration: const InputDecoration(
                  labelText: 'Zugewiesen an (optional)',
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Nicht zugewiesen'),
                  ),
                  ...members.map(
                    (m) => DropdownMenuItem(
                      value: m.id,
                      child: Text(m.displayName),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => _assignedTo = v),
              ),
              const SizedBox(height: 24),
            ],

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
        await ref.read(tasksProvider.notifier).updateTask(
              id: widget.taskId!,
              name: _nameController.text,
              difficulty: _difficulty,
              frequencyDays: _frequencyDays,
              assignedTo: _assignedTo,
              clearAssignment: _assignedTo == null,
            );
      } else {
        await ref.read(tasksProvider.notifier).createTask(
              roomId: _selectedRoomId!,
              name: _nameController.text,
              difficulty: _difficulty,
              frequencyDays: _frequencyDays,
              assignedTo: _assignedTo,
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

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aufgabe löschen?'),
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

    if (confirmed == true && mounted) {
      await ref.read(tasksProvider.notifier).deleteTask(widget.taskId!);
      if (mounted) context.pop();
    }
  }
}
