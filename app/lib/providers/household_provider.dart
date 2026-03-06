import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_profile.dart';
import 'api_provider.dart';
import 'auth_provider.dart';

class HouseholdState {
  final String? householdId;
  final List<UserProfile> members;

  const HouseholdState({this.householdId, this.members = const []});
}

final householdProvider =
    AsyncNotifierProvider<HouseholdNotifier, HouseholdState>(
  HouseholdNotifier.new,
);

class HouseholdNotifier extends AsyncNotifier<HouseholdState> {
  @override
  Future<HouseholdState> build() async {
    final auth = ref.watch(authProvider);
    if (!auth.isAuthenticated) return const HouseholdState();

    final api = ref.read(apiClientProvider);
    final data = await api.get('/api/household');
    return HouseholdState(
      householdId: data['householdId'] as String?,
      members: (data['members'] as List)
          .map((m) => UserProfile.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }
}

class LeaderboardEntry {
  final String id;
  final String displayName;
  final int totalPoints;
  final int currentStreak;
  final int longestStreak;

  const LeaderboardEntry({
    required this.id,
    required this.displayName,
    required this.totalPoints,
    required this.currentStreak,
    required this.longestStreak,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) =>
      LeaderboardEntry(
        id: json['id'] as String,
        displayName: json['displayName'] as String,
        totalPoints: json['totalPoints'] as int? ?? 0,
        currentStreak: json['currentStreak'] as int? ?? 0,
        longestStreak: json['longestStreak'] as int? ?? 0,
      );
}

final leaderboardProvider =
    FutureProvider<List<LeaderboardEntry>>((ref) async {
  final auth = ref.watch(authProvider);
  if (!auth.isAuthenticated) return [];

  final api = ref.read(apiClientProvider);
  final data = await api.get('/api/household/leaderboard');
  return (data['leaderboard'] as List)
      .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
      .toList();
});
