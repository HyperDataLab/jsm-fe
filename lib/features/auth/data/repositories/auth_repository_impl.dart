import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import '../../../../core/constants/api_endpoints.dart';
import '../../domain/entities/auth_provider.dart';
import '../../domain/entities/auth_result.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/auth_launcher.dart';
import '../datasources/browser_sso_seam.dart';
import '../datasources/desktop_sso_launcher.dart';
import '../datasources/sso_auth_launcher.dart';
import '../datasources/sso_session_store.dart';

/// Auth repository backed by the Central SSO (OIDC Authorization Code +
/// PKCE) launcher. All browser/network details live behind [AuthLauncher];
/// tokens never leave this layer.
class AuthRepositoryImpl implements AuthRepository {
  final AuthLauncher launcher;
  final http.Client? httpClient;

  AuthRepositoryImpl({AuthLauncher? launcher, this.httpClient})
    : launcher =
          launcher ??
          // Web: the browser navigates to the SSO page and back.
          // Desktop: the system browser opens; a loopback server on the
          // configured redirect port receives the callback in-process.
          (kIsWeb ? SsoAuthLauncher() : DesktopSsoLauncher());

  @override
  Future<void> login(AuthProvider provider) async {
    // Web: the browser navigates away to the SSO authorize page; the flow
    // completes later via [handleCallback] on the /auth/callback page load.
    // Desktop: [DesktopSsoLauncher] opens the system browser and waits for
    // the loopback callback, completing the exchange before returning.
    await launcher.start(provider);
    final desktop = launcher;
    if (desktop is DesktopSsoLauncher) {
      await desktop.awaitCallbackAndComplete();
    }
  }

  /// True when the current page load is the SSO /auth/callback (app start
  /// after the browser redirected back). Requires both the callback path
  /// and authorization code/error query parameters so normal reloads (F5)
  /// or navigations without code are not mistakenly treated as pending callbacks.
  bool isOnCallbackPage() {
    final uri = BrowserSso.currentUri();
    final isCallbackPath =
        uri.path == '/auth/callback' || uri.path.endsWith('/auth/callback');
    final hasCallbackParams =
        uri.queryParameters.containsKey('code') ||
        uri.queryParameters.containsKey('error');
    return isCallbackPath && hasCallbackParams;
  }

  /// Processes the callback page load: validates state, exchanges the code
  /// with PKCE, fetches userinfo. Returns the authenticated result, or
  /// null if this page load is not a callback.
  @override
  Future<AuthResult?> handleCallback() async {
    if (!isOnCallbackPage()) return null;
    final result = await launcher.completeFromCallback();
    final session = await restoreSession();
    return AuthResult(user: session?.user ?? result.user);
  }

  @override
  Future<AuthSession?> restoreSession() async {
    final ssoLauncher = launcher;
    if (ssoLauncher is SsoAuthLauncher) {
      if (ApiEndpoints.localDesktopEnabled) {
        final localSession = await _restoreLocalSession(ssoLauncher);
        if (localSession != null) return localSession;
      }

      final snapshot = await ssoLauncher.restoreStoredSession();
      if (snapshot == null) return null;
      final ssoUser = AuthUser(
        sub: snapshot.userInfo.sub,
        email: snapshot.userInfo.email,
        name: snapshot.userInfo.name,
        picture: snapshot.userInfo.picture,
        role: snapshot.userInfo.role,
      );
      if (ApiEndpoints.localDesktopEnabled) {
        return _exchangeForLocalSession(ssoLauncher, ssoUser, snapshot.tokens.accessToken);
      }
      return AuthSession(
        user: await _fetchBackendUser(ssoUser, snapshot.tokens.accessToken),
        accessToken: snapshot.tokens.accessToken,
        refreshToken: snapshot.tokens.refreshToken,
      );
    }
    return null;
  }

  @override
  Future<void> logout() async {
    final ssoLauncher = launcher;
    if (ssoLauncher is SsoAuthLauncher) {
      ssoLauncher.store.remove(SsoSessionKeys.localSession);
      ssoLauncher.clearSession();
    }
    // Attempt best-effort SSO server session invalidation
    try {
      final client = httpClient ?? http.Client();
      final uri = Uri.parse('${ApiEndpoints.ssoIssuer}/api/v1/auth/logout');
      await client.post(uri).timeout(const Duration(seconds: 3));
    } catch (_) {
      // Local session is cleared; ignore network/logout errors
    }
  }

  @override
  Future<String?> currentToken() async {
    final ssoLauncher = launcher;
    if (ssoLauncher is! SsoAuthLauncher) return null;
    if (ApiEndpoints.localDesktopEnabled) {
      final stored = ssoLauncher.store.read(SsoSessionKeys.localSession);
      if (stored != null) {
        try {
          final data = jsonDecode(stored) as Map<String, dynamic>;
          final expiry = data['expires_at'] as int?;
          if (expiry != null && expiry > DateTime.now().millisecondsSinceEpoch) {
            return data['access_token'] as String?;
          }
        } catch (_) {}
      }
    }
    final snapshot = await ssoLauncher.restoreStoredSession();
    return snapshot?.tokens.accessToken;
  }

