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

  // Already sorted by total_points DESC from the repository
  final leaderboard = members
      .map(
        (m) => {
          'id': m.id,
          'displayName': m.displayName,
          'totalPoints': m.totalPoints,
          'currentStreak': m.currentStreak,
          'longestStreak': m.longestStreak,
        },
      )
      .toList();

  return Response.json(body: {'leaderboard': leaderboard});
}
