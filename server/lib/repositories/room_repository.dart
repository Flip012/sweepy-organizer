import '../models/room.dart';
import '../services/database_service.dart';

class RoomRepository {
  final DatabaseService _db;

  RoomRepository(this._db);

  Future<List<Room>> findByHousehold(String householdId) async {
    final result = await _db.query(
      'SELECT * FROM rooms WHERE household_id = @householdId ORDER BY sort_order, created_at',
      parameters: {'householdId': householdId},
    );
    return result.map((row) => Room.fromRow(row.toColumnMap())).toList();
  }

  Future<Room?> findById(String id, String householdId) async {
    final result = await _db.query(
      'SELECT * FROM rooms WHERE id = @id AND household_id = @householdId',
      parameters: {'id': id, 'householdId': householdId},
    );
    if (result.isEmpty) return null;
    return Room.fromRow(result.first.toColumnMap());
  }

  Future<Room> create({
    required String householdId,
    required String name,
    String icon = 'home',
    int sortOrder = 0,
  }) async {
    final result = await _db.query(
      '''
      INSERT INTO rooms (household_id, name, icon, sort_order)
      VALUES (@householdId, @name, @icon, @sortOrder)
      RETURNING *
      ''',
      parameters: {
        'householdId': householdId,
        'name': name,
        'icon': icon,
        'sortOrder': sortOrder,
      },
    );
    return Room.fromRow(result.first.toColumnMap());
  }

  Future<Room?> update({
    required String id,
    required String householdId,
    String? name,
    String? icon,
    int? sortOrder,
  }) async {
    final sets = <String>[];
    final params = <String, dynamic>{'id': id, 'householdId': householdId};

    if (name != null) {
      sets.add('name = @name');
      params['name'] = name;
    }
    if (icon != null) {
      sets.add('icon = @icon');
      params['icon'] = icon;
    }
    if (sortOrder != null) {
      sets.add('sort_order = @sortOrder');
      params['sortOrder'] = sortOrder;
    }

    if (sets.isEmpty) return findById(id, householdId);

    final result = await _db.query(
      'UPDATE rooms SET ${sets.join(', ')} WHERE id = @id AND household_id = @householdId RETURNING *',
      parameters: params,
    );
    if (result.isEmpty) return null;
    return Room.fromRow(result.first.toColumnMap());
  }

  Future<bool> delete(String id, String householdId) async {
    final result = await _db.query(
      'DELETE FROM rooms WHERE id = @id AND household_id = @householdId',
      parameters: {'id': id, 'householdId': householdId},
    );
    return result.affectedRows > 0;
  }
}
