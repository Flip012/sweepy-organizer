class UserProfile {
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

  const UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    required this.authentikGroupId,
    this.totalPoints = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastCompletedDate,
    this.dailyEffortLimit = 6,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        email: json['email'] as String,
        displayName: json['displayName'] as String,
        authentikGroupId: json['authentikGroupId'] as String,
        totalPoints: json['totalPoints'] as int? ?? 0,
        currentStreak: json['currentStreak'] as int? ?? 0,
        longestStreak: json['longestStreak'] as int? ?? 0,
        lastCompletedDate: json['lastCompletedDate'] != null
            ? DateTime.parse(json['lastCompletedDate'] as String)
            : null,
        dailyEffortLimit: json['dailyEffortLimit'] as int? ?? 6,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  UserProfile copyWith({
    String? displayName,
    int? dailyEffortLimit,
    int? totalPoints,
    int? currentStreak,
  }) =>
      UserProfile(
        id: id,
        email: email,
        displayName: displayName ?? this.displayName,
        authentikGroupId: authentikGroupId,
        totalPoints: totalPoints ?? this.totalPoints,
        currentStreak: currentStreak ?? this.currentStreak,
        longestStreak: longestStreak,
        lastCompletedDate: lastCompletedDate,
        dailyEffortLimit: dailyEffortLimit ?? this.dailyEffortLimit,
        createdAt: createdAt,
      );
}
