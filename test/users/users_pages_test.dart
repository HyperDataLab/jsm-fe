import 'package:bloc_test/bloc_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jsm_fe/features/auth/domain/entities/auth_user.dart';
import 'package:jsm_fe/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:jsm_fe/features/auth/presentation/cubit/auth_state.dart';
import 'package:jsm_fe/features/users/domain/entities/user_profile.dart';
import 'package:jsm_fe/features/users/domain/repositories/users_repository.dart';
import 'package:jsm_fe/features/users/domain/usecases/create_account_usecase.dart';
import 'package:jsm_fe/features/users/presentation/cubit/create_account_cubit.dart';
import 'package:jsm_fe/features/users/presentation/pages/create_account_page.dart';
import 'package:jsm_fe/features/users/presentation/pages/user_info_page.dart';

class _FakeUsersRepository implements UsersRepository {
  Object? error;
  UserRole? lastRole;
  int calls = 0;

  @override
  Future<UserProfile> createAccount({
    required UserRole role,
    required String email,
    required String fullName,
    required String password,
  }) async {
    calls++;
    lastRole = role;
    if (error != null) throw error!;
    return UserProfile(id: 'u1', email: email, name: fullName);
  }
}

Widget _wrap(Widget child, {UsersRepository? repo}) => MultiRepositoryProvider(
  providers: [
    RepositoryProvider<UsersRepository>.value(
      value: repo ?? _FakeUsersRepository(),
    ),
  ],
  child: MaterialApp(
    home: BlocProvider(
      create: (context) => CreateAccountCubit(
        createAccount: CreateAccountUseCase(context.read<UsersRepository>()),
      ),
      child: child,
    ),
  ),
);

void main() {
  testWidgets('student form: title shown, validation blocks empty submit', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const CreateAccountPage(role: UserRole.student)),
    );

    expect(find.text('Create Student Account'), findsWidgets);

    await tester.tap(find.text('Create account'));
    await tester.pump();
    expect(find.text('Full name is required.'), findsOneWidget);
    expect(find.text('Email is required.'), findsOneWidget);
    expect(find.text('Password is required.'), findsOneWidget);
  });

  testWidgets('lecturer form: invalid email and short password rejected', (
    tester,
  ) async {
    final repo = _FakeUsersRepository();
    await tester.pumpWidget(
      _wrap(const CreateAccountPage(role: UserRole.lecturer), repo: repo),
    );

    await tester.enterText(find.byKey(const Key('field_Full name')), 'G');
    await tester.enterText(
      find.byKey(const Key('field_Email')),
      'not-an-email',
    );
    await tester.enterText(find.byKey(const Key('field_Password')), 'short');
    await tester.tap(find.text('Create account'));
    await tester.pump();

    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(
      find.text('Password must be at least 8 characters.'),
      findsOneWidget,
    );
    expect(find.text('Name is too short.'), findsOneWidget);
    expect(repo.calls, 0);
  });

  testWidgets('valid student submission reaches the repository and shows '
      'success state', (tester) async {
    final repo = _FakeUsersRepository();
    await tester.pumpWidget(
      _wrap(const CreateAccountPage(role: UserRole.student), repo: repo),
    );

    await tester.enterText(
      find.byKey(const Key('field_Full name')),
      'Sinh Vien',
    );
    await tester.enterText(
      find.byKey(const Key('field_Email')),
      's@university.edu',
    );
    await tester.enterText(
      find.byKey(const Key('field_Password')),
      'long-enough-1',
    );
    await tester.tap(find.text('Create account'));
    await tester.pump();
    await tester.pump();

    expect(repo.lastRole, UserRole.student);
    expect(find.text('Account created'), findsOneWidget);
    expect(find.text('Create another account'), findsOneWidget);
  });

  testWidgets('backend failure shows a recoverable error, not a crash', (
    tester,
  ) async {
    final repo = _FakeUsersRepository()
      ..error = Exception('Email already used.');
    await tester.pumpWidget(
      _wrap(const CreateAccountPage(role: UserRole.lecturer), repo: repo),
    );

    await tester.enterText(
      find.byKey(const Key('field_Full name')),
      'Giang Vien',
    );
    await tester.enterText(
      find.byKey(const Key('field_Email')),
      'dup@university.edu',
    );
    await tester.enterText(
      find.byKey(const Key('field_Password')),
      'long-enough-1',
    );
    await tester.tap(find.text('Create account'));
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('Email already used.'), findsOneWidget);
    expect(find.byType(CreateAccountPage), findsOneWidget);
  });

  testWidgets('user info page shows the SSO profile fields', (tester) async {
    final cubit = _MockAuthCubit();
    whenListen(
      cubit,
      Stream<AuthState>.empty(),
      initialState: const AuthAuthenticated(
        user: AuthUser(sub: 'sub-1', email: 'a@b.co', name: 'A B'),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<AuthCubit>.value(
          value: cubit,
          child: const UserInfoPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Account Profile'), findsOneWidget);
    expect(find.text('sub-1'), findsOneWidget);
    expect(find.text('a@b.co'), findsWidgets);
    expect(find.text('A B'), findsWidgets);
  });
}

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}
