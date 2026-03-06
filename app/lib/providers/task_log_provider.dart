import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/task_log.dart';
import 'api_provider.dart';
import 'auth_provider.dart';

final taskLogProvider = FutureProvider<List<TaskLog>>((ref) async {
  final auth = ref.watch(authProvider);
  if (!auth.isAuthenticated) return [];

  final api = ref.read(apiClientProvider);
  final data = await api.get('/api/history', queryParams: {'limit': '50'});
  return (data['logs'] as List)
      .map((l) => TaskLog.fromJson(l as Map<String, dynamic>))
      .toList();
});
