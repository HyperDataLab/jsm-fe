import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/domain/usecases/login_usecase.dart';
import '../features/auth/domain/usecases/logout_usecase.dart';
import '../features/auth/domain/usecases/restore_session_usecase.dart';
import '../features/auth/presentation/cubit/auth_cubit.dart';

/// Creates the app-level AuthCubit and checks the persisted session on
/// start: processes the SSO /auth/callback page load if this is one,
/// otherwise restores the stored session (see AuthRepositoryImpl).
class AuthCubitScope extends StatelessWidget {
  final Widget child;

  const AuthCubitScope({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<AuthRepository>(
      create: (context) =>
          context.read<AuthRepository?>() ?? AuthRepositoryImpl(),
      child: BlocProvider(
        create: (context) {
          final repo = context.read<AuthRepository>();
          return AuthCubit(
            loginUseCase: LoginUseCase(repo),
            logoutUseCase: LogoutUseCase(repo),
            restoreSessionUseCase: RestoreSessionUseCase(repo),
            repository: repo,
          )..checkSession();
        },
        child: child,
      ),
    );
  }
}
