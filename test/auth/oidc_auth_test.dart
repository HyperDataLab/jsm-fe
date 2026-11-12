import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jsm_fe/core/errors/exceptions.dart';
import 'package:jsm_fe/features/auth/data/datasources/oidc_auth.dart';
import 'package:jsm_fe/features/auth/domain/entities/auth_provider.dart';

void main() {
  setUp(() {
    dotenv.loadFromString(
      envString:
          'SSO_ISSUER_URL=http://localhost:3001\n'
          'SSO_CLIENT_ID=researchpulse-ecosystem\n'
          'SSO_REDIRECT_URI=http://localhost:5173/auth/callback',
    );
  });

  group('PKCE / state generation', () {
    test('code verifier: 64 URL-safe chars, differs per call', () {
      final a = OidcAuthUrlBuilder.createCodeVerifier();
      final b = OidcAuthUrlBuilder.createCodeVerifier();
      expect(a.length, 64);
      expect(b.length, 64);
      expect(a, isNot(equals(b)));
      expect(RegExp(r'^[A-Za-z0-9\-._~]+$').hasMatch(a), isTrue);
    });

    test('state: 32 URL-safe chars, differs per call, never fixed', () {
      final a = OidcAuthUrlBuilder.createState();
      final b = OidcAuthUrlBuilder.createState();
      expect(a.length, 32);
      expect(a, isNot(equals('xyz')));
      expect(a, isNot(equals(b)));
    });

    test('code challenge is BASE64URL(SHA256(verifier)) without padding', () {
      // RFC 7636 appendix B test vector.
      final challenge = OidcAuthUrlBuilder.createCodeChallenge(
        'dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk',
      );
      expect(challenge, 'E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM');
      expect(challenge.contains('='), isFalse);
    });

    test('pending request pairs state with verifier', () {
      final p = OidcAuthUrlBuilder.createPendingRequest();
      expect(p.state.length, 32);
      expect(p.codeVerifier.length, 64);
      expect(p.state, isNot(equals(p.codeVerifier)));
    });
  });

  group('authorize URL', () {
    const builder = OidcAuthUrlBuilder();
    const state = 'st-st-st-st-st-st-st-st-st-st-st-st-st-st-st';
    const challenge = 'E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM';

    test('contains all required OIDC + PKCE parameters', () {
      final url = builder.build(
        provider: AuthProvider.web,
        redirectUri: 'http://localhost:3003/auth/callback',
        state: state,
        codeChallenge: challenge,
      );
      final uri = Uri.parse(url);
      expect(uri.scheme, 'http');
      expect(uri.host, 'localhost');
      expect(uri.port, 3001);
      expect(uri.path, '/api/v1/oidc/authorize');
      final q = uri.queryParameters;
      expect(q['client_id'], 'researchpulse-ecosystem');
      expect(q['redirect_uri'], 'http://localhost:3003/auth/callback');
      expect(q['response_type'], 'code');
      expect(q['scope'], 'openid profile email');
      expect(q['state'], state);
      expect(q['code_challenge'], challenge);
      expect(q['code_challenge_method'], 'S256');
    });

    test('state is URL-encoded safely', () {
      final url = builder.build(
        provider: AuthProvider.web,
        redirectUri: 'http://localhost:3003/auth/callback',
        state: 'a+b/c',
        codeChallenge: 'x',
      );
      expect(Uri.parse(url).queryParameters['state'], 'a+b/c');
    });
  });

  group('parseAuthCallback', () {
    const storedState = 'stored-state-123';
    Uri cbUri([Map<String, String>? extra]) => Uri(
      scheme: 'http',
      host: 'localhost',
      port: 3003,
      path: '/auth/callback',
      queryParameters: {'code': 'auth-code-1', ...?extra},
    );

    test('valid code and state parse', () {
      final cb = parseAuthCallback(
        cbUri({'state': storedState}),
        storedState: storedState,
      );
      expect(cb.code, 'auth-code-1');
      expect(cb.state, storedState);
    });

    test('invalid state (mismatch) is rejected', () {
      expect(
        () => parseAuthCallback(
          cbUri({'state': 'attacker'}),
          storedState: storedState,
        ),
        throwsA(isA<ServerException>()),
      );
    });

    test('missing state param is rejected', () {
      expect(
        () => parseAuthCallback(cbUri(), storedState: storedState),
        throwsA(isA<ServerException>()),
      );
    });

    test('no stored state (fresh session / consumed) is rejected', () {
      expect(
        () =>
            parseAuthCallback(cbUri({'state': storedState}), storedState: null),
        throwsA(isA<ServerException>()),
      );
      expect(
        () => parseAuthCallback(cbUri({'state': storedState}), storedState: ''),
        throwsA(isA<ServerException>()),
      );
    });

    test('missing code is rejected', () {
      expect(
        () => parseAuthCallback(
          Uri.parse('http://localhost:3003/auth/callback?state=$storedState'),
          storedState: storedState,
        ),
        throwsA(isA<ServerException>()),
      );
    });

    test('SSO error param (e.g. access_denied) is rejected', () {
      expect(
        () => parseAuthCallback(
          Uri.parse('http://localhost:3003/auth/callback?error=access_denied'),
          storedState: storedState,
        ),
        throwsA(isA<ServerException>()),
      );
    });
  });
}
