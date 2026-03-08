import 'package:server/models/task.dart';
import 'package:server/services/database_service.dart';

class TaskRepository {

  TaskRepository(this._db);
  final DatabaseService _db;

  Future<List<Task>> findByHousehold(
    String householdId, {
    String? roomId,
  }) async {
    var sql = 'SELECT * FROM tasks WHERE household_id = @householdId';
    final params = <String, dynamic>{'householdId': householdId};

    if (roomId != null) {
      sql += ' AND room_id = @roomId';
      params['roomId'] = roomId;
    }

    sql += ' ORDER BY created_at';

    final result = await _db.query(sql, parameters: params);
    return result.map((row) => Task.fromRow(row.toColumnMap())).toList();
  }

  Future<Task?> findById(String id, String householdId) async {
    final result = await _db.query(
      'SELECT * FROM tasks WHERE id = @id AND household_id = @householdId',
      parameters: {'id': id, 'householdId': householdId},
    );
    if (result.isEmpty) return null;
    return Task.fromRow(result.first.toColumnMap());
  }

  Future<Task> create({
    required String roomId,
    required String householdId,
    required String name,
    int difficulty = 1,
    int frequencyDays = 7,
    String? assignedTo,
  }) async {
    final result = await _db.query(
      '''
      INSERT INTO tasks (room_id, household_id, name, difficulty, frequency_days, assigned_to)
      VALUES (@roomId, @householdId, @name, @difficulty, @frequencyDays, @assignedTo)
      RETURNING *
      ''',
      parameters: {
        'roomId': roomId,
        'householdId': householdId,
        'name': name,
        'difficulty': difficulty,
        'frequencyDays': frequencyDays,
        'assignedTo': assignedTo,
      },
    );
    return Task.fromRow(result.first.toColumnMap());
  }

  Future<Task?> update({
    required String id,
    required String householdId,
    String? name,
    int? difficulty,
    int? frequencyDays,
    String? assignedTo,
    bool clearAssignment = false,
  }) async {
    final sets = <String>[];
    final params = <String, dynamic>{'id': id, 'householdId': householdId};

    if (name != null) {
      sets.add('name = @name');
      params['name'] = name;
    }
    if (difficulty != null) {
      sets.add('difficulty = @difficulty');
      params['difficulty'] = difficulty;
    }
    if (frequencyDays != null) {
      sets.add('frequency_days = @frequencyDays');
      params['frequencyDays'] = frequencyDays;
    }
    if (clearAssignment) {
      sets.add('assigned_to = NULL');
    } else if (assignedTo != null) {
      sets.add('assigned_to = @assignedTo');
      params['assignedTo'] = assignedTo;
    }

    if (sets.isEmpty) return findById(id, householdId);

    final result = await _db.query(
      'UPDATE tasks SET ${sets.join(', ')} '
      'WHERE id = @id '
      'AND household_id = @householdId '
      'RETURNING *',
      parameters: params,
    );
    if (result.isEmpty) return null;
    return Task.fromRow(result.first.toColumnMap());
  }

  Future<Task?> markCompleted(
    String id,
    String householdId,
    String userId,
  ) async {
    final result = await _db.query(
      '''
      UPDATE tasks SET
        last_completed_at = NOW(),
        last_completed_by = @userId
      WHERE id = @id AND household_id = @householdId
      RETURNING *
      ''',
      parameters: {'id': id, 'householdId': householdId, 'userId': userId},
    );
    if (result.isEmpty) return null;
    return Task.fromRow(result.first.toColumnMap());
  }

  Future<bool> delete(String id, String householdId) async {
    final result = await _db.query(
      'DELETE FROM tasks WHERE id = @id AND household_id = @householdId',
      parameters: {'id': id, 'householdId': householdId},
    );
    return result.affectedRows > 0;
  }
}
