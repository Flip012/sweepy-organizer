class AppConstants {
  // These should be configured via environment or build config
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  static const oidcIssuer = String.fromEnvironment(
    'OIDC_ISSUER',
    defaultValue: 'http://localhost:9000/application/o/sweepy/',
  );

  static const oidcClientId = String.fromEnvironment(
    'OIDC_CLIENT_ID',
    defaultValue: 'sweepy-app',
  );

  static const oidcRedirectUri = String.fromEnvironment(
    'OIDC_REDIRECT_URI',
    defaultValue: 'com.sweepy.app://callback',
  );

  static const oidcWebRedirectUri = String.fromEnvironment(
    'OIDC_WEB_REDIRECT_URI',
    defaultValue: 'http://localhost:3000/callback',
  );

  static const oidcScopes = ['openid', 'profile', 'email', 'offline_access'];
}
