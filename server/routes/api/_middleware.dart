import 'package:dart_frog/dart_frog.dart';
import 'package:server/repositories/user_repository.dart';
import 'package:server/services/auth_service.dart';

/// Middleware that validates the Bearer token and ensures the user profile exists.
/// Adds the AuthUser to the request context.
Handler middleware(Handler handler) {
  return (context) async {
    final authHeader = context.request.headers['Authorization'];
    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      return Response.json(
        statusCode: 401,
        body: {'error': 'Missing or invalid Authorization header'},
      );
    }

    final token = authHeader.substring(7);
    final authService = context.read<AuthService>();
    final authUser = await authService.validateToken(token);

    if (authUser == null) {
      return Response.json(
        statusCode: 401,
        body: {'error': 'Invalid or expired token'},
      );
    }

    if (authUser.householdId == null) {
      return Response.json(
        statusCode: 403,
        body: {'error': 'User has no household group assigned in Authentik'},
      );
    }

    // Ensure user profile exists in DB
    final userRepo = context.read<UserRepository>();
    await userRepo.upsert(
      id: authUser.id,
      email: authUser.email,
      displayName: authUser.displayName,
      authentikGroupId: authUser.householdId!,
    );

    return handler.use(provider<AuthUser>((_) => authUser)).call(context);
  };
}
