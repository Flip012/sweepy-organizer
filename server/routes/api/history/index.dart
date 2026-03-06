import 'package:dart_frog/dart_frog.dart';
import 'package:server/repositories/task_log_repository.dart';
import 'package:server/services/auth_service.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response.json(statusCode: 405, body: {'error': 'Method not allowed'});
  }

  final authUser = context.read<AuthUser>();
  final taskLogRepo = context.read<TaskLogRepository>();

  final params = context.request.uri.queryParameters;
  final limit = int.tryParse(params['limit'] ?? '') ?? 50;
  final offset = int.tryParse(params['offset'] ?? '') ?? 0;

  final logs = await taskLogRepo.findByHousehold(
    authUser.householdId!,
    limit: limit,
    offset: offset,
  );

  return Response.json(
    body: {'logs': logs.map((l) => l.toJson()).toList()},
  );
}
