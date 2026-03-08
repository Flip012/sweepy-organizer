import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:server/repositories/room_repository.dart';
import 'package:server/repositories/task_log_repository.dart';
import 'package:server/repositories/task_repository.dart';
import 'package:server/repositories/user_repository.dart';
import 'package:server/services/auth_service.dart';
import 'package:server/services/database_service.dart';
import 'package:server/services/scheduler_service.dart';
import 'package:server/services/websocket_service.dart';

bool _initialized = false;

Handler middleware(Handler handler) {
  return (context) async {
    // Initialize services once
    if (!_initialized) {
      await DatabaseService.instance().initialize();
      await AuthService.instance().initialize();
      _initialized = true;
    }

    // CORS handling
    final origin =
        Platform.environment['CORS_ORIGIN'] ?? 'http://localhost:3000';
    final response = await _handleCors(context, handler, origin);
    return response;
  };
}

Future<Response> _handleCors(
  RequestContext context,
  Handler handler,
  String origin,
) async {
  // Handle preflight
  if (context.request.method == HttpMethod.options) {
    return Response(
      statusCode: 204,
      headers: _corsHeaders(origin),
    );
  }

  final response = await handler
      .use(provider<DatabaseService>((_) => DatabaseService.instance()))
      .use(provider<AuthService>((_) => AuthService.instance()))
      .use(provider<WebSocketService>((_) => WebSocketService.instance))
      .use(provider<SchedulerService>((_) => const SchedulerService()))
      .use(
        provider<UserRepository>(
          (ctx) => UserRepository(ctx.read<DatabaseService>()),
        ),
      )
      .use(
        provider<RoomRepository>(
          (ctx) => RoomRepository(ctx.read<DatabaseService>()),
        ),
      )
      .use(
        provider<TaskRepository>(
          (ctx) => TaskRepository(ctx.read<DatabaseService>()),
        ),
      )
      .use(
        provider<TaskLogRepository>(
          (ctx) => TaskLogRepository(ctx.read<DatabaseService>()),
        ),
      )
      .call(context);

  return response.copyWith(
    headers: {...response.headers, ..._corsHeaders(origin)},
  );
}

Map<String, String> _corsHeaders(String origin) => {
      'Access-Control-Allow-Origin': origin,
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      'Access-Control-Allow-Credentials': 'true',
    };
