import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jsm_fe/core/errors/exceptions.dart';
import 'package:jsm_fe/features/auth/data/datasources/browser_sso_seam.dart';
import 'package:jsm_fe/features/auth/data/datasources/oidc_api_client.dart';
import 'package:jsm_fe/features/auth/data/datasources/sso_auth_launcher.dart';
import 'package:jsm_fe/features/auth/data/datasources/sso_session_store.dart';
import 'package:jsm_fe/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:jsm_fe/features/auth/domain/entities/auth_provider.dart';
import 'package:jsm_fe/features/auth/domain/entities/auth_result.dart';
import 'package:jsm_fe/features/auth/domain/entities/auth_user.dart';
import 'package:jsm_fe/features/auth/domain/usecases/auth_launcher.dart';

/// In-memory store: stands in for web sessionStorage.
class _MemoryStore implements SsoSessionStore {
  final map = <String, String>{};
  final removedKeys = <String>[];

  @override
  String? read(String key) => map[key];

  @override
  void write(String key, String value) => map[key] = value;

  @override
  void remove(String key) {
    map.remove(key);
    removedKeys.add(key);
  }
}

/// Fake launcher: records calls, returns canned results; never touches a
/// browser or network.
class _FakeLauncher implements AuthLauncher {
  Object? startError;
  Object? callbackError;
  AuthResult? callbackResult = AuthResult(
    user: AuthUser(sub: 'u1', email: 'user@example.com'),
  );
  AuthProvider? startedProvider;
  bool completeCalled = false;

  @override
  Future<void> start(AuthProvider provider) async {
    startedProvider = provider;
    if (startError != null) throw startError!;
  }

  @override
  Future<AuthResult> completeFromCallback() async {
    completeCalled = true;
    if (callbackError != null) throw callbackError!;
    return callbackResult!;
  }
}

