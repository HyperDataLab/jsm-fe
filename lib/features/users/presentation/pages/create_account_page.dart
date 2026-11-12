import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/error_view.dart';
import '../../domain/entities/user_profile.dart';
import '../cubit/create_account_cubit.dart';
import '../widgets/account_form_field.dart';

/// Form page for an admin creating a student or lecturer account.
/// Requires a [CreateAccountCubit] above it.
class CreateAccountPage extends StatelessWidget {
  final UserRole role;

  const CreateAccountPage({super.key, required this.role});

  String get _title => role == UserRole.student
      ? 'Create Student Account'
      : 'Create Lecturer Account';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: BlocBuilder<CreateAccountCubit, CreateAccountState>(
              builder: (context, state) {
                if (state is CreateAccountSuccess) {
                  return _SuccessView(
                    user: state.user,
                    onBack: () => Navigator.of(context).pop(),
                    onCreateAnother: () =>
                        context.read<CreateAccountCubit>().reset(),
                  );
                }
                return _AccountForm(role: role, title: _title);
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountForm extends StatefulWidget {
  final UserRole role;
  final String title;

  const _AccountForm({required this.role, required this.title});

  @override
  State<_AccountForm> createState() => _AccountFormState();
}

class _AccountFormState extends State<_AccountForm> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _fullName = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _fullName.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<CreateAccountCubit>().submit(
        role: widget.role,
        email: _email.text,
        fullName: _fullName.text,
        password: _password.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CreateAccountCubit, CreateAccountState>(
      builder: (context, state) {
        final submitting = state is CreateAccountSubmitting;
        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 24),
              if (state is CreateAccountFailure) ...[
                ErrorView(message: state.message),
                const SizedBox(height: 16),
              ],
              AccountFormField(
                label: 'Full name',
                controller: _fullName,
                validator: AccountValidators.fullName,
              ),
              const SizedBox(height: 16),
              AccountFormField(
                label: 'Email',
                controller: _email,
                validator: AccountValidators.email,
                keyboardType: TextInputType.emailAddress,
                hintText: 'name@university.edu',
              ),
              const SizedBox(height: 16),
              AccountFormField(
                label: 'Password',
                controller: _password,
                validator: AccountValidators.password,
                obscureText: true,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: Semantics(
                  button: true,
                  label: 'Create account',
                  child: ElevatedButton(
                    onPressed: submitting ? null : _submit,
                    child: submitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Create account'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SuccessView extends StatelessWidget {
  final UserProfile user;
  final VoidCallback onBack;
  final VoidCallback onCreateAnother;

  const _SuccessView({
    required this.user,
    required this.onBack,
    required this.onCreateAnother,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.check_circle_outline_rounded,
          size: 48,
          color: Colors.green,
        ),
        const SizedBox(height: 12),
        Text('Account created', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          '${user.name ?? 'User'} <${user.email}> was created '
          'successfully.',
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onCreateAnother,
            icon: const Icon(Icons.add),
            label: const Text('Create another account'),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back'),
          ),
        ),
      ],
    );
  }
}
