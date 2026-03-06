class Task {
  final String id;
  final String roomId;
  final String householdId;
  final String name;
  final int difficulty;
  final int frequencyDays;
  final DateTime? lastCompletedAt;
  final String? lastCompletedBy;
  final String? assignedTo;
  final DateTime createdAt;

  const Task({
    required this.id,
    required this.roomId,
    required this.householdId,
    required this.name,
    this.difficulty = 1,
    this.frequencyDays = 7,
    this.lastCompletedAt,
    this.lastCompletedBy,
    this.assignedTo,
    required this.createdAt,
  });

  factory Task.fromRow(Map<String, dynamic> row) {
    return Task(
      id: row['id'] as String,
      roomId: row['room_id'] as String,
      householdId: row['household_id'] as String,
      name: row['name'] as String,
      difficulty: row['difficulty'] as int? ?? 1,
      frequencyDays: row['frequency_days'] as int? ?? 7,
      lastCompletedAt: row['last_completed_at'] != null
          ? DateTime.parse(row['last_completed_at'].toString())
          : null,
      lastCompletedBy: row['last_completed_by'] as String?,
      assignedTo: row['assigned_to'] as String?,
      createdAt: DateTime.parse(row['created_at'].toString()),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'roomId': roomId,
        'householdId': householdId,
        'name': name,
        'difficulty': difficulty,
        'frequencyDays': frequencyDays,
        'lastCompletedAt': lastCompletedAt?.toIso8601String(),
        'lastCompletedBy': lastCompletedBy,
        'assignedTo': assignedTo,
        'createdAt': createdAt.toIso8601String(),
      };

  /// Calculate how overdue this task is (ratio > 1.0 means past due)
  double get overdueRatio {
    if (lastCompletedAt == null) return 999.0;
    final daysSince =
        DateTime.now().difference(lastCompletedAt!).inHours / 24.0;
    return daysSince / frequencyDays;
  }
}
