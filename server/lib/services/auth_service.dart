import 'dart:io';

import 'package:jose/jose.dart';

/// Validates OIDC tokens from Authentik and extracts user info + groups.
class AuthService {
  AuthService._();
  static AuthService? _instance;
  JsonWebKeyStore? _keyStore;
  String? _issuer;

  static AuthService get instance {
    _instance ??= AuthService._();
    return _instance!;
  }

  Future<void> initialize() async {
    _issuer =
        Platform.environment['AUTHENTIK_ISSUER'] ??
        'http://localhost:9000/application/o/sweepy/';

    final jwksUri =
        Platform.environment['AUTHENTIK_JWKS_URI'] ??
        'http://localhost:9000/application/o/sweepy/jwks/';

    _keyStore = JsonWebKeyStore()..addKeySetUrl(Uri.parse(jwksUri));
  }

  /// Validate a Bearer token and return the decoded claims.
  /// Returns null if the token is invalid.
  Future<AuthUser?> validateToken(String token) async {
    try {
      final jwt = await JsonWebToken.decodeAndVerify(token, _keyStore!);
      final claims = jwt.claims;

      // Verify issuer
      if (claims.issuer != null && claims.issuer != _issuer) {
        return null;
      }

      // Check expiry
      if (claims.expiry != null && claims.expiry!.isBefore(DateTime.now())) {
        return null;
      }

      final claimsMap = claims.toJson();
      final sub = claimsMap['sub'] as String?;
      final email = claimsMap['email'] as String?;
      final name =
          claimsMap['name'] as String? ??
          claimsMap['preferred_username'] as String? ??
          email ??
          'Unknown';

      // Extract groups from Authentik token
      final groups = <String>[];
      if (claimsMap['groups'] is List) {
        groups.addAll(
          (claimsMap['groups'] as List).map((g) => g.toString()),
        );
      }

      if (sub == null || email == null) return null;

      return AuthUser(
        id: sub,
        email: email,
        displayName: name,
        groups: groups,
      );
    } catch (e) {
      return null;
    }
  }
}

class AuthUser {
  final String id;
  final String email;
  final String displayName;
  final List<String> groups;

  const AuthUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.groups,
  });

  /// The first group is used as the household ID.
  /// In Authentik, users should be assigned to a household group.
  String? get householdId => groups.isNotEmpty ? groups.first : null;
}
