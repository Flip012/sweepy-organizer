import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_web_socket/dart_frog_web_socket.dart';
import 'package:server/services/auth_service.dart';

Future<Response> onRequest(RequestContext context) async {
  // Authenticate via query parameter for WebSocket connections
  final token = context.request.uri.queryParameters['token'];
  if (token == null) {
    return Response.json(
      statusCode: 401,
      body: {'error': 'Token required'},
    );
  }

  final authService = context.read<AuthService>();
  final authUser = await authService.validateToken(token);

  if (authUser == null || authUser.householdId == null) {
    return Response.json(
      statusCode: 401,
      body: {'error': 'Invalid token'},
    );
  }

  final householdId = authUser.householdId;

  final handler = webSocketHandler((channel, protocol) {
    channel.stream.listen(
      (message) {
        // Client messages for ping/pong or future features
      },
      onDone: () {
        // Cleanup on disconnect
      },
    );

    // Send initial confirmation
    channel.sink.add(
      '{"type":"connected","householdId":"$householdId"}',
    );
  });

  return handler(context);
}
