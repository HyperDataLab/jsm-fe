import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jsm_fe/core/errors/exceptions.dart';
import 'package:jsm_fe/features/auth/data/datasources/browser_sso_seam.dart';
import 'package:jsm_fe/features/auth/data/datasources/oidc_auth.dart';
import 'package:jsm_fe/features/auth/data/datasources/oidc_api_client.dart';
import 'package:jsm_fe/features/auth/data/datasources/sso_auth_launcher.dart';
import 'package:jsm_fe/features/auth/data/datasources/sso_session_store.dart';
import 'package:jsm_fe/features/auth/domain/entities/auth_provider.dart';

class _MemoryStore implements SsoSessionStore {
  final map = <String, String>{};

  @override
  String? read(String key) => map[key];

  @override
  void write(String key, String value) => map[key] = value;

  @override
  void remove(String key) => map.remove(key);
}

void main() {
  late _MemoryStore store;
  late Uri pageUri;
  String? navigatedTo;
  bool historyCleaned = false;

  setUp(() {
    store = _MemoryStore();
    pageUri = Uri.parse('http://localhost:3003/');
    navigatedTo = null;
    historyCleaned = false;
    BrowserSso.redirectUri = () => 'http://localhost:3003/auth/callback';
    BrowserSso.currentUri = () => pageUri;
    BrowserSso.navigate = (url) async {
      navigatedTo = url;
    };
    BrowserSso.cleanHistory = () => historyCleaned = true;
  });

  tearDown(() {
    // Reset the seam to inert no-ops; every test re-binds what it needs in
    // setUp, so nothing leaks between tests in this file.
    BrowserSso.redirectUri = () => '';
    BrowserSso.currentUri = () => Uri.parse('about:blank');
    BrowserSso.cleanHistory = () {};
    BrowserSso.navigate = (url) async {};
  });

  SsoAuthLauncher launcherWith(http.Client client) => SsoAuthLauncher(
    store: store,
    apiClient: OidcApiClient(client: client),
  );

  group('start (login redirect)', () {
    test('generates PKCE + state, stores them, redirects to authorize URL', () {
      final launcher = launcherWith(_neverCalledClient());
      launcher.start(AuthProvider.web);

      // Redirect issued with the required parameters.
      expect(navigatedTo, isNotNull);
      final uri = Uri.parse(navigatedTo!);
      expect(uri.path, '/api/v1/oidc/authorize');
      final q = uri.queryParameters;
      expect(q['client_id'], 'researchpulse-ecosystem');
      expect(q['redirect_uri'], 'http://localhost:3003/auth/callback');
      expect(q['response_type'], 'code');
      expect(q['scope'], 'openid profile email');
      expect(q['code_challenge_method'], 'S256');
      expect(q['state'], isNotEmpty);
      expect(q['state'], isNot(equals('xyz')));

      // Stored pending request matches the URL.
      final pending = jsonDecode(
        store.read(SsoSessionKeys.pendingRequest)!,
      ) as Map<String, dynamic>;
      expect(pending['state'], q['state']);
      expect(pending['redirect_uri'], q['redirect_uri']);
      final verifier = pending['code_verifier'] as String;
      expect(verifier.length, 64);
      // challenge must equal BASE64URL(SHA256(verifier)).
      expect(
        q['code_challenge'],
        OidcAuthUrlBuilder.createCodeChallenge(verifier),
      );
    });

    test('state and verifier are fresh per call', () {
      final launcher = launcherWith(_neverCalledClient());
      launcher.start(AuthProvider.web);
      final first = store.read(SsoSessionKeys.pendingRequest);
      launcher.start(AuthProvider.web);
      expect(store.read(SsoSessionKeys.pendingRequest), isNot(equals(first)));
    });
  });

  group('completeFromCallback', () {
    http.Client okClient({String userSub = 'u1'}) => MockClient((req) async {
      if (req.url.path.endsWith('/oidc/token')) {
        return http.Response(
          jsonEncode({
            'access_token': 'at-1',
            'token_type': 'Bearer',
            'expires_in': 3600,
            'refresh_token': 'rt-1',
            'id_token': 'it-1',
          }),
          200,
        );
      }
      if (req.url.path.endsWith('/oidc/userinfo')) {
        expect(req.headers['Authorization'], 'Bearer at-1');
        return http.Response(
          jsonEncode({
            'sub': userSub,
            'email': 'user@example.com',
            'name': 'Example User',
            'picture': 'https://cdn.example.com/a.png',
          }),
          200,
        );
      }
      fail('unexpected request to ${req.url}');
    });

    Future<void> seedPending(SsoAuthLauncher launcher) async {
      await launcher.start(AuthProvider.web);
      final pending = jsonDecode(
        store.read(SsoSessionKeys.pendingRequest)!,
      ) as Map<String, dynamic>;
      pageUri = Uri.parse(
        'http://localhost:3003/auth/callback?code=code-1&state=${pending['state']}',
      );
    }

    test(
      'valid code + state: exchanges, fetches userinfo, cleans history',
      () async {
        final launcher = launcherWith(okClient());
        await seedPending(launcher);

        final result = await launcher.completeFromCallback();

        expect(result.user.sub, 'u1');
        expect(result.user.email, 'user@example.com');
        expect(result.user.name, 'Example User');
        expect(result.user.picture, 'https://cdn.example.com/a.png');
        // Tokens persisted in the store (not in the UI result object).
        final tokens = jsonDecode(
          store.read(SsoSessionKeys.tokens)!,
        ) as Map<String, dynamic>;
        expect(tokens['access_token'], 'at-1');
        // Pending request consumed + history cleaned (no re-processing).
        expect(store.read(SsoSessionKeys.pendingRequest), isNull);
        expect(historyCleaned, isTrue);
      },
    );

    test('callback cannot be processed twice', () async {
      final launcher = launcherWith(okClient());
      await seedPending(launcher);
      await launcher.completeFromCallback();
      // Second processing of the same URL: no stored state left.
      await expectLater(
        launcher.completeFromCallback(),
        throwsA(isA<ServerException>()),
      );
    });

    test('invalid state: safe failure, no token request', () async {
      var tokenCalled = false;
      final client = MockClient((req) async {
        tokenCalled = true;
        throw StateError('must not be reached');
      });
      final launcher = launcherWith(client);
      await launcher.start(AuthProvider.web);
      pageUri = Uri.parse(
        'http://localhost:3003/auth/callback?code=code-1&state=tampered',
      );

      await expectLater(
        launcher.completeFromCallback(),
        throwsA(isA<ServerException>()),
      );
      expect(tokenCalled, isFalse);
    });

    test('missing code: safe failure', () async {
      final launcher = launcherWith(_neverCalledClient());
      await launcher.start(AuthProvider.web);
      final pending = jsonDecode(
        store.read(SsoSessionKeys.pendingRequest)!,
      ) as Map<String, dynamic>;
      pageUri = Uri.parse(
        'http://localhost:3003/auth/callback?state=${pending['state']}',
      );

      await expectLater(
        launcher.completeFromCallback(),
        throwsA(isA<ServerException>()),
      );
    });

    test('no stored pending request at all: safe failure', () async {
      final launcher = launcherWith(_neverCalledClient());
      pageUri = Uri.parse('http://localhost:3003/auth/callback?code=c&state=s');
      await expectLater(
        launcher.completeFromCallback(),
        throwsA(isA<ServerException>()),
      );
    });

    test(
      'token exchange failure (non-200): safe failure, nothing stored',
      () async {
        final client = MockClient(
          (req) async =>
              http.Response(jsonEncode({'error': 'invalid_grant'}), 400),
        );
        final launcher = launcherWith(client);
        await seedPending(launcher);

        await expectLater(
          launcher.completeFromCallback(),
          throwsA(isA<ServerException>()),
        );
        expect(store.read(SsoSessionKeys.tokens), isNull);
      },
    );

    test('userinfo failure (non-200): safe failure', () async {
      final client = MockClient((req) async {
        if (req.url.path.endsWith('/oidc/token')) {
          return http.Response(
            jsonEncode({
              'access_token': 'at-1',
              'token_type': 'Bearer',
              'expires_in': 3600,
            }),
            200,
          );
        }
        return http.Response('{}', 401);
      });
      final launcher = launcherWith(client);
      await seedPending(launcher);

      await expectLater(
        launcher.completeFromCallback(),
        throwsA(isA<ServerException>()),
      );
    });

    test(
      'Method 1: decodes profile from id_token directly when userinfo fails',
      () async {
        final payload = base64Url
            .encode(
              utf8.encode(
                jsonEncode({
                  'sub': 'fast-user',
                  'email': 'fast@example.com',
                  'name': 'Fast User',
                }),
              ),
            )
            .replaceAll('=', '');
        final jwt = 'h.$payload.s';

        final client = MockClient((req) async {
          if (req.url.path.endsWith('/oidc/token')) {
            return http.Response(
              jsonEncode({
                'access_token': 'at-fast',
                'token_type': 'Bearer',
                'expires_in': 3600,
                'id_token': jwt,
              }),
              200,
            );
          }
          if (req.url.path.endsWith('/oidc/userinfo')) {
            return http.Response('server error', 500);
          }
          fail('unexpected request');
        });

        final launcher = launcherWith(client);
        await seedPending(launcher);
        final result = await launcher.completeFromCallback();

        expect(result.user.sub, 'fast-user');
        expect(result.user.email, 'fast@example.com');
        expect(result.user.name, 'Fast User');
      },
    );

    test('non-callback page: throws (nothing to complete)', () async {
      final launcher = launcherWith(_neverCalledClient());
      pageUri = Uri.parse('http://localhost:3003/');
      await expectLater(
        launcher.completeFromCallback(),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('restoreStoredSession', () {
    test('returns null with empty store', () async {
      final launcher = launcherWith(_neverCalledClient());
      expect(await launcher.restoreStoredSession(), isNull);
    });
  });

  test('clearSession removes everything', () async {
    final launcher = launcherWith(_neverCalledClient());
    store.write(SsoSessionKeys.pendingRequest, '{}');
    store.write(SsoSessionKeys.tokens, '{"access_token":"at"}');
    store.write(SsoSessionKeys.user, '{"sub":"u1"}');
    launcher.clearSession();
    expect(store.map, isEmpty);
  });
}

http.Client _neverCalledClient() =>
    MockClient((req) async => fail('network must not be called in this test'));
