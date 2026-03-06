import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/room.dart';
import 'api_provider.dart';
import 'auth_provider.dart';

final roomsProvider =
    AsyncNotifierProvider<RoomsNotifier, List<Room>>(RoomsNotifier.new);

class RoomsNotifier extends AsyncNotifier<List<Room>> {
  @override
  Future<List<Room>> build() async {
    final auth = ref.watch(authProvider);
    if (!auth.isAuthenticated) return [];

    final api = ref.read(apiClientProvider);
    final data = await api.get('/api/rooms');
    final rooms = (data['rooms'] as List)
        .map((r) => Room.fromJson(r as Map<String, dynamic>))
        .toList();
    return rooms;
  }

  Future<Room> createRoom({
    required String name,
    String icon = 'home',
    int sortOrder = 0,
  }) async {
    final api = ref.read(apiClientProvider);
    final data = await api.post('/api/rooms', body: {
      'name': name,
      'icon': icon,
      'sortOrder': sortOrder,
    });
    final room = Room.fromJson(data);
    state = AsyncData([...state.value ?? [], room]);
    return room;
  }

  Future<void> updateRoom({
    required String id,
    String? name,
    String? icon,
    int? sortOrder,
  }) async {
    final api = ref.read(apiClientProvider);
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (icon != null) body['icon'] = icon;
    if (sortOrder != null) body['sortOrder'] = sortOrder;

    final data = await api.put('/api/rooms/$id', body: body);
    final updated = Room.fromJson(data);
    state = AsyncData(
      (state.value ?? []).map((r) => r.id == id ? updated : r).toList(),
    );
  }

  Future<void> deleteRoom(String id) async {
    final api = ref.read(apiClientProvider);
    await api.delete('/api/rooms/$id');
    state = AsyncData(
      (state.value ?? []).where((r) => r.id != id).toList(),
    );
  }
}
