import '../models/user_profile.dart';
import '../services/database_service.dart';

class UserRepository {
  final DatabaseService _db;

  UserRepository(this._db);

  Future<UserProfile?> findById(String id) async {
    final result = await _db.query(
      'SELECT * FROM user_profiles WHERE id = @id',
      parameters: {'id': id},
    );
    if (result.isEmpty) return null;
    return UserProfile.fromRow(result.first.toColumnMap());
  }

  Future<UserProfile> upsert({
    required String id,
    required String email,
    required String displayName,
    required String authentikGroupId,
  }) async {
    final result = await _db.query(
      '''
      INSERT INTO user_profiles (id, email, display_name, authentik_group_id)
      VALUES (@id, @email, @displayName, @groupId)
      ON CONFLICT (id) DO UPDATE SET
        email = @email,
        display_name = COALESCE(NULLIF(@displayName, ''), user_profiles.display_name),
        authentik_group_id = @groupId
      RETURNING *
      ''',
      parameters: {
        'id': id,
        'email': email,
        'displayName': displayName,
        'groupId': authentikGroupId,
      },
    );
    return UserProfile.fromRow(result.first.toColumnMap());
  }

  Future<UserProfile?> updateProfile({
    required String id,
    String? displayName,
    int? dailyEffortLimit,
  }) async {
    final sets = <String>[];
    final params = <String, dynamic>{'id': id};

    if (displayName != null) {
      sets.add('display_name = @displayName');
      params['displayName'] = displayName;
    }
    if (dailyEffortLimit != null) {
      sets.add('daily_effort_limit = @dailyEffortLimit');
      params['dailyEffortLimit'] = dailyEffortLimit;
    }

    if (sets.isEmpty) return findById(id);

    final result = await _db.query(
      'UPDATE user_profiles SET ${sets.join(', ')} WHERE id = @id RETURNING *',
      parameters: params,
    );
    if (result.isEmpty) return null;
    return UserProfile.fromRow(result.first.toColumnMap());
  }

  Future<List<UserProfile>> findByHousehold(String householdId) async {
    final result = await _db.query(
      'SELECT * FROM user_profiles WHERE authentik_group_id = @householdId ORDER BY total_points DESC',
      parameters: {'householdId': householdId},
    );
    return result.map((row) => UserProfile.fromRow(row.toColumnMap())).toList();
  }

  Future<void> addPoints({
    required String userId,
    required int points,
    required DateTime completedDate,
  }) async {
    // Get current profile for streak calculation
    final profile = await findById(userId);
    if (profile == null) return;

    final today = DateTime(
      completedDate.year,
      completedDate.month,
      completedDate.day,
    );
    final lastDate = profile.lastCompletedDate;

    int newStreak = profile.currentStreak;
    if (lastDate == null) {
      newStreak = 1;
    } else {
      final lastDay = DateTime(lastDate.year, lastDate.month, lastDate.day);
      final diff = today.difference(lastDay).inDays;
      if (diff == 1) {
        newStreak = profile.currentStreak + 1;
      } else if (diff > 1) {
        newStreak = 1;
      }
      // diff == 0 means same day, keep streak as is
    }

    final longestStreak =
        newStreak > profile.longestStreak ? newStreak : profile.longestStreak;

    await _db.query(
      '''
      UPDATE user_profiles SET
        total_points = total_points + @points,
        current_streak = @streak,
        longest_streak = @longestStreak,
        last_completed_date = @completedDate
      WHERE id = @userId
      ''',
      parameters: {
        'points': points,
        'streak': newStreak,
        'longestStreak': longestStreak,
        'completedDate': today.toIso8601String().substring(0, 10),
        'userId': userId,
      },
    );
  }
}
