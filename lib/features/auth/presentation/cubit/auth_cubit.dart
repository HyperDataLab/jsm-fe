import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/auth_provider.dart';
import '../../domain/entities/auth_result.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/restore_session_usecase.dart';
import 'auth_state.dart';

/// Manages authentication state. All browser/callback/launcher logic
/// lives in the repository layer, never in widgets.
class AuthCubit extends Cubit<AuthState> {
  final LoginUseCase loginUseCase;
  final LogoutUseCase logoutUseCase;
  final RestoreSessionUseCase restoreSessionUseCase;
  final AuthRepository repository;

  AuthCubit({
    required this.loginUseCase,
    required this.logoutUseCase,
    required this.restoreSessionUseCase,
    required this.repository,
  }) : super(AuthInitial());

  /// Called once at app start: processes the SSO callback page load (if
  /// this is one), otherwise restores the persisted session, if any.
  Future<void> checkSession() async {
    try {
      AuthResult? result;
      try {
        result = await repository.handleCallback();
      } catch (e) {
        // Invalid state / missing code / failed exchange: safe failure, no
        // crash, no partial authentication.
        emit(AuthFailure(message: _sanitize(e)));
        return;
      }
      if (result != null) {
        emit(AuthAuthenticated(user: result.user));
        return;
      }
      final session = await restoreSessionUseCase();
      if (session != null) {
        emit(AuthAuthenticated(user: session.user));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (_) {
      // A failed restore (expired/invalid session, storage error) means
      // unauthenticated, not a crash.
      emit(AuthUnauthenticated());
    }
  }

  /// Starts the SSO authorize flow. Web waits for its popup to close and then
  /// restores the session written by the callback page; desktop waits for the
  /// loopback callback. A closed popup without a session is a login failure.
  Future<void> login(AuthProvider provider) async {
    emit(AuthLoading());
    try {
      await loginUseCase(provider);
      // The browser callback or desktop loopback flow should have persisted
      // the session before the launcher returns.
      final session = await restoreSessionUseCase();
      if (session != null) {
        emit(AuthAuthenticated(user: session.user));
      } else {
        // The web popup can close without returning an SSO session. End the
        // loading state and let the login page report the failed attempt.
        emit(
          const AuthFailure(
            message: 'Login was cancelled or could not be completed.',
            showOnLoginPage: true,
          ),
        );
      }
    } catch (e) {
      emit(AuthFailure(message: _sanitize(e), showOnLoginPage: true));
    }
  }

  Future<void> logout() async {
    emit(AuthLoading());
    try {
      await logoutUseCase();
    } catch (_) {
      // Logout must always leave the user signed out locally, even if the
      // session invalidation fails.
    }
    emit(AuthLoggedOut());
  }

  /// Mock authentication for dev/testing: seeds an authenticated session with a specified role.
  Future<void> mockLogin({
    required String sub,
    required String email,
    required String name,
    required String role,
  }) async {
    emit(AuthLoading());
    try {
      final user = await repository.mockLogin(
        sub: sub,
        email: email,
        name: name,
        role: role,
      );
      emit(AuthAuthenticated(user: user));
    } catch (e) {
      emit(AuthFailure(message: _sanitize(e)));
    }
  }

  /// Maps any error to a user-safe message: exception text from the data
  /// layer never contains tokens, but keep this as the single funnel so
  /// raw internals are not surfaced verbatim.
  String _sanitize(Object e) {
    final text = e.toString();
    return text.startsWith('Exception: ') ? text.substring(11) : text;
  }
}
