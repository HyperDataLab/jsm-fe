import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jsm_fe/app/auth_gate.dart';
import 'package:jsm_fe/core/widgets/error_view.dart';
import 'package:jsm_fe/core/widgets/loading_view.dart';
import 'package:jsm_fe/features/auth/domain/entities/auth_provider.dart';
import 'package:jsm_fe/features/auth/domain/entities/auth_result.dart';
import 'package:jsm_fe/features/auth/domain/entities/auth_user.dart';
import 'package:jsm_fe/features/auth/domain/repositories/auth_repository.dart';
import 'package:jsm_fe/features/auth/domain/usecases/login_usecase.dart';
import 'package:jsm_fe/features/auth/domain/usecases/logout_usecase.dart';
import 'package:jsm_fe/features/auth/domain/usecases/restore_session_usecase.dart';
import 'package:jsm_fe/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:jsm_fe/features/auth/presentation/pages/login_page.dart';
import 'package:jsm_fe/features/admin/presentation/pages/admin_dashboard_page.dart';

/// Stub repository: never touches a browser or the SSO network.
class _StubRepo implements AuthRepository {
  AuthResult? callbackResult;
  Object? callbackError;
  AuthSession? storedSession;
  bool logoutCalled = false;

  @override
  Future<void> login(AuthProvider provider) async {}

  @override
  Future<AuthResult?> handleCallback() async {
    if (callbackError != null) throw callbackError!;
    return callbackResult;
  }

  @override
  Future<AuthSession?> restoreSession() async => storedSession;

  @override
  @override
  Future<void> logout() async {
    logoutCalled = true;
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

Widget _gate(AuthRepository repo) => RepositoryProvider<AuthRepository>.value(
  value: repo,
  child: BlocProvider<AuthCubit>(
    create: (_) => AuthCubit(
      loginUseCase: LoginUseCase(repo),
      logoutUseCase: LogoutUseCase(repo),
      restoreSessionUseCase: RestoreSessionUseCase(repo),
      repository: repo,
    )..checkSession(),
    child: const MaterialApp(home: AuthGate()),
  ),
);

void main() {
  testWidgets('startup unauthenticated: shows Login, never Home', (
    tester,
  ) async {
    await tester.pumpWidget(_gate(_StubRepo()));
    await tester.pumpAndSettle(); // checkSession -> unauthenticated
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.text('Journal Dashboard'), findsNothing);
  });

  testWidgets('authenticated: shows the app home', (tester) async {
    final repo = _StubRepo()
      ..callbackResult = AuthResult(
        user: AuthUser(sub: 'u1', email: 'user@example.com'),
      );
    await tester.pumpWidget(_gate(repo));
    await tester.pumpAndSettle();
    expect(find.text('Journal Dashboard'), findsOneWidget);
    expect(find.byType(LoginPage), findsNothing);
  });

  testWidgets('sign-out from home returns to login (never stays authed)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repo = _StubRepo()
      ..callbackResult = AuthResult(
        user: AuthUser(sub: 'u1', email: 'user@example.com'),
      );
    await tester.pumpWidget(_gate(repo));
    await tester.pumpAndSettle();
    expect(find.text('Journal Dashboard'), findsOneWidget);

    final profileFinder = find.byKey(const ValueKey('profile_expanded'));
    await tester.ensureVisible(profileFinder);
    await tester.tap(profileFinder);
    await tester.pumpAndSettle();

    final signOutFinder = find.byWidgetPredicate(
      (widget) =>
          widget is Text &&
          (widget.data == 'Sign out' || widget.data == 'Đăng xuất'),
    );
    await tester.tap(signOutFinder);
    await tester.pumpAndSettle();

    expect(repo.logoutCalled, isTrue);
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.text('Journal Dashboard'), findsNothing);
  });

  testWidgets('loading state shows the loading UI, not login or home', (
    tester,
  ) async {
    final repo = _SlowRepo();
    await tester.pumpWidget(_gate(repo));
    await tester.pump();
    await tester.pump();
    expect(find.byType(LoadingView), findsOneWidget);
    expect(find.byType(LoginPage), findsNothing);
    expect(find.text('Journal Dashboard'), findsNothing);
    await tester.pumpAndSettle();
  });

  testWidgets('failure state shows recoverable error UI', (tester) async {
    final repo = _StubRepo()
      ..callbackError = Exception('Login session state mismatch.');
    await tester.pumpWidget(_gate(repo));
    await tester.pumpAndSettle();
    expect(find.byType(ErrorView), findsOneWidget);
    expect(find.byType(LoginPage), findsNothing);
    // Recoverable: a retry button exists.
    expect(find.byType(ElevatedButton), findsOneWidget);
  });

  testWidgets('session restoration: stored session -> authenticated', (
    tester,
  ) async {
    final repo = _StubRepo()
      ..storedSession = AuthSession(
        user: AuthUser(sub: 'u1', email: 'user@example.com'),
      );
    await tester.pumpWidget(_gate(repo));
    await tester.pumpAndSettle();
    expect(find.text('Journal Dashboard'), findsOneWidget);
  });

  testWidgets('admin authenticated: routes directly to AdminDashboardPage', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repo = _StubRepo()
      ..callbackResult = AuthResult(
        user: AuthUser(
          sub: 'admin_1',
          email: 'admin@example.com',
          name: 'Super Admin',
          role: 'ADMIN',
        ),
      );
    await tester.pumpWidget(_gate(repo));
    await tester.pumpAndSettle();
    expect(find.byType(AdminDashboardPage), findsOneWidget);
    expect(find.text('Journal Dashboard'), findsNothing);
  });
}

/// Completes checkSession only after a delay so loading is observable.
class _SlowRepo extends _StubRepo {
  @override
  Future<AuthSession?> restoreSession() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return null;
  }
}

// Ensure the home entity import is used even if HomePage internals change.
