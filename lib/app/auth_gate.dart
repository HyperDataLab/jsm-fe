import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/widgets/loading_view.dart';
import '../../core/widgets/error_view.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../features/auth/domain/entities/auth_provider.dart';
import '../features/auth/presentation/cubit/auth_cubit.dart';
import '../features/auth/presentation/cubit/auth_state.dart';
import '../features/auth/presentation/pages/login_page.dart';
import 'auth_cubit_scope.dart';

/// Root gate of the app: switches between loading, Login, Home, and
/// recoverable error based on authentication state.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    try {
      context.read<AuthCubit>();
      return const _AuthSwitch();
    } catch (_) {
      return const _AuthSwitchWithScope();
    }
  }
}

class _AuthSwitchWithScope extends StatelessWidget {
  const _AuthSwitchWithScope();

  @override
  Widget build(BuildContext context) {
    return AuthCubitScope(child: const _AuthSwitch());
  }
}

class _AuthSwitch extends StatelessWidget {
  const _AuthSwitch();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          final role = state.user.role?.toUpperCase();
          if (role == 'ADMIN') {
            return const AdminDashboardPage();
          }
          return const HomePage();
        }
        if (state is AuthInitial || state is AuthLoading) {
          // Session check / flow in flight: not a login screen frame.
          return const Scaffold(
            body: LoadingView(message: 'Checking session…'),
          );
        }
        if (state is AuthFailure) {
          if (state.showOnLoginPage) return const LoginPage();
          // Recoverable error: user can retry the login flow.
          return Scaffold(
            body: ErrorView(
              message: state.message,
              onRetry: () => context.read<AuthCubit>().login(AuthProvider.web),
            ),
          );
        }
        // AuthUnauthenticated, AuthLoggedOut: show Login.
        return const LoginPage();
      },
    );
  }
}