void main() {
  setUp(() {
    // Simulate a /auth/callback page load (tests never touch a browser).
    BrowserSso.currentUri = () =>
        Uri.parse('http://localhost:3003/auth/callback?code=c&state=s');
  });

  test('login delegates to the launcher (redirect issued)', () async {
    final launcher = _FakeLauncher();
    final repo = AuthRepositoryImpl(launcher: launcher);
    await repo.login(AuthProvider.web);
    expect(launcher.startedProvider, AuthProvider.web);
  });

  test('login launcher failure propagates (no fake success)', () async {
    final launcher = _FakeLauncher()
      ..startError = const ServerException('no browser', 500);
    final repo = AuthRepositoryImpl(launcher: launcher);
    await expectLater(
      repo.login(AuthProvider.web),
      throwsA(isA<ServerException>()),
    );
  });

  test('handleCallback delegates to the launcher', () async {
    final launcher = _FakeLauncher();
    final repo = AuthRepositoryImpl(launcher: launcher);
    final result = await repo.handleCallback();
    expect(launcher.completeCalled, isTrue);
    expect(result?.user.sub, 'u1');
  });

  test(
    'handleCallback returns null when missing callback code or error param',
    () async {
      BrowserSso.currentUri = () =>
          Uri.parse('http://localhost:3003/auth/callback');
      final launcher = _FakeLauncher();
      final repo = AuthRepositoryImpl(launcher: launcher);
      final result = await repo.handleCallback();
      expect(result, isNull);
      expect(launcher.completeCalled, isFalse);
    },
  );

  test('restoreSession returns null when nothing stored', () async {
    final repo = AuthRepositoryImpl(launcher: _FakeLauncher());
    expect(await repo.restoreSession(), isNull);
  });

  test(
    'restoreSession uses the backend user profile for the stored SSO session',
    () async {
      final store = _MemoryStore();
      final repo = AuthRepositoryImpl(
        launcher: SsoAuthLauncher(
          store: store,
          apiClient: OidcApiClient(client: _neverCalledClient()),
        ),
        httpClient: _backendUserClient('USER'),
      );
      store.write(
        SsoSessionKeys.tokens,
        jsonEncode(SsoTokens(accessToken: 'at').toJson()),
      );
      store.write(
        SsoSessionKeys.user,
        jsonEncode(
          const SsoUserInfo(
            sub: 'u1',
            email: 'user@example.com',
            name: 'Example User',
          ).toJson(),
        ),
      );

      final session = await repo.restoreSession();
      expect(session, isNotNull);
      expect(session!.user.sub, 'postgres-user-id');
      expect(session.user.email, 'admin@example.com');
      expect(session.user.name, 'Admin User');
      expect(session.user.role, 'USER');
      expect(session.accessToken, 'at');
    },
  );

  test('restoreSession uses the role returned by the JSM backend', () async {
    final store = _MemoryStore();
    final repo = AuthRepositoryImpl(
      launcher: SsoAuthLauncher(
        store: store,
        apiClient: OidcApiClient(client: _neverCalledClient()),
      ),
      httpClient: _backendUserClient('ADMIN'),
    );
    store.write(
      SsoSessionKeys.tokens,
      jsonEncode(SsoTokens(accessToken: 'at').toJson()),
    );
    store.write(
      SsoSessionKeys.user,
      jsonEncode(
        const SsoUserInfo(
          sub: 'sso-sub',
          email: 'admin@example.com',
          role: 'USER',
        ).toJson(),
      ),
    );

    final session = await repo.restoreSession();
    expect(session?.user.role, 'ADMIN');
    expect(session?.user.sub, 'postgres-user-id');
  });

  test('restoreSession ignores expired tokens', () async {
    final store = _MemoryStore();
    final repo = AuthRepositoryImpl(
      launcher: SsoAuthLauncher(
        store: store,
        apiClient: OidcApiClient(client: _neverCalledClient()),
      ),
    );
    store.write(
      SsoSessionKeys.tokens,
      jsonEncode(
        SsoTokens(
          accessToken: 'at',
          expiresAtMs: DateTime.now()
              .subtract(const Duration(hours: 1))
              .millisecondsSinceEpoch,
        ).toJson(),
      ),
    );
    store.write(
      SsoSessionKeys.user,
      jsonEncode(const SsoUserInfo(sub: 'u1').toJson()),
    );

    expect(await repo.restoreSession(), isNull);
    // Expired data must be cleared, not kept for the next restore.
    expect(store.map, isEmpty);
  });

  test('logout clears all stored session state', () async {
    final store = _MemoryStore();
    final repo = AuthRepositoryImpl(
      launcher: SsoAuthLauncher(store: store),
      httpClient: MockClient(
        (req) async => http.Response('{"message":"ok"}', 200),
      ),
    );
    store.write(SsoSessionKeys.pendingRequest, '{}');
    store.write(SsoSessionKeys.tokens, '{"access_token":"at"}');
    store.write(SsoSessionKeys.user, '{"sub":"u1"}');

    await repo.logout();
    expect(store.map, isEmpty);
  });

  test('logout never throws even if the store is broken', () async {
    final store = _BrokenStore();
    final repo = AuthRepositoryImpl(
      launcher: SsoAuthLauncher(store: store),
      httpClient: MockClient(
        (req) async => http.Response('{"message":"ok"}', 200),
      ),
    );
    await repo.logout(); // must not throw
  });
}

http.Client _neverCalledClient() =>
    MockClient((req) async => fail('network must not be called in this test'));

http.Client _backendUserClient(String role) => MockClient((request) async {
  expect(request.url.path, '/api/v1/users/me');
  expect(request.headers['Authorization'], 'Bearer at');
  return http.Response(
    jsonEncode({
      'data': {
        'id': 'postgres-user-id',
        'email': 'admin@example.com',
        'full_name': 'Admin User',
        'role': role,
      },
    }),
    200,
  );
});

class _BrokenStore implements SsoSessionStore {
  @override
  String? read(String key) => throw Exception('store unavailable');

  @override
  void write(String key, String value) => throw Exception('store unavailable');

  @override
  void remove(String key) => throw Exception('store unavailable');
}
