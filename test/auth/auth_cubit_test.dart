import 'package:flutter_test/flutter_test.dart';
import 'package:jsm_fe/core/errors/exceptions.dart';
import 'package:jsm_fe/features/auth/domain/entities/auth_provider.dart';
import 'package:jsm_fe/features/auth/domain/entities/auth_result.dart';
import 'package:jsm_fe/features/auth/domain/entities/auth_user.dart';
import 'package:jsm_fe/features/auth/domain/repositories/auth_repository.dart';
import 'package:jsm_fe/features/auth/domain/usecases/login_usecase.dart';
import 'package:jsm_fe/features/auth/domain/usecases/logout_usecase.dart';
import 'package:jsm_fe/features/auth/domain/usecases/restore_session_usecase.dart';
import 'package:jsm_fe/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:jsm_fe/features/auth/presentation/cubit/auth_state.dart';

/// Fake repository standing in for the SSO flow: never makes real OAuth or
/// network requests.
class _FakeAuthRepository implements AuthRepository {
  Object? loginError;
  Object? callbackError;
  AuthResult? callbackResult;
  AuthSession? storedSession;
  bool logoutCalled = false;
  AuthProvider? loginProvider;

  @override
  Future<void> login(AuthProvider provider) async {
    if (loginError != null) throw loginError!;
    loginProvider = provider;
  }

  @override
  Future<AuthResult?> handleCallback() async {
    if (callbackError != null) throw callbackError!;
    return callbackResult;
  }

  @override
  Future<AuthSession?> restoreSession() async => storedSession;

  @override
  Future<void> logout() async {
    logoutCalled = true;
    storedSession = null;
  }

  @override
  Future<String?> currentToken() async => null;

  @override
  Future<AuthUser> mockLogin({
    required String sub,
    required String email,
    required String name,
    required String role,
  }) async {
    return AuthUser(sub: sub, email: email, name: name, role: role);
  }
}

void main() {
  late _FakeAuthRepository repo;
  late AuthCubit cubit;

  AuthCubit makeCubit(AuthRepository r) => AuthCubit(
    loginUseCase: LoginUseCase(r),
    logoutUseCase: LogoutUseCase(r),
    restoreSessionUseCase: RestoreSessionUseCase(r),
    repository: r,
  );

  setUp(() {
    repo = _FakeAuthRepository();
    cubit = makeCubit(repo);
  });

  tearDown(() => cubit.close());

  test('initial state is AuthInitial', () {
    expect(cubit.state, isA<AuthInitial>());
  });

  test('checkSession with no session emits AuthUnauthenticated', () async {
    await cubit.checkSession();
    expect(cubit.state, isA<AuthUnauthenticated>());
  });

  test('checkSession restores stored session -> AuthAuthenticated', () async {
    repo.storedSession = AuthSession(
      user: AuthUser(sub: 's1', email: 'saved@jsm.dev'),
    );
    await cubit.checkSession();
    expect(cubit.state, isA<AuthAuthenticated>());
    expect((cubit.state as AuthAuthenticated).user.email, 'saved@jsm.dev');
  });

  test(
    'checkSession with throwing storage falls back to unauthenticated',
    () async {
      final throwing = _ThrowingRepo();
      final c = makeCubit(throwing);
      await c.checkSession();
      expect(c.state, isA<AuthUnauthenticated>());
      await c.close();
    },
  );

  test(
    'checkSession processes a valid callback -> AuthAuthenticated',
    () async {
      repo.callbackResult = AuthResult(
        user: AuthUser(sub: 's1', email: 'user@example.com'),
      );
      await cubit.checkSession();
      expect(cubit.state, isA<AuthAuthenticated>());
      expect((cubit.state as AuthAuthenticated).user.sub, 's1');
    },
  );

  test(
    'checkSession with invalid state callback -> AuthFailure (no crash)',
    () async {
      repo.callbackError = const ServerException(
        'Login session state mismatch.',
      );
      await cubit.checkSession();
      expect(cubit.state, isA<AuthFailure>());
      expect((cubit.state as AuthFailure).message, contains('state mismatch'));
    },
  );

  test('checkSession with missing code callback -> AuthFailure', () async {
    repo.callbackError = const ServerException(
      'Login callback is missing a code.',
    );
    await cubit.checkSession();
    expect(cubit.state, isA<AuthFailure>());
  });

  test(
    'login reports cancellation when SSO closes without a session',
    () async {
      await cubit.login(AuthProvider.web);
      expect(repo.loginProvider, AuthProvider.web);
      expect(cubit.state, isA<AuthFailure>());
      expect(
        (cubit.state as AuthFailure).message,
        contains('Login was cancelled'),
      );
    },
  );

  test('login failure (no browser / store error) emits AuthFailure', () async {
    repo.loginError = const ServerException(
      'SSO login requires the web build.',
    );
    await cubit.login(AuthProvider.web);
    expect(cubit.state, isA<AuthFailure>());
  });

  test('logout emits AuthLoggedOut and clears session', () async {
    repo.storedSession = AuthSession(
      user: AuthUser(sub: 's1', email: 'a@b.com'),
    );
    final states = <AuthState>[];
    final sub = cubit.stream.listen(states.add);
    await cubit.logout();
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();
    expect(states.map((s) => s.runtimeType), [AuthLoading, AuthLoggedOut]);
    expect(repo.logoutCalled, isTrue);
    expect(repo.storedSession, isNull);
  });

  test('logout emits AuthLoggedOut even if repository throws', () async {
    final c = makeCubit(_ThrowingRepo());
    await c.logout();
    expect(c.state, isA<AuthLoggedOut>());
    await c.close();
  });
}

class _ThrowingRepo implements AuthRepository {
  @override
  Future<void> login(AuthProvider provider) async =>
      throw const ServerException();

  @override
  Future<AuthResult?> handleCallback() async => null; // not a callback page

  @override
  Future<AuthSession?> restoreSession() async => throw CacheException();

  @override
  Future<void> logout() async => throw Exception('boom');

  @override
  Future<String?> currentToken() async => null;

  @override
  Future<AuthUser> mockLogin({
    required String sub,
    required String email,
    required String name,
    required String role,
  }) async {
    return AuthUser(sub: sub, email: email, name: name, role: role);
  }
}
