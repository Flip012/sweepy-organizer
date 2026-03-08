class UserProfile {

  const UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    required this.authentikGroupId,
    required this.createdAt,
    this.totalPoints = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastCompletedDate,
    this.dailyEffortLimit = 6,
  });

  factory UserProfile.fromRow(Map<String, dynamic> row) {
    return UserProfile(
      id: row['id'] as String,
      email: row['email'] as String,
      displayName: row['display_name'] as String,
      authentikGroupId: row['authentik_group_id'] as String,
      totalPoints: row['total_points'] as int? ?? 0,
      currentStreak: row['current_streak'] as int? ?? 0,
      longestStreak: row['longest_streak'] as int? ?? 0,
      lastCompletedDate: row['last_completed_date'] != null
          ? DateTime.parse(row['last_completed_date'].toString())
          : null,
      dailyEffortLimit: row['daily_effort_limit'] as int? ?? 6,
      createdAt: DateTime.parse(row['created_at'].toString()),
    );
  }
  final String id;
  final String email;
  final String displayName;
  final String authentikGroupId;
  final int totalPoints;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastCompletedDate;
  final int dailyEffortLimit;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'displayName': displayName,
        'authentikGroupId': authentikGroupId,
        'totalPoints': totalPoints,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'lastCompletedDate': lastCompletedDate?.toIso8601String(),
        'dailyEffortLimit': dailyEffortLimit,
        'createdAt': createdAt.toIso8601String(),
      };
}
