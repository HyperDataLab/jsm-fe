import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';

/// Token payload from POST /api/v1/oidc/token. Tokens are never logged or
/// shown in UI; they stay in the session store and this data class.
class SsoTokens {
  final String accessToken;
  final String? refreshToken;
  final String? idToken;

  /// Epoch milliseconds when [accessToken] expires.
  final int? expiresAtMs;

  const SsoTokens({
    required this.accessToken,
    this.refreshToken,
    this.idToken,
    this.expiresAtMs,
  });

  Map<String, dynamic> toJson() => {
    'access_token': accessToken,
    if (refreshToken != null) 'refresh_token': refreshToken,
    if (idToken != null) 'id_token': idToken,
    if (expiresAtMs != null) 'expires_at': expiresAtMs,
  };

  factory SsoTokens.fromJson(Map<String, dynamic> json) => SsoTokens(
    accessToken: json['access_token'] as String,
    refreshToken: json['refresh_token'] as String?,
    idToken: json['id_token'] as String?,
    expiresAtMs: json['expires_at'] as int?,
  );

  bool get isExpired =>
      expiresAtMs != null &&
      DateTime.now().millisecondsSinceEpoch >= expiresAtMs!;
}

/// OAuth 2.0 userinfo profile from GET /oauth/userinfo.
class SsoUserInfo {
  final String sub;
  final String? email;
  final String? name;
  final String? picture;
  final String? role;
  final String? studentId;
  final String? major;

  const SsoUserInfo({
    required this.sub,
    this.email,
    this.name,
    this.picture,
    this.role,
    this.studentId,
    this.major,
  });

  Map<String, dynamic> toJson() => {
    'sub': sub,
    if (email != null) 'email': email,
    if (name != null) 'name': name,
    if (picture != null) 'picture': picture,
    if (role != null) 'role': role,
    if (studentId != null) 'student_id': studentId,
    if (major != null) 'major': major,
  };

  factory SsoUserInfo.fromJson(Map<String, dynamic> json) {
    String? resolvedRole;
    final r = json['role'] ?? json['roles'] ?? json['groups'];
    if (r is List && r.isNotEmpty) {
      resolvedRole = r.first.toString();
    } else if (r is String) {
      resolvedRole = r;
    }
    return SsoUserInfo(
      sub: (json['sub'] ?? json['id'] ?? '').toString(),
      email: json['email'] as String?,
      name:
          (json['name'] ?? json['preferred_username'] ?? json['username'])
              as String?,
      picture: (json['picture'] ?? json['avatar']) as String?,
      role: resolvedRole,
      studentId: (json['student_id'] ?? json['studentId']) as String?,
      major: json['major'] as String?,
    );
  }
}

/// HTTP client for the Central SSO token and userinfo endpoints. The
/// [Client] is injected so tests can mock the network.
class OidcApiClient {
  final http.Client _client;

  OidcApiClient({http.Client? client}) : _client = client ?? http.Client();

  /// Decodes the OIDC id_token payload (JWT) to extract user profile
  /// claims without an extra network call (Method 1 in quickstart doc).
  static SsoUserInfo? parseIdToken(String? idToken) {
    if (idToken == null || idToken.isEmpty) return null;
    final parts = idToken.split('.');
    if (parts.length != 3) return null;
    try {
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final map = jsonDecode(decoded) as Map<String, dynamic>;
      final sub = (map['sub'] ?? map['id'])?.toString();
      if (sub != null && sub.isNotEmpty) {
        return SsoUserInfo.fromJson(map);
      }
    } catch (_) {
      // In case of invalid JWT payload, fall through to userinfo endpoint.
    }
    return null;
  }

  /// Exchanges the authorization code (Authorization Code + PKCE flow).
  Future<SsoTokens> exchangeCode({
    required String code,
    required String redirectUri,
    required String codeVerifier,
  }) async {
    final uri = Uri.parse('${ApiEndpoints.ssoIssuer}/oauth/token');
    http.Response response;
    try {
      response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'grant_type': 'authorization_code',
          'client_id': ApiEndpoints.ssoClientId,
          'code': code,
          'redirect_uri': redirectUri,
          'code_verifier': codeVerifier,
        }),
      );
    } catch (e) {
      throw NetworkException('Could not reach the login server.');
    }
    if (response.statusCode != 200) {
      throw ServerException(
        _errorMessage(response) ?? 'Login was rejected by the login server.',
        response.statusCode,
      );
    }
    final Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw const ServerException('Malformed login server response.');
    }
    final accessToken = body['access_token'];
    if (accessToken is! String || accessToken.isEmpty) {
      throw const ServerException('Login response is missing a token.');
    }
    final expiresIn = body['expires_in'];
    return SsoTokens(
      accessToken: accessToken,
      refreshToken: body['refresh_token'] as String?,
      idToken: body['id_token'] as String?,
      expiresAtMs: expiresIn is num
          ? DateTime.now().millisecondsSinceEpoch + (expiresIn * 1000).round()
          : null,
    );
  }

  /// Fetches the canonical user profile.
  Future<SsoUserInfo> fetchUserInfo(String accessToken) async {
    final uri = Uri.parse('${ApiEndpoints.ssoIssuer}/oauth/userinfo');
    http.Response response;
    try {
      response = await _client.get(
        uri,
        headers: {'Authorization': 'Bearer $accessToken'},
      );
    } catch (e) {
      throw NetworkException('Could not reach the login server.');
    }
    if (response.statusCode != 200) {
      throw ServerException(
        _errorMessage(response) ?? 'Could not load the user profile.',
        response.statusCode,
      );
    }
    try {
      return SsoUserInfo.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } catch (_) {
      throw const ServerException('Malformed user profile response.');
    }
  }

  /// Revokes an access token via POST /oauth/revoke.
  Future<bool> revokeToken(String token) async {
    final uri = Uri.parse('${ApiEndpoints.ssoIssuer}/oauth/revoke');
    try {
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': token}),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Extracts a user-safe message from an OIDC-style error body
  /// ({"error": "...", "error_description": "..."}); null if absent.
  static String? _errorMessage(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final description = body['error_description'];
      if (description is String && description.isNotEmpty) {
        return description;
      }
      final error = body['error'];
      if (error is String && error.isNotEmpty) return 'Login failed: $error';
    } catch (_) {
      // Non-JSON error body: caller uses the fallback message.
    }
    return null;
  }
}
