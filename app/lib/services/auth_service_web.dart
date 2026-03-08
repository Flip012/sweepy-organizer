import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web/web.dart' as web;

import '../config/constants.dart';
import 'auth_service.dart';

AuthService createAuthService() => WebAuthService();

class WebAuthService implements AuthService {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _codeVerifierKey = 'pkce_code_verifier';

  /// Authentik uses shared endpoints under /application/o/ (not per-app slug).
  String get _oidcBaseUrl {
    final issuerUri = Uri.parse(AppConstants.oidcIssuer);
    return '${issuerUri.scheme}://${issuerUri.authority}/application/o';
  }

  @override
  Future<AuthResult?> tryRestore() async {
    // Check if we have a callback code in the URL
    final callbackResult = await _handleCallback();
    if (callbackResult != null) return callbackResult;

    // Try to restore from stored tokens
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString(_refreshTokenKey);

    if (refreshToken == null) return null;

    // Try token refresh
    try {
      final tokenEndpoint = '$_oidcBaseUrl/token/';
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
        await _saveTokens(
            prefs, newAccessToken, newRefreshToken ?? refreshToken);
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

  Future<AuthResult?> _handleCallback() async {
    final uri = Uri.parse(web.window.location.href);
    final code = uri.queryParameters['code'];
    if (code == null) return null;

    final prefs = await SharedPreferences.getInstance();
    final codeVerifier = prefs.getString(_codeVerifierKey);
    if (codeVerifier == null) return null;

    // Exchange code for tokens
    final tokenEndpoint = '$_oidcBaseUrl/token/';
    final response = await http.post(
      Uri.parse(tokenEndpoint),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'authorization_code',
        'client_id': AppConstants.oidcClientId,
        'code': code,
        'redirect_uri': AppConstants.oidcWebRedirectUri,
        'code_verifier': codeVerifier,
      },
    );

    // Clean up PKCE verifier
    await prefs.remove(_codeVerifierKey);

    // Clean URL
    web.window.history.replaceState(null, '', '/');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final accessToken = data['access_token'] as String;
      final refreshToken = data['refresh_token'] as String?;
      await _saveTokens(prefs, accessToken, refreshToken);
      return AuthResult(accessToken: accessToken, refreshToken: refreshToken);
    }

    return null;
  }

  @override
  Future<AuthResult?> login() async {
    final codeVerifier = _generateCodeVerifier();
    final codeChallenge = _generateCodeChallenge(codeVerifier);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_codeVerifierKey, codeVerifier);

    final authEndpoint = '$_oidcBaseUrl/authorize/';
    final authUri = Uri.parse(authEndpoint).replace(queryParameters: {
      'response_type': 'code',
      'client_id': AppConstants.oidcClientId,
      'redirect_uri': AppConstants.oidcWebRedirectUri,
      'scope': AppConstants.oidcScopes.join(' '),
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256',
      'prompt': 'login',
    });

    web.window.location.assign(authUri.toString());

    // Browser will navigate away; this future won't complete
    return null;
  }

  @override
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_codeVerifierKey);
  }

  Future<void> _saveTokens(
    SharedPreferences prefs,
    String accessToken,
    String? refreshToken,
  ) async {
    await prefs.setString(_accessTokenKey, accessToken);
    if (refreshToken != null) {
      await prefs.setString(_refreshTokenKey, refreshToken);
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
}
