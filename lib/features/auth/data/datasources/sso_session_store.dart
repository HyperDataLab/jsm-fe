/// Persisted SSO session data. On web this is browser sessionStorage via
/// the conditional-export factory; keys/values are opaque to callers.
abstract class SsoSessionStore {
  String? read(String key);
  void write(String key, String value);
  void remove(String key);
}

/// Keys used by the SSO flow. Kept here so nothing else knows them.
class SsoSessionKeys {
  SsoSessionKeys._();

  /// JSON: {"state": ..., "code_verifier": ...} for the pending request.
  static const pendingRequest = 'sso_pending_request';

  /// JSON: {"access_token": ..., "refresh_token": ..., "id_token": ...,
  /// "expires_at": epoch-ms}.
  static const tokens = 'sso_tokens';

  /// JSON userinfo from /api/v1/oidc/userinfo.
  static const user = 'sso_user';

  /// JSON with the local API token, seven-day expiry, and effective role.
  static const localSession = 'local_session';
}