  Future<AuthSession?> _restoreLocalSession(SsoAuthLauncher ssoLauncher) async {
    final serialized = ssoLauncher.store.read(SsoSessionKeys.localSession);
    if (serialized == null) return null;
    try {
      final data = jsonDecode(serialized) as Map<String, dynamic>;
      final expiry = data['expires_at'] as int?;
      final token = data['access_token'] as String?;
      if (expiry == null || token == null ||
          expiry <= DateTime.now().millisecondsSinceEpoch) {
        ssoLauncher.store.remove(SsoSessionKeys.localSession);
        if (expiry != null && expiry <= DateTime.now().millisecondsSinceEpoch) {
          ssoLauncher.store.remove(SsoSessionKeys.tokens);
          ssoLauncher.store.remove(SsoSessionKeys.user);
        }
        return null;
      }
      final rawUser = data['user'] as Map<String, dynamic>? ?? const {};
      final user = AuthUser(
        sub: (rawUser['sub'] ?? rawUser['id'] ?? '').toString(),
        email: rawUser['email'] as String?,
        name: (rawUser['name'] ?? rawUser['full_name']) as String?,
        role: rawUser['role'] as String?,
      );
      return AuthSession(
        user: await _fetchBackendUser(user, token),
        accessToken: token,
      );
    } catch (_) {
      ssoLauncher.store.remove(SsoSessionKeys.localSession);
      return null;
    }
  }

  Future<AuthSession?> _exchangeForLocalSession(
    SsoAuthLauncher ssoLauncher,
    AuthUser ssoUser,
    String ssoToken,
  ) async {
    try {
      final client = httpClient ?? http.Client();
      final response = await client
          .post(
            Uri.parse('${ApiEndpoints.baseUrl}/auth/local-session'),
            headers: {'Authorization': 'Bearer $ssoToken'},
          )
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final data = decoded['data'] as Map<String, dynamic>?;
      final token = data?['access_token'] as String?;
      final expiresAt = DateTime.tryParse(data?['expires_at'] as String? ?? '');
      if (token == null || expiresAt == null) return null;
      final rawUser = data?['user'] as Map<String, dynamic>? ?? const {};
      final user = AuthUser(
        sub: (rawUser['id'] ?? ssoUser.sub).toString(),
        email: rawUser['email'] as String? ?? ssoUser.email,
        name: (rawUser['full_name'] ?? ssoUser.name) as String?,
        picture: ssoUser.picture,
        role: rawUser['role'] as String? ?? ssoUser.role,
      );
      ssoLauncher.store.write(
        SsoSessionKeys.localSession,
        jsonEncode({
          'access_token': token,
          'expires_at': expiresAt.toUtc().millisecondsSinceEpoch,
          'user': {
            'sub': user.sub,
            'email': user.email,
            'name': user.name,
            'role': user.role,
          },
        }),
      );
      return AuthSession(user: user, accessToken: token);
    } catch (error) {
      developer.log('Could not create a local session: $error', name: 'auth');
      return null;
    }
  }

  /// Reads the effective application role from the backend user record. The
  /// SSO profile identifies the user, while the backend owns JSM permissions.
  Future<AuthUser> _fetchBackendUser(
    AuthUser fallback,
    String accessToken,
  ) async {
    try {
      final client = httpClient ?? http.Client();
      final response = await client
          .get(
            Uri.parse('${ApiEndpoints.users}/me'),
            headers: {'Authorization': 'Bearer $accessToken'},
          )
          .timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) {
        developer.log(
          'Could not load the current JSM user (HTTP ${response.statusCode}); '
          'using the SSO profile role.',
          name: 'auth',
        );
        return fallback;
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final profile = decoded['data'] as Map<String, dynamic>?;
      if (profile == null || profile['role'] is! String) {
        developer.log(
          'The current JSM user response did not include a role; '
          'using the SSO profile role.',
          name: 'auth',
        );
        return fallback;
      }
      return AuthUser(
        sub: (profile['id'] ?? fallback.sub).toString(),
        email: profile['email'] as String? ?? fallback.email,
        name: (profile['full_name'] ?? fallback.name) as String?,
        picture: fallback.picture,
        role: profile['role'] as String,
      );
    } catch (_) {
      // Authentication should still work when the JSM API is temporarily
      // unavailable; use the profile returned by SSO in that case.
      developer.log(
        'Could not load the current JSM user; using the SSO profile role.',
        name: 'auth',
      );
      return fallback;
    }
  }

  @override
  Future<AuthUser> mockLogin({
    required String sub,
    required String email,
    required String name,
    required String role,
  }) async {
    final header = base64Url
        .encode(utf8.encode(jsonEncode({'alg': 'none', 'typ': 'JWT'})))
        .replaceAll('=', '');
    final payload = base64Url
        .encode(
          utf8.encode(
            jsonEncode({
              'sub': sub,
              'email': email,
              'name': name,
              'role': role,
              'roles': [role],
              'type': 'access',
              'exp':
                  (DateTime.now()
                      .add(const Duration(days: 7))
                      .millisecondsSinceEpoch ~/
                  1000),
            }),
          ),
        )
        .replaceAll('=', '');
    final token = '$header.$payload.';

    final user = AuthUser(sub: sub, email: email, name: name, role: role);

    final ssoLauncher = launcher;
    if (ssoLauncher is SsoAuthLauncher) {
      ssoLauncher.store.write(
        SsoSessionKeys.tokens,
        jsonEncode({
          'access_token': token,
          'expires_at': DateTime.now()
              .add(const Duration(days: 7))
              .millisecondsSinceEpoch,
        }),
      );
      ssoLauncher.store.write(
        SsoSessionKeys.user,
        jsonEncode({'sub': sub, 'email': email, 'name': name, 'role': role}),
      );
    }
    return user;
  }
}
