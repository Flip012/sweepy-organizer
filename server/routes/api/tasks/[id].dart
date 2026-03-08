import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';
import 'package:server/repositories/task_repository.dart';
import 'package:server/services/auth_service.dart';
import 'package:server/services/websocket_service.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  final authUser = context.read<AuthUser>();
  final taskRepo = context.read<TaskRepository>();

  switch (context.request.method) {
    case HttpMethod.get:
      return _get(authUser, taskRepo, id);
    case HttpMethod.put:
      return _update(context, authUser, taskRepo, id);
    case HttpMethod.delete:
      return _delete(context, authUser, taskRepo, id);
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
  TaskRepository taskRepo,
  String id,
) async {
  final task = await taskRepo.findById(id, authUser.householdId!);
  if (task == null) {
    return Response.json(statusCode: 404, body: {'error': 'Task not found'});
  }
  return Response.json(body: task.toJson());
}

Future<Response> _update(
  RequestContext context,
  AuthUser authUser,
  TaskRepository taskRepo,
  String id,
) async {
  final body = jsonDecode(await context.request.body()) as Map<String, dynamic>;

  final task = await taskRepo.update(
    id: id,
    householdId: authUser.householdId!,
    name: body['name'] as String?,
    difficulty: body['difficulty'] as int?,
    frequencyDays: body['frequencyDays'] as int?,
    assignedTo: body['assignedTo'] as String?,
    clearAssignment: body['clearAssignment'] as bool? ?? false,
  );

  if (task == null) {
    return Response.json(statusCode: 404, body: {'error': 'Task not found'});
  }

  context.read<WebSocketService>().broadcast(
    authUser.householdId!,
    'task_updated',
    {'action': 'updated', 'task': task.toJson()},
  );

  return Response.json(body: task.toJson());
}

Future<Response> _delete(
  RequestContext context,
  AuthUser authUser,
  TaskRepository taskRepo,
  String id,
) async {
  final deleted = await taskRepo.delete(id, authUser.householdId!);
  if (!deleted) {
    return Response.json(statusCode: 404, body: {'error': 'Task not found'});
  }

  context.read<WebSocketService>().broadcast(
    authUser.householdId!,
    'task_updated',
    {'action': 'deleted', 'taskId': id},
  );

  return Response.json(body: {'success': true});
}
