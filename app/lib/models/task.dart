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

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'] as String,
        roomId: json['roomId'] as String,
        householdId: json['householdId'] as String,
        name: json['name'] as String,
        difficulty: json['difficulty'] as int? ?? 1,
        frequencyDays: json['frequencyDays'] as int? ?? 7,
        lastCompletedAt: json['lastCompletedAt'] != null
            ? DateTime.parse(json['lastCompletedAt'] as String)
            : null,
        lastCompletedBy: json['lastCompletedBy'] as String?,
        assignedTo: json['assignedTo'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'roomId': roomId,
        'name': name,
        'difficulty': difficulty,
        'frequencyDays': frequencyDays,
        'assignedTo': assignedTo,
      };

  double get overdueRatio {
    if (lastCompletedAt == null) return 999.0;
    final daysSince =
        DateTime.now().difference(lastCompletedAt!).inHours / 24.0;
    return daysSince / frequencyDays;
  }

  /// Cleanliness from 0.0 (clean) to 1.0 (dirty)
  double get dirtiness {
    return (overdueRatio).clamp(0.0, 1.0);
  }
}
