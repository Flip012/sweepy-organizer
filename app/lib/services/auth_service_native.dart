import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../config/constants.dart';
import 'auth_service.dart';

AuthService createAuthService() => NativeAuthService();

class NativeAuthService implements AuthService {
  final _appAuth = const FlutterAppAuth();
  final _storage = const FlutterSecureStorage();

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  bool get _isDesktop =>
      Platform.isLinux || Platform.isMacOS || Platform.isWindows;

  String get _desktopRedirectUri =>
      'http://localhost:${AppConstants.oidcDesktopCallbackPort}/callback';

  @override
  Future<AuthResult?> tryRestore() async {
    final accessToken = await _storage.read(key: _accessTokenKey);
    final refreshToken = await _storage.read(key: _refreshTokenKey);

    if (accessToken == null || refreshToken == null) return null;

    if (_isDesktop) {
      return _desktopTokenRefresh(refreshToken);
    }

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
    if (_isDesktop) {
      return _desktopLogin();
    }

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

  // --- Desktop login flow ---

  Future<AuthResult?> _desktopLogin() async {
    final codeVerifier = _generateCodeVerifier();
    final codeChallenge = _generateCodeChallenge(codeVerifier);

    final server = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      AppConstants.oidcDesktopCallbackPort,
    );

    try {
      final authEndpoint = '${AppConstants.oidcIssuer}authorize/';
      final authUri = Uri.parse(authEndpoint).replace(queryParameters: {
        'response_type': 'code',
        'client_id': AppConstants.oidcClientId,
        'redirect_uri': _desktopRedirectUri,
        'scope': AppConstants.oidcScopes.join(' '),
        'code_challenge': codeChallenge,
        'code_challenge_method': 'S256',
        'prompt': 'login',
      });

      await _openBrowser(authUri.toString());

      // Wait for the actual callback request (ignore favicon etc.)
      String? code;
      await for (final request in server) {
        if (request.uri.path == '/callback' &&
            request.uri.queryParameters.containsKey('code')) {
          code = request.uri.queryParameters['code'];
          request.response
            ..statusCode = 200
            ..headers.contentType = ContentType.html
            ..write(
              '<!DOCTYPE html><html><body>'
              '<h1>Login erfolgreich</h1>'
              '<p>Du kannst dieses Fenster schließen.</p>'
              '</body></html>',
            );
          await request.response.close();
          break;
        } else {
          request.response
            ..statusCode = 404
            ..write('Not found');
          await request.response.close();
        }
      }

      if (code == null) return null;

      return _exchangeCodeForTokens(code, codeVerifier);
    } finally {
      await server.close();
    }
  }

  Future<AuthResult?> _exchangeCodeForTokens(
    String code,
    String codeVerifier,
  ) async {
    final tokenEndpoint = '${AppConstants.oidcIssuer}token/';
    final response = await http.post(
      Uri.parse(tokenEndpoint),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'authorization_code',
        'client_id': AppConstants.oidcClientId,
        'code': code,
        'redirect_uri': _desktopRedirectUri,
        'code_verifier': codeVerifier,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final accessToken = data['access_token'] as String;
      final refreshToken = data['refresh_token'] as String?;
      await _saveTokens(accessToken, refreshToken);
      return AuthResult(accessToken: accessToken, refreshToken: refreshToken);
    }

    return null;
  }

  // --- Desktop token refresh ---

  Future<AuthResult?> _desktopTokenRefresh(String refreshToken) async {
    try {
      final tokenEndpoint = '${AppConstants.oidcIssuer}token/';
      final response = await http.post(
        Uri.parse(tokenEndpoint),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'refresh_token',
          'client_id': AppConstants.oidcClientId,
          'refresh_token': refreshToken,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final newAccessToken = data['access_token'] as String;
        final newRefreshToken = data['refresh_token'] as String?;
        await _saveTokens(newAccessToken, newRefreshToken ?? refreshToken);
        return AuthResult(
          accessToken: newAccessToken,
          refreshToken: newRefreshToken ?? refreshToken,
        );
      }
    } catch (_) {
      // Refresh failed
    }

    return null;
  }

  // --- Helpers ---

  Future<void> _openBrowser(String url) async {
    if (Platform.isLinux) {
      await Process.run('xdg-open', [url]);
    } else if (Platform.isMacOS) {
      await Process.run('open', [url]);
    } else if (Platform.isWindows) {
      await Process.run('cmd', ['/c', 'start', url]);
    }
  }

  String _generateCodeVerifier() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  String _generateCodeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64UrlEncode(digest.bytes).replaceAll('=', '');
  }

  Future<void> _saveTokens(String accessToken, String? refreshToken) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    if (refreshToken != null) {
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    }
  }
}
