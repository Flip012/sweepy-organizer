import 'package:dart_frog/dart_frog.dart';
import 'package:server/repositories/task_log_repository.dart';
import 'package:server/repositories/task_repository.dart';
import 'package:server/repositories/user_repository.dart';
import 'package:server/services/auth_service.dart';
import 'package:server/services/websocket_service.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.post) {
    return Response.json(
      statusCode: 405,
      body: {'error': 'Method not allowed'},
    );
  }

  final authUser = context.read<AuthUser>();
  final taskRepo = context.read<TaskRepository>();
  final taskLogRepo = context.read<TaskLogRepository>();
  final userRepo = context.read<UserRepository>();

  // Mark task as completed
  final task = await taskRepo.markCompleted(
    id,
    authUser.householdId!,
    authUser.id,
  );

  if (task == null) {
    return Response.json(statusCode: 404, body: {'error': 'Task not found'});
  }

  // Create task log
  final log = await taskLogRepo.create(
    taskId: task.id,
    taskName: task.name,
    roomId: task.roomId,
    householdId: authUser.householdId!,
    completedBy: authUser.id,
    completedByName: authUser.displayName,
    pointsEarned: task.difficulty,
  );

  // Update user points and streak
  await userRepo.addPoints(
    userId: authUser.id,
    points: task.difficulty,
    completedDate: DateTime.now(),
  );

  // Broadcast to household
  context.read<WebSocketService>().broadcast(
    authUser.householdId!,
    'task_completed',
    {
      'task': task.toJson(),
      'log': log.toJson(),
      'completedBy': authUser.displayName,
    },
  );

  return Response.json(
    body: {
      'task': task.toJson(),
      'log': log.toJson(),
      'pointsEarned': task.difficulty,
    },
  );
}
