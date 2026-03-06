import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../config/constants.dart';
import 'auth_provider.dart';
import 'household_provider.dart';
import 'rooms_provider.dart';
import 'schedule_provider.dart';
import 'tasks_provider.dart';

final websocketProvider = Provider<WebSocketManager>((ref) {
  final manager = WebSocketManager(ref);

  ref.listen<AuthState>(authProvider, (previous, next) {
    if (next.isAuthenticated && next.accessToken != null) {
      manager.connect(next.accessToken!);
    } else {
      manager.disconnect();
    }
  }, fireImmediately: true);

  ref.onDispose(() => manager.disconnect());

  return manager;
});

class WebSocketManager {
  final Ref _ref;
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  WebSocketManager(this._ref);

  void connect(String token) {
    disconnect();

    final wsUrl = AppConstants.apiBaseUrl
        .replaceFirst('http://', 'ws://')
        .replaceFirst('https://', 'wss://');

    _channel = WebSocketChannel.connect(
      Uri.parse('$wsUrl/ws?token=$token'),
    );

    _subscription = _channel!.stream.listen(
      _onMessage,
      onError: (_) => _reconnect(token),
      onDone: () => _reconnect(token),
    );
  }

  void disconnect() {
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
    _subscription = null;
  }

  void _onMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String) as Map<String, dynamic>;
      final type = data['type'] as String?;

      switch (type) {
        case 'task_completed':
          _ref.invalidate(tasksProvider);
          _ref.invalidate(scheduleProvider);
          _ref.invalidate(leaderboardProvider);
          _ref.invalidate(householdProvider);
        case 'room_updated':
          _ref.invalidate(roomsProvider);
        case 'task_updated':
          _ref.invalidate(tasksProvider);
          _ref.invalidate(scheduleProvider);
      }
    } catch (_) {}
  }

  Timer? _reconnectTimer;

  void _reconnect(String token) {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      connect(token);
    });
  }
}
