import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/api_client.dart';
import '../config/constants.dart';
import 'auth_provider.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final apiClient = ApiClient(baseUrl: AppConstants.apiBaseUrl);

  ref.listen<AuthState>(authProvider, (previous, next) {
    if (next.accessToken != null) {
      apiClient.setToken(next.accessToken!);
    } else {
      apiClient.clearToken();
    }
  }, fireImmediately: true);

  return apiClient;
});
