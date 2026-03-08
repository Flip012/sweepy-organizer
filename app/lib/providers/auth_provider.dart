import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_service.dart';

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
  late final AuthService _authService;

  @override
  AuthState build() {
    _authService = AuthService();
    _tryRestore();
    return const AuthState();
  }

  Future<void> _tryRestore() async {
    try {
      final result = await _authService.tryRestore();

      if (result != null) {
        state = AuthState(
          isAuthenticated: true,
          isLoading: false,
          accessToken: result.accessToken,
        );
      } else {
        state = const AuthState(isAuthenticated: false, isLoading: false);
      }
    } catch (e) {
      state = const AuthState(isAuthenticated: false, isLoading: false);
    }
  }

  Future<void> login() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _authService.login();

      if (result != null) {
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
    await _authService.logout();
    state = const AuthState(isAuthenticated: false, isLoading: false);
  }
}
