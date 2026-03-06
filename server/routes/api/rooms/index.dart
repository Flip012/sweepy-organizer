import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';
import 'package:server/repositories/room_repository.dart';
import 'package:server/services/auth_service.dart';
import 'package:server/services/websocket_service.dart';

Future<Response> onRequest(RequestContext context) async {
  final authUser = context.read<AuthUser>();
  final roomRepo = context.read<RoomRepository>();

  switch (context.request.method) {
    case HttpMethod.get:
      return _list(authUser, roomRepo);
    case HttpMethod.post:
      return _create(context, authUser, roomRepo);
    default:
      return Response.json(statusCode: 405, body: {'error': 'Method not allowed'});
  }
}

Future<Response> _list(AuthUser authUser, RoomRepository roomRepo) async {
  final rooms = await roomRepo.findByHousehold(authUser.householdId!);
  return Response.json(
    body: {'rooms': rooms.map((r) => r.toJson()).toList()},
  );
}

Future<Response> _create(
  RequestContext context,
  AuthUser authUser,
  RoomRepository roomRepo,
) async {
  final body = jsonDecode(await context.request.body()) as Map<String, dynamic>;

  final name = body['name'] as String?;
  if (name == null || name.isEmpty) {
    return Response.json(statusCode: 400, body: {'error': 'Name is required'});
  }

  final room = await roomRepo.create(
    householdId: authUser.householdId!,
    name: name,
    icon: body['icon'] as String? ?? 'home',
    sortOrder: body['sortOrder'] as int? ?? 0,
  );

  context.read<WebSocketService>().broadcast(
    authUser.householdId!,
    'room_updated',
    {'action': 'created', 'room': room.toJson()},
  );

  return Response.json(statusCode: 201, body: room.toJson());
}
