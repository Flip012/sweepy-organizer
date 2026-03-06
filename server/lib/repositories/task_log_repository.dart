import '../models/task_log.dart';
import '../services/database_service.dart';

class TaskLogRepository {
  final DatabaseService _db;

  TaskLogRepository(this._db);

  Future<TaskLog> create({
    required String taskId,
    required String taskName,
    required String roomId,
    required String householdId,
    required String completedBy,
    required String completedByName,
    required int pointsEarned,
  }) async {
    final result = await _db.query(
      '''
      INSERT INTO task_logs (task_id, task_name, room_id, household_id, completed_by, completed_by_name, points_earned)
      VALUES (@taskId, @taskName, @roomId, @householdId, @completedBy, @completedByName, @pointsEarned)
      RETURNING *
      ''',
      parameters: {
        'taskId': taskId,
        'taskName': taskName,
        'roomId': roomId,
        'householdId': householdId,
        'completedBy': completedBy,
        'completedByName': completedByName,
        'pointsEarned': pointsEarned,
      },
    );
    return TaskLog.fromRow(result.first.toColumnMap());
  }

  Future<List<TaskLog>> findByHousehold(
    String householdId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final result = await _db.query(
      '''
      SELECT * FROM task_logs
      WHERE household_id = @householdId
      ORDER BY completed_at DESC
      LIMIT @limit OFFSET @offset
      ''',
      parameters: {
        'householdId': householdId,
        'limit': limit,
        'offset': offset,
      },
    );
    return result.map((row) => TaskLog.fromRow(row.toColumnMap())).toList();
  }
}
