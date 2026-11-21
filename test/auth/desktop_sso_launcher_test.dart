import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jsm_fe/core/errors/exceptions.dart';
import 'package:jsm_fe/features/auth/data/datasources/desktop_sso_launcher.dart';
import 'package:jsm_fe/features/auth/data/datasources/oidc_api_client.dart';
import 'package:jsm_fe/features/auth/data/datasources/sso_session_store.dart';
import 'package:jsm_fe/features/auth/domain/entities/auth_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;
  const testPort = 5999;

  test('desktop flow: browser redirect lands on loopback /auth/callback and '
      'completes the token exchange', () async {
    final launcher = DesktopSsoLauncher(
      listenPort: testPort,
      browserLauncher: (_) async => true,
      apiClient: OidcApiClient(
        client: MockClient((request) async {
          if (request.url.path.endsWith('/token')) {
            return http.Response(
              jsonEncode({
                'access_token': 'at',
                'token_type': 'Bearer',
                'expires_in': 3600,
              }),
              200,
            );
          }
          return http.Response(
            jsonEncode({'sub': 'sub-9', 'email': 'd@e.f', 'name': 'D E'}),
            200,
          );
        }),
      ),
    );

    await launcher.start(AuthProvider.web); // opens browser + binds :testPort

    // Extract the dynamically generated state
    final pendingRaw = launcher.store.read(SsoSessionKeys.pendingRequest);
    expect(pendingRaw, isNotNull);
    final pending = jsonDecode(pendingRaw!) as Map<String, dynamic>;
    final state = pending['state'] as String;

    // Simulate the SSO server redirecting the user's browser back.
    final client = HttpClient();
    final request = await client.getUrl(
      Uri.parse(
        'http://localhost:$testPort/auth/callback?code=c1&state=$state',
      ),
    );
    final response = await request.close();
    await response.drain<void>();
    client.close();

    final result = await launcher.awaitCallbackAndComplete();
    expect(result.user.sub, 'sub-9');
    expect(result.user.email, 'd@e.f');

    launcher.clearSession();
  });

  test('desktop flow: wrong-state callback fails safely', () async {
    final launcher = DesktopSsoLauncher(
      listenPort: testPort,
      browserLauncher: (_) async => true,
      apiClient: OidcApiClient(
        client: MockClient(
          (request) async => fail('exchange must not run on bad state'),
        ),
      ),
    );
    await launcher.start(AuthProvider.web);

    final client = HttpClient();
    final request = await client.getUrl(
      Uri.parse('http://localhost:$testPort/auth/callback?code=c1&state=evil'),
    );
    await (await request.close()).drain<void>();
    client.close();

    await expectLater(
      launcher.awaitCallbackAndComplete(),
      throwsA(isA<ServerException>()),
    );
    launcher.clearSession();
  });
}
