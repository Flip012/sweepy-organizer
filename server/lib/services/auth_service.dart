import 'dart:io';

import 'package:jose/jose.dart';

/// Validates OIDC tokens from Authentik and extracts user info + groups.
class AuthService {
  factory AuthService.instance() {
    _instance ??= AuthService._();
    return _instance!;
  }

  AuthService._();
  static AuthService? _instance;
  late JsonWebKeyStore _keyStore;
  String? _issuer;

  Future<void> initialize() async {
    _issuer =
        Platform.environment['AUTHENTIK_ISSUER'] ??
        'https://auth.familyschulze.de/application/o/sweepy/';

    final jwksUri =
        Platform.environment['AUTHENTIK_JWKS_URI'] ??
        'https://auth.familyschulze.de/application/o/sweepy/jwks/';

    _keyStore = JsonWebKeyStore()
      ..addKeySetUrl(Uri.parse(jwksUri));
  }

  /// Validate a Bearer token and return the decoded claims.
  /// Returns null if the token is invalid.
  Future<AuthUser?> validateToken(String token) async {
    try {
      final jwt = await JsonWebToken.decodeAndVerify(token, _keyStore);
      final claims = jwt.claims;

      // Verify issuer
      if (claims.issuer != null &&
          claims.issuer.toString() != _issuer) {
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

  const AuthUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.groups,
  });
  final String id;
  final String email;
  final String displayName;
  final List<String> groups;

  /// The first group is used as the household ID.
  /// In Authentik, users should be assigned to a household group.
  String? get householdId => groups.isNotEmpty ? groups.first : null;
}
