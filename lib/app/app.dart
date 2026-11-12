import 'package:material_ui/material_ui.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_localizations/flutter_localizations.dart'
    hide GlobalCupertinoLocalizations, GlobalMaterialLocalizations;

import 'theme/app_theme.dart';
import 'auth_gate.dart';
import 'auth_cubit_scope.dart';
import '../core/localization/app_localizations.dart';
import '../core/localization/locale_cubit.dart';

import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../features/home/presentation/cubit/home_cubit.dart';
import '../features/home/domain/usecases/get_featured_journals_usecase.dart';
import '../features/home/data/repositories/home_repository_impl.dart';
import '../features/users/data/repositories/users_repository_impl.dart';
import '../features/users/domain/usecases/create_account_usecase.dart';
import '../features/users/presentation/pages/user_info_page.dart';
import '../features/student_manuscript_checker/presentation/pages/student_manuscript_checker_page.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthCubitScope(
      child: MultiRepositoryProvider(
        providers: [
          RepositoryProvider<HomeRepositoryImpl>(
            create: (_) => HomeRepositoryImpl(),
          ),
          RepositoryProvider<CreateAccountUseCase>(
            create: (context) {
              final authRepo = context.read<AuthRepository>();
              return CreateAccountUseCase(
                UsersRepositoryImpl(authRepository: authRepo),
              );
            },
          ),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider<LocaleCubit>(create: (_) => LocaleCubit()),
            BlocProvider<HomeCubit>(
              create: (context) => HomeCubit(
                getFeaturedJournalsUseCase: GetFeaturedJournalsUseCase(
                  context.read<HomeRepositoryImpl>(),
                ),
              ),
            ),
          ],
          child: BlocBuilder<LocaleCubit, Locale>(
            builder: (context, locale) {
              return MaterialApp(
                title: 'journal system miner - HyperDataLab',
                theme: AppTheme.lightTheme,
                locale: locale,
                supportedLocales: const [Locale('en'), Locale('vi')],
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],

                // Authentication is now the entry point of the application.
                home: const AuthGate(),

                routes: {
                  '/home': (context) => const HomePage(),
                  '/admin': (context) => const AdminDashboardPage(),
                  '/user-info': (context) => const UserInfoPage(),
                  '/student-checker': (context) =>
                      const StudentManuscriptCheckerPage(),
                },

                debugShowCheckedModeBanner: false,
              );
            },
          ),
        ),
      ),
    );
  }
}
