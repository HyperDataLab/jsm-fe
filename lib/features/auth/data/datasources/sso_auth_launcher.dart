import 'dart:convert';

import '../../domain/entities/auth_provider.dart';
import '../../domain/entities/auth_result.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/usecases/auth_launcher.dart';
import 'oidc_auth.dart';
import 'oidc_api_client.dart';
import 'sso_session_store.dart';
import 'sso_session_store_stub.dart' show createSsoSessionStore;
import 'browser_sso_seam.dart';

/// Central SSO (Authorization Code + PKCE S256) implementation of
/// [AuthLauncher]. All browser access goes through browser_sso* and the
/// injected [store], so this class is fully testable with fakes.
class SsoAuthLauncher implements AuthLauncher {
  final OidcAuthUrlBuilder urlBuilder;
  final OidcApiClient apiClient;
  final SsoSessionStore store;

  SsoAuthLauncher({
    OidcAuthUrlBuilder? urlBuilder,
    OidcApiClient? apiClient,
    SsoSessionStore? store,
  }) : urlBuilder = urlBuilder ?? const OidcAuthUrlBuilder(),
       apiClient = apiClient ?? OidcApiClient(),
       store = store ?? createSsoSessionStore();

  @override
  Future<void> start(AuthProvider provider) async {
    final redirectUri = BrowserSso.redirectUri();
    final pending = OidcAuthUrlBuilder.createPendingRequest();
    store.write(
      SsoSessionKeys.pendingRequest,
      jsonEncode({
        'state': pending.state,
        'code_verifier': pending.codeVerifier,
        'redirect_uri': redirectUri,
      }),
    );
    final url = urlBuilder.build(
      provider: provider,
      redirectUri: redirectUri,
      state: pending.state,
      codeChallenge: OidcAuthUrlBuilder.createCodeChallenge(
        pending.codeVerifier,
      ),
    );
    await BrowserSso.navigate(url);
  }

  @override
  Future<AuthResult> completeFromCallback() async {
    final uri = BrowserSso.currentUri();
    if (uri.path != '/auth/callback') {
      throw const AuthLauncherException('No login callback in progress.');
    }
    final String? stored;
    try {
      stored = store.read(SsoSessionKeys.pendingRequest);
    } catch (_) {
      throw const AuthLauncherException('Invalid login session state.');
    }
    String? state;
    String? codeVerifier;
    String? redirectUri;
    if (stored != null) {
      try {
        final decoded = jsonDecode(stored) as Map<String, dynamic>;
        state = decoded['state'] as String?;
        codeVerifier = decoded['code_verifier'] as String?;
        redirectUri = decoded['redirect_uri'] as String?;
      } catch (_) {
        // fall through: missing state fails validation below
      }
    }
    final callback = parseAuthCallback(uri, storedState: state);
    // Consume the pending request immediately so a reload/repeat of the
    // same callback URL cannot be processed twice.
    store.remove(SsoSessionKeys.pendingRequest);

    if (codeVerifier == null || codeVerifier.isEmpty) {
      throw const AuthLauncherException('Missing PKCE verifier.');
    }

    final tokens = await apiClient.exchangeCode(
      code: callback.code,
      redirectUri: redirectUri ?? BrowserSso.redirectUri(),
      codeVerifier: codeVerifier,
    );
    store.write(SsoSessionKeys.tokens, jsonEncode(tokens.toJson()));

    // User profile retrieval:
    // Method 1 (Fastest, per quickstart doc): Decode id_token directly.
    // Method 2: GET /api/v1/oidc/userinfo with Bearer token.
    SsoUserInfo profile;
    final fromIdToken = OidcApiClient.parseIdToken(tokens.idToken);
    if (fromIdToken != null) {
      profile = fromIdToken;
      // Best-effort userinfo call to enrich profile, without failing login if offline/error.
      try {
        final enriched = await apiClient.fetchUserInfo(tokens.accessToken);
        profile = enriched;
      } catch (_) {
        // Keep profile from id_token
      }
    } else {
      profile = await apiClient.fetchUserInfo(tokens.accessToken);
    }
    store.write(SsoSessionKeys.user, jsonEncode(profile.toJson()));

    BrowserSso.cleanHistory();
    return AuthResult(user: _toAuthUser(profile));
  }

  /// Restores a previously stored session (app start on a non-callback URL).
  /// Returns null when nothing valid is stored; clears stale data.
  Future<AuthSessionSnapshot?> restoreStoredSession() async {
    final tokensJson = store.read(SsoSessionKeys.tokens);
    final userJson = store.read(SsoSessionKeys.user);
    if (tokensJson == null || userJson == null) {
      _clear();
      return null;
    }
    try {
      final tokens = SsoTokens.fromJson(
        jsonDecode(tokensJson) as Map<String, dynamic>,
      );
      final profile = SsoUserInfo.fromJson(
        jsonDecode(userJson) as Map<String, dynamic>,
      );
      if (tokens.isExpired) {
        // ponytail: no refresh-token flow yet; add when the SSO server
        // supports refresh_token grant and the app needs longer sessions.
        _clear();
        return null;
      }
      return AuthSessionSnapshot(tokens: tokens, userInfo: profile);
    } catch (_) {
      _clear();
      return null;
    }
  }

  /// Clears all locally stored SSO session data (logout).
  void clearSession() => _clear();

  void _clear() {
    for (final key in [
      SsoSessionKeys.pendingRequest,
      SsoSessionKeys.tokens,
      SsoSessionKeys.user,
    ]) {
      try {
        store.remove(key);
      } catch (_) {
        // A broken store must not crash logout.
      }
    }
  }
}

/// Restored session data held internally by the repository; never crosses
/// into the presentation layer.
class AuthSessionSnapshot {
  final SsoTokens tokens;
  final SsoUserInfo userInfo;

  const AuthSessionSnapshot({required this.tokens, required this.userInfo});
}

AuthUser _toAuthUser(SsoUserInfo info) => AuthUser(
  sub: info.sub,
  email: info.email,
  name: info.name,
  picture: info.picture,
  role: info.role,
  studentId: info.studentId,
  major: info.major,
);
