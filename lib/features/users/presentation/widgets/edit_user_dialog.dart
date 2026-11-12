import 'package:material_ui/material_ui.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/datasources/users_api_client.dart';
import 'account_form_field.dart';

/// Modal dialog for editing user profile information (Name, Email, Role, Password, Status).
class EditUserDialog extends StatefulWidget {
  final Map<String, dynamic> user;
  final UsersApiClient apiClient;

  const EditUserDialog({
    super.key,
    required this.user,
    required this.apiClient,
  });

  @override
  State<EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<EditUserDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late String _selectedRole;
  late bool _isActive;
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(
      text: widget.user['full_name'] ?? widget.user['name'] ?? '',
    );
    _emailController = TextEditingController(text: widget.user['email'] ?? '');
    _passwordController = TextEditingController();
    _selectedRole = (widget.user['role'] ?? 'student').toString().toLowerCase();
    if (!['student', 'lecturer', 'admin'].contains(_selectedRole)) {
      _selectedRole = 'student';
    }
    _isActive = widget.user['is_active'] ?? true;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final userId = widget.user['id']?.toString() ?? '';
      await widget.apiClient.updateUser(
        userId,
        fullName: _fullNameController.text.trim(),
        role: _selectedRole,
        isActive: _isActive,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      backgroundColor: AppColors.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dialog Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.blue50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.manage_accounts_rounded,
                              color: AppColors.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            context.l10n.editUserTitle,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              fontFamily: 'Manrope',
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded, size: 20),
                        color: AppColors.textSubtle,
                        tooltip: context.l10n.close,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.l10n.editUserSubtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                      fontFamily: 'Manrope',
                    ),
                  ),
                  const Divider(height: 28, color: AppColors.borderSoft),

                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.errorSurface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.errorBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: AppColors.error,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: AppColors.error,
                                fontSize: 13,
                                fontFamily: 'Manrope',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Full Name Field
                  AccountFormField(
                    label: context.l10n.fullNameRequired,
                    controller: _fullNameController,
                    hintText: context.l10n.enterFullNameHint,
                    validator: AccountValidators.fullName,
                  ),
                  const SizedBox(height: 16),

                  // Email Field
                  AccountFormField(
                    label: context.l10n.accountEmailRequired,
                    controller: _emailController,
                    hintText: 'user@example.edu.vn',
                    keyboardType: TextInputType.emailAddress,
                    validator: AccountValidators.email,
                  ),
                  const SizedBox(height: 16),

                  // Role Dropdown
                  Text(
                    context.l10n.systemRoleRequired,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      fontFamily: 'Manrope',
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedRole,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'student',
                        child: Text(
                          context.l10n.roleStudentDesc,
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 13,
                          ),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'lecturer',
                        child: Text(
                          context.l10n.roleLecturerDesc,
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 13,
                          ),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'admin',
                        child: Text(
                          context.l10n.roleAdminDesc,
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedRole = val);
                    },
                  ),
                  const SizedBox(height: 16),

                  // New Password Field (Optional)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.newPasswordOptional,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          fontFamily: 'Manrope',
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: context.l10n.passwordKeepBlankHint,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 18,
                              color: AppColors.textSubtle,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value != null &&
                              value.isNotEmpty &&
                              value.length < 6) {
                            return context.l10n.passwordMinLengthError;
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Active status Switch
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSoft,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.borderSoft),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.accountStatusLabel,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                fontFamily: 'Manrope',
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              _isActive
                                  ? context.l10n.statusActiveDesc
                                  : context.l10n.statusInactiveDesc,
                              style: TextStyle(
                                fontSize: 12,
                                color: _isActive
                                    ? AppColors.green700
                                    : AppColors.error,
                                fontFamily: 'Manrope',
                              ),
                            ),
                          ],
                        ),
                        Switch.adaptive(
                          value: _isActive,
                          activeThumbColor: AppColors.primary,
                          onChanged: (val) => setState(() => _isActive = val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Dialog Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          context.l10n.cancel,
                          style: const TextStyle(fontFamily: 'Manrope'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                context.l10n.saveChanges,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Manrope',
                                ),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
