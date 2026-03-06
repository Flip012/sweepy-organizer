import 'dart:convert';
import 'dart:io';

/// Manages WebSocket connections grouped by household ID.
/// Broadcasts events to all connected clients in the same household.
class WebSocketService {
  WebSocketService._();
  static final WebSocketService instance = WebSocketService._();

  // householdId -> set of connected WebSockets
  final Map<String, Set<WebSocket>> _connections = {};

  void addConnection(String householdId, WebSocket socket) {
    _connections.putIfAbsent(householdId, () => {});
    _connections[householdId]!.add(socket);

    socket.done.then((_) {
      removeConnection(householdId, socket);
    });
  }

  void removeConnection(String householdId, WebSocket socket) {
    _connections[householdId]?.remove(socket);
    if (_connections[householdId]?.isEmpty ?? false) {
      _connections.remove(householdId);
    }
  }

  /// Broadcast an event to all clients in a household.
  void broadcast(String householdId, String eventType, Map<String, dynamic> data) {
    final message = jsonEncode({
      'type': eventType,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    });

    final sockets = _connections[householdId];
    if (sockets == null) return;

    final toRemove = <WebSocket>[];
    for (final socket in sockets) {
      try {
        socket.add(message);
      } catch (_) {
        toRemove.add(socket);
      }
    }
    for (final socket in toRemove) {
      removeConnection(householdId, socket);
    }
  }
}
