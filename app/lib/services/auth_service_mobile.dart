import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/constants.dart';
import 'auth_service.dart';

AuthService createAuthService() => MobileAuthService();

class MobileAuthService implements AuthService {
  final _appAuth = const FlutterAppAuth();
  final _storage = const FlutterSecureStorage();

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  @override
  Future<AuthResult?> tryRestore() async {
    final accessToken = await _storage.read(key: _accessTokenKey);
    final refreshToken = await _storage.read(key: _refreshTokenKey);

    if (accessToken == null || refreshToken == null) return null;

    final result = await _appAuth.token(
      TokenRequest(
        AppConstants.oidcClientId,
        AppConstants.oidcRedirectUri,
        issuer: AppConstants.oidcIssuer,
        refreshToken: refreshToken,
        scopes: AppConstants.oidcScopes,
      ),
    );

    if (result.accessToken != null) {
      await _saveTokens(result.accessToken!, result.refreshToken);
      return AuthResult(
        accessToken: result.accessToken!,
        refreshToken: result.refreshToken,
      );
    }

    return null;
  }

  @override
  Future<AuthResult?> login() async {
    final result = await _appAuth.authorizeAndExchangeCode(
      AuthorizationTokenRequest(
        AppConstants.oidcClientId,
        AppConstants.oidcRedirectUri,
        issuer: AppConstants.oidcIssuer,
        scopes: AppConstants.oidcScopes,
        promptValues: ['login'],
      ),
    );

    if (result.accessToken != null) {
      await _saveTokens(result.accessToken!, result.refreshToken);
      return AuthResult(
        accessToken: result.accessToken!,
        refreshToken: result.refreshToken,
      );
    }

    return null;
  }

  @override
  Future<void> logout() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  Future<void> _saveTokens(String accessToken, String? refreshToken) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    if (refreshToken != null) {
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    }
  }
}
