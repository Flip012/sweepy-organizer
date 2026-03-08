import 'package:dart_frog/dart_frog.dart';
import 'package:server/repositories/user_repository.dart';
import 'package:server/services/auth_service.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response.json(
      statusCode: 405,
      body: {'error': 'Method not allowed'},
    );
  }

  final authUser = context.read<AuthUser>();
  final userRepo = context.read<UserRepository>();

  final members = await userRepo.findByHousehold(authUser.householdId!);

  return Response.json(
    body: {
      'householdId': authUser.householdId,
      'members': members.map((m) => m.toJson()).toList(),
    },
  );
}
