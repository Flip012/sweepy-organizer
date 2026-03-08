import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/constants.dart';

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? accessToken;
  final String? error;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = true,
    this.accessToken,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? accessToken,
    String? error,
  }) =>
      AuthState(
        isAuthenticated: isAuthenticated ?? this.isAuthenticated,
        isLoading: isLoading ?? this.isLoading,
        accessToken: accessToken ?? this.accessToken,
        error: error,
      );
}

class AuthNotifier extends Notifier<AuthState> {
  final _appAuth = const FlutterAppAuth();
  final _storage = const FlutterSecureStorage();

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  @override
  AuthState build() {
    _tryRestore();
    return const AuthState();
  }

  Future<void> _tryRestore() async {
    try {
      final accessToken = await _storage.read(key: _accessTokenKey);
      final refreshToken = await _storage.read(key: _refreshTokenKey);

      if (accessToken != null && refreshToken != null) {
        // Try to refresh the token
        try {
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
            state = AuthState(
              isAuthenticated: true,
              isLoading: false,
              accessToken: result.accessToken,
            );
            return;
          }
        } catch (_) {
          // Refresh failed, fall through to unauthenticated
        }
      }

      state = const AuthState(isAuthenticated: false, isLoading: false);
    } catch (e) {
      state = const AuthState(isAuthenticated: false, isLoading: false);
    }
  }

  Future<void> login() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
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
        state = AuthState(
          isAuthenticated: true,
          isLoading: false,
          accessToken: result.accessToken,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Login fehlgeschlagen',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Login-Fehler: ${e.toString()}',
      );
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    state = const AuthState(isAuthenticated: false, isLoading: false);
  }

  Future<void> _saveTokens(String accessToken, String? refreshToken) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    if (refreshToken != null) {
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    }
  }
}
