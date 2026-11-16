import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/auth_provider.dart';

/// Pure-PKCE/state/URL helpers for the Central SSO Authorization Code +
/// PKCE (S256) flow. No platform or network code lives here so it is fully
/// unit-testable.
class OidcAuthUrlBuilder {
  const OidcAuthUrlBuilder();

  /// Cryptographically secure random string (URL-safe), [length] chars.
  static String _randomString(int length) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final rnd = Random.secure();
    return List.generate(
      length,
      (_) => chars[rnd.nextInt(chars.length)],
    ).join();
  }

  static String createCodeVerifier() => _randomString(64);
  static String createState() => _randomString(32);

  /// code_challenge = BASE64URL(SHA256(code_verifier)), no padding.
  static String createCodeChallenge(String codeVerifier) => base64Url
      .encode(sha256.convert(utf8.encode(codeVerifier)).bytes)
      .replaceAll('=', '');

  /// A pending authorization request: the state and PKCE verifier that must
  /// be persisted (sessionStorage on web) before redirecting away.
  static ({String state, String codeVerifier}) createPendingRequest() =>
      (state: createState(), codeVerifier: createCodeVerifier());

  /// Builds the SSO authorize URL for [provider] (provider only affects the
  /// SSO login page's own options; all providers go through the same
  /// OIDC authorize endpoint) with [redirectUri].
  String build({
    required AuthProvider provider,
    required String redirectUri,
    required String state,
    required String codeChallenge,
  }) {
    final params = {
      'client_id': ApiEndpoints.ssoClientId,
      'redirect_uri': redirectUri,
      'response_type': 'code',
      'scope': 'email profile hyperdatalab_profile',
      'state': state,
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256',
    };
    final query = params.entries
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
        )
        .join('&');
    return '${ApiEndpoints.ssoIssuer}/oauth/authorize?$query';
  }
}

/// Parsed /auth/callback query parameters.
class AuthCallback {
  final String code;
  final String state;

  const AuthCallback({required this.code, required this.state});
}

/// Parses and validates the callback URL against the state we stored before
/// redirecting. Throws [ServerException] when the callback is unusable —
/// never returns a partially valid result.
AuthCallback parseAuthCallback(Uri uri, {required String? storedState}) {
  if (storedState == null || storedState.isEmpty) {
    throw const ServerException('Invalid login session state.');
  }
  final error = uri.queryParameters['error'];
  if (error != null) {
    throw ServerException('Login failed: $error');
  }
  final code = uri.queryParameters['code'];
  final state = uri.queryParameters['state'];
  if (code == null || code.isEmpty) {
    throw const ServerException('Login callback is missing a code.');
  }
  if (state == null || state != storedState) {
    throw const ServerException('Login session state mismatch.');
  }
  return AuthCallback(code: code, state: state);
}
