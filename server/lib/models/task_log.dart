class TaskLog {

  const TaskLog({
    required this.id,
    required this.taskName,
    required this.householdId,
    required this.completedBy,
    required this.completedByName,
    required this.pointsEarned,
    required this.completedAt,
    this.taskId,
    this.roomId,
  });

  factory TaskLog.fromRow(Map<String, dynamic> row) {
    return TaskLog(
      id: row['id'] as String,
      taskId: row['task_id'] as String?,
      taskName: row['task_name'] as String,
      roomId: row['room_id'] as String?,
      householdId: row['household_id'] as String,
      completedBy: row['completed_by'] as String,
      completedByName: row['completed_by_name'] as String,
      pointsEarned: row['points_earned'] as int,
      completedAt: DateTime.parse(row['completed_at'].toString()),
    );
  }
  final String id;
  final String? taskId;
  final String taskName;
  final String? roomId;
  final String householdId;
  final String completedBy;
  final String completedByName;
  final int pointsEarned;
  final DateTime completedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'taskId': taskId,
        'taskName': taskName,
        'roomId': roomId,
        'householdId': householdId,
        'completedBy': completedBy,
        'completedByName': completedByName,
        'pointsEarned': pointsEarned,
        'completedAt': completedAt.toIso8601String(),
      };
}
