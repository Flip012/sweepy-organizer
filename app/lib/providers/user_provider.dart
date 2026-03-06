import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/api_client.dart';
import '../models/user_profile.dart';
import 'api_provider.dart';
import 'auth_provider.dart';

final userProfileProvider =
    AsyncNotifierProvider<UserProfileNotifier, UserProfile?>(
  UserProfileNotifier.new,
);

class UserProfileNotifier extends AsyncNotifier<UserProfile?> {
  @override
  Future<UserProfile?> build() async {
    final auth = ref.watch(authProvider);
    if (!auth.isAuthenticated) return null;

    final api = ref.read(apiClientProvider);
    try {
      final data = await api.get('/api/profile');
      return UserProfile.fromJson(data);
    } on ApiException {
      return null;
    }
  }

  Future<void> updateProfile({String? displayName, int? dailyEffortLimit}) async {
    final api = ref.read(apiClientProvider);
    final body = <String, dynamic>{};
    if (displayName != null) body['displayName'] = displayName;
    if (dailyEffortLimit != null) body['dailyEffortLimit'] = dailyEffortLimit;

    final data = await api.put('/api/profile', body: body);
    state = AsyncData(UserProfile.fromJson(data));
  }
}
