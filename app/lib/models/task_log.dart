class TaskLog {
  final String id;
  final String? taskId;
  final String taskName;
  final String? roomId;
  final String householdId;
  final String completedBy;
  final String completedByName;
  final int pointsEarned;
  final DateTime completedAt;

  const TaskLog({
    required this.id,
    this.taskId,
    required this.taskName,
    this.roomId,
    required this.householdId,
    required this.completedBy,
    required this.completedByName,
    required this.pointsEarned,
    required this.completedAt,
  });

  factory TaskLog.fromJson(Map<String, dynamic> json) => TaskLog(
        id: json['id'] as String,
        taskId: json['taskId'] as String?,
        taskName: json['taskName'] as String,
        roomId: json['roomId'] as String?,
        householdId: json['householdId'] as String,
        completedBy: json['completedBy'] as String,
        completedByName: json['completedByName'] as String,
        pointsEarned: json['pointsEarned'] as int,
        completedAt: DateTime.parse(json['completedAt'] as String),
      );
}
