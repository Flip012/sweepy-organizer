import 'auth_service_stub.dart'
    if (dart.library.io) 'auth_service_mobile.dart'
    if (dart.library.html) 'auth_service_web.dart' as platform;

class AuthResult {
  final String accessToken;
  final String? refreshToken;

  const AuthResult({required this.accessToken, this.refreshToken});
}

abstract class AuthService {
  factory AuthService() => platform.createAuthService();

  Future<AuthResult?> tryRestore();
  Future<AuthResult?> login();
  Future<void> logout();
}
