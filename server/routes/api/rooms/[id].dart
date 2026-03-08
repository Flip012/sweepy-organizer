import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';
import 'package:server/repositories/room_repository.dart';
import 'package:server/services/auth_service.dart';
import 'package:server/services/websocket_service.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  final authUser = context.read<AuthUser>();
  final roomRepo = context.read<RoomRepository>();

  switch (context.request.method) {
    case HttpMethod.get:
      return _get(authUser, roomRepo, id);
    case HttpMethod.put:
      return _update(context, authUser, roomRepo, id);
    case HttpMethod.delete:
      return _delete(context, authUser, roomRepo, id);
    case HttpMethod.head:
    case HttpMethod.options:
    case HttpMethod.patch:
    case HttpMethod.post:
      return Response.json(
        statusCode: 405,
        body: {'error': 'Method not allowed'},
      );
  }
}

Future<Response> _get(
  AuthUser authUser,
  RoomRepository roomRepo,
  String id,
) async {
  final room = await roomRepo.findById(id, authUser.householdId!);
  if (room == null) {
    return Response.json(statusCode: 404, body: {'error': 'Room not found'});
  }
  return Response.json(body: room.toJson());
}

Future<Response> _update(
  RequestContext context,
  AuthUser authUser,
  RoomRepository roomRepo,
  String id,
) async {
  final body = jsonDecode(await context.request.body()) as Map<String, dynamic>;

  final room = await roomRepo.update(
    id: id,
    householdId: authUser.householdId!,
    name: body['name'] as String?,
    icon: body['icon'] as String?,
    sortOrder: body['sortOrder'] as int?,
  );

  if (room == null) {
    return Response.json(statusCode: 404, body: {'error': 'Room not found'});
  }

  context.read<WebSocketService>().broadcast(
    authUser.householdId!,
    'room_updated',
    {'action': 'updated', 'room': room.toJson()},
  );

  return Response.json(body: room.toJson());
}

Future<Response> _delete(
  RequestContext context,
  AuthUser authUser,
  RoomRepository roomRepo,
  String id,
) async {
  final deleted = await roomRepo.delete(id, authUser.householdId!);
  if (!deleted) {
    return Response.json(statusCode: 404, body: {'error': 'Room not found'});
  }

  context.read<WebSocketService>().broadcast(
    authUser.householdId!,
    'room_updated',
    {'action': 'deleted', 'roomId': id},
  );

  return Response.json(body: {'success': true});
}
