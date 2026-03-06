import 'package:dart_frog/dart_frog.dart';
import 'package:server/repositories/task_repository.dart';
import 'package:server/repositories/user_repository.dart';
import 'package:server/services/auth_service.dart';
import 'package:server/services/scheduler_service.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response.json(statusCode: 405, body: {'error': 'Method not allowed'});
  }

  final authUser = context.read<AuthUser>();
  final taskRepo = context.read<TaskRepository>();
  final userRepo = context.read<UserRepository>();
  final scheduler = context.read<SchedulerService>();

  final profile = await userRepo.findById(authUser.id);
  final allTasks = await taskRepo.findByHousehold(authUser.householdId!);

  final scheduled = scheduler.generateDailySchedule(
    tasks: allTasks,
    userId: authUser.id,
    dailyEffortLimit: profile?.dailyEffortLimit ?? 6,
  );

  final totalDifficulty = scheduled.fold<int>(0, (sum, t) => sum + t.difficulty);

  return Response.json(
    body: {
      'tasks': scheduled.map((t) => t.toJson()).toList(),
      'totalDifficulty': totalDifficulty,
      'effortLimit': profile?.dailyEffortLimit ?? 6,
    },
  );
}
