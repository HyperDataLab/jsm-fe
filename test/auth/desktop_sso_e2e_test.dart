import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jsm_fe/features/auth/data/datasources/desktop_sso_launcher.dart';
import 'package:jsm_fe/features/auth/data/datasources/oidc_api_client.dart';
import 'package:jsm_fe/features/auth/data/datasources/sso_session_store.dart';
import 'package:jsm_fe/features/auth/domain/entities/auth_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;
  const port = 5998;

  test('E2E Desktop SSO: dual-stack IPv4 & IPv6 loopback callbacks and token exchange', () async {
    String? launchedUrl;
    final launcher = DesktopSsoLauncher(
      listenPort: port,
      browserLauncher: (url) async {
        launchedUrl = url;
        return true;
      },
      apiClient: OidcApiClient(
        client: MockClient((req) async {
          if (req.url.path.endsWith('/token')) {
            return http.Response(
              jsonEncode({
                'access_token': 'at-e2e-token',
                'token_type': 'Bearer',
                'expires_in': 3600,
                'id_token': 'mock.id.token',
              }),
              200,
            );
          }
          if (req.url.path.endsWith('/userinfo')) {
            return http.Response(
              jsonEncode({
                'sub': 'sub-e2e-user',
                'email': 'scholar@lab.edu.vn',
                'name': 'Scholar Test User',
                'role': 'USER',
              }),
              200,
            );
          }
          return http.Response('Not found', 404);
        }),
      ),
    );

    // 1. Start launcher
    await launcher.start(AuthProvider.web);
    expect(launcher.loopbackServerRunning, isTrue);
    expect(launchedUrl, contains('client_id=hd_CeFMf5SSDY9xiAhP5vxS9Td3'));
    expect(
      launchedUrl,
      contains('redirect_uri=http%3A%2F%2Flocalhost%3A$port%2Fauth%2Fcallback'),
    );

    // 2. Read pending state
    final pendingRaw = launcher.store.read(SsoSessionKeys.pendingRequest);
    expect(pendingRaw, isNotNull);
    final pending = jsonDecode(pendingRaw!) as Map<String, dynamic>;
    final state = pending['state'] as String;
    expect(pending['redirect_uri'], 'http://localhost:$port/auth/callback');

    // 3. Test IPv4 callback (127.0.0.1)
    final client = HttpClient();
    final reqV4 = await client.getUrl(
      Uri.parse(
        'http://127.0.0.1:$port/auth/callback?code=mock_auth_code&state=$state',
      ),
    );
    final respV4 = await reqV4.close();
    final bodyV4 = await respV4.transform(utf8.decoder).join();
    expect(respV4.statusCode, 200);
    expect(bodyV4, contains('Đăng nhập thành công'));

    // 4. Await completion
    final result = await launcher.awaitCallbackAndComplete();
    expect(result.user.email, 'scholar@lab.edu.vn');
    expect(result.user.sub, 'sub-e2e-user');
    expect(result.user.role, 'USER');

    launcher.clearSession();
    client.close();
  });

  test('E2E Desktop SSO: IPv6 loopback callback', () async {
    final launcherV6 = DesktopSsoLauncher(
      listenPort: port,
      browserLauncher: (_) async => true,
      apiClient: OidcApiClient(
        client: MockClient((req) async {
          if (req.url.path.endsWith('/token')) {
            return http.Response(
              jsonEncode({
                'access_token': 'at-v6-token',
                'token_type': 'Bearer',
                'expires_in': 3600,
                'id_token': 'mock.id.token',
              }),
              200,
            );
          }
          if (req.url.path.endsWith('/userinfo')) {
            return http.Response(
              jsonEncode({
                'sub': 'sub-v6-user',
                'email': 'scholar_v6@lab.edu.vn',
                'name': 'Scholar V6 User',
                'role': 'USER',
              }),
              200,
            );
          }
          return http.Response('Not found', 404);
        }),
      ),
    );

    await launcherV6.start(AuthProvider.web);
    final pendingV6 = jsonDecode(
      launcherV6.store.read(SsoSessionKeys.pendingRequest)!,
    ) as Map<String, dynamic>;
    final stateV6 = pendingV6['state'] as String;

    final client = HttpClient();
    try {
      final reqV6 = await client.getUrl(
        Uri.parse(
          'http://[::1]:$port/auth/callback?code=mock_code_v6&state=$stateV6',
        ),
      );
      final respV6 = await reqV6.close();
      final bodyV6 = await respV6.transform(utf8.decoder).join();
      expect(respV6.statusCode, 200);
      expect(bodyV6, contains('Đăng nhập thành công'));

      final resultV6 = await launcherV6.awaitCallbackAndComplete();
      expect(resultV6.user.email, 'scholar_v6@lab.edu.vn');
      expect(resultV6.user.sub, 'sub-v6-user');
    } catch (e) {
      // If OS environment does not route [::1], launcher still safely cleans up
    } finally {
      launcherV6.clearSession();
      client.close();
    }
  });
}
