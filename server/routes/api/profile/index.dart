import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';
import 'package:server/repositories/user_repository.dart';
import 'package:server/services/auth_service.dart';

Future<Response> onRequest(RequestContext context) async {
  final authUser = context.read<AuthUser>();
  final userRepo = context.read<UserRepository>();

  switch (context.request.method) {
    case HttpMethod.get:
      return _get(authUser, userRepo);
    case HttpMethod.put:
      return _put(context, authUser, userRepo);
    case HttpMethod.delete:
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

Future<Response> _get(AuthUser authUser, UserRepository userRepo) async {
  final profile = await userRepo.findById(authUser.id);
  if (profile == null) {
    return Response.json(statusCode: 404, body: {'error': 'Profile not found'});
  }
  return Response.json(body: profile.toJson());
}

Future<Response> _put(
  RequestContext context,
  AuthUser authUser,
  UserRepository userRepo,
) async {
  final body = jsonDecode(await context.request.body()) as Map<String, dynamic>;

  final profile = await userRepo.updateProfile(
    id: authUser.id,
    displayName: body['displayName'] as String?,
    dailyEffortLimit: body['dailyEffortLimit'] as int?,
  );

  if (profile == null) {
    return Response.json(statusCode: 404, body: {'error': 'Profile not found'});
  }
  return Response.json(body: profile.toJson());
}
