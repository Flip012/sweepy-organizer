import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';
import 'package:server/repositories/task_repository.dart';
import 'package:server/services/auth_service.dart';
import 'package:server/services/websocket_service.dart';

Future<Response> onRequest(RequestContext context) async {
  final authUser = context.read<AuthUser>();
  final taskRepo = context.read<TaskRepository>();

  switch (context.request.method) {
    case HttpMethod.get:
      return _list(context, authUser, taskRepo);
    case HttpMethod.post:
      return _create(context, authUser, taskRepo);
    case HttpMethod.delete:
    case HttpMethod.head:
    case HttpMethod.options:
    case HttpMethod.patch:
    case HttpMethod.put:
      return Response.json(
        statusCode: 405,
        body: {'error': 'Method not allowed'},
      );
  }
}

Future<Response> _list(
  RequestContext context,
  AuthUser authUser,
  TaskRepository taskRepo,
) async {
  final roomId = context.request.uri.queryParameters['roomId'];
  final tasks = await taskRepo.findByHousehold(
    authUser.householdId!,
    roomId: roomId,
  );
  return Response.json(
    body: {'tasks': tasks.map((t) => t.toJson()).toList()},
  );
}

Future<Response> _create(
  RequestContext context,
  AuthUser authUser,
  TaskRepository taskRepo,
) async {
  final body = jsonDecode(await context.request.body()) as Map<String, dynamic>;

  final name = body['name'] as String?;
  final roomId = body['roomId'] as String?;
  if (name == null || name.isEmpty || roomId == null) {
    return Response.json(
      statusCode: 400,
      body: {'error': 'Name and roomId are required'},
    );
  }

  final task = await taskRepo.create(
    roomId: roomId,
    householdId: authUser.householdId!,
    name: name,
    difficulty: body['difficulty'] as int? ?? 1,
    frequencyDays: body['frequencyDays'] as int? ?? 7,
    assignedTo: body['assignedTo'] as String?,
  );

  context.read<WebSocketService>().broadcast(
    authUser.householdId!,
    'task_updated',
    {'action': 'created', 'task': task.toJson()},
  );

  return Response.json(statusCode: 201, body: task.toJson());
}
