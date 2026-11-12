import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jsm_fe/core/widgets/app_notification.dart';
import 'package:jsm_fe/features/auth/domain/entities/auth_provider.dart';
import 'package:jsm_fe/features/auth/domain/entities/auth_result.dart';
import 'package:jsm_fe/features/auth/domain/entities/auth_user.dart';
import 'package:jsm_fe/features/auth/domain/repositories/auth_repository.dart';
import 'package:jsm_fe/features/auth/domain/usecases/login_usecase.dart';
import 'package:jsm_fe/features/auth/domain/usecases/logout_usecase.dart';
import 'package:jsm_fe/features/auth/domain/usecases/restore_session_usecase.dart';
import 'package:jsm_fe/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:jsm_fe/features/auth/presentation/cubit/auth_state.dart';
import 'package:jsm_fe/features/auth/presentation/pages/login_page.dart';

/// Stub repository standing in for the SSO redirect flow: never launches a
/// browser or makes real OAuth requests.
class _StubRepo implements AuthRepository {
  Object? loginError;
  AuthProvider? startedProvider;

  @override
  Future<void> login(AuthProvider provider) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (loginError != null) throw loginError!;
    startedProvider = provider;
  }

  @override
  Future<AuthResult?> handleCallback() async => null;

  @override
  Future<AuthSession?> restoreSession() async => null;

  @override
  Future<void> logout() async {}

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

Widget _wrap(AuthRepository repo) => BlocProvider(
  create: (_) => AuthCubit(
    loginUseCase: LoginUseCase(repo),
    logoutUseCase: LogoutUseCase(repo),
    restoreSessionUseCase: RestoreSessionUseCase(repo),
    repository: repo,
  )..checkSession(),
  child: const MaterialApp(home: LoginPage()),
);

void main() {
  tearDown(AppNotification.clear);

  testWidgets(
    'unauthenticated start renders Sign in button without Google button',
    (tester) async {
      final repo = _StubRepo();
      await tester.pumpWidget(_wrap(repo));
      await tester.pumpAndSettle(); // checkSession -> unauthenticated
      expect(find.text('Sign in'), findsWidgets);
      expect(find.text('Continue with Google'), findsNothing);
      // No local credential form: the SSO page handles credentials.
      expect(find.byType(TextFormField), findsNothing);
    },
  );

  testWidgets('tapping Sign in reports an incomplete SSO flow', (tester) async {
    final repo = _StubRepo();
    await tester.pumpWidget(_wrap(repo));
    await tester.pumpAndSettle(); // checkSession -> unauthenticated
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump(); // begin loading
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    // The stub completes after 50ms of real async; pump bounded time
    // (pumpAndSettle would never settle: the spinner animates forever).
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    // The web flow completed without a persisted session, so the user can
    // retry instead of the page remaining in a permanent loading state.
    expect(repo.startedProvider, AuthProvider.web);
    final ctx = tester.element(find.byType(LoginView));
    expect(ctx.read<AuthCubit>().state, isA<AuthFailure>());
    expect(find.textContaining('cancelled'), findsOneWidget);
  });

  testWidgets('auth failure surfaces an error notification, stays on login', (
    tester,
  ) async {
    final repo = _StubRepo()..loginError = Exception('access_denied');
    await tester.pumpWidget(_wrap(repo));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    expect(find.textContaining('access_denied'), findsOneWidget);
    final ctx = tester.element(find.byType(LoginView));
    expect(ctx.read<AuthCubit>().state, isA<AuthFailure>());
  });
}
