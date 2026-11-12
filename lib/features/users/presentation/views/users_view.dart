import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_notification.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../data/datasources/users_api_client.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/usecases/create_account_usecase.dart';
import '../cubit/create_account_cubit.dart';
import '../pages/create_account_page.dart';

/// Admin sidebar view: entry point for account management.
/// Connects to real Backend REST API to fetch and manage live user accounts.
class UsersView extends StatefulWidget {
  const UsersView({super.key});

  @override
  State<UsersView> createState() => _UsersViewState();
}

class _UsersViewState extends State<UsersView> {
  late final UsersApiClient _apiClient;
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String? _error;

  // Track inline draft edits per user: userId -> value
  final Map<String, String> _editedRoles = {};
  final Map<String, bool> _editedStatuses = {};
  final Set<String> _savingUserIds = {};
  final Set<String> _deletingUserIds = {};

  @override
  void initState() {
    super.initState();
    final authRepo = context.read<AuthRepository?>();
    _apiClient = UsersApiClient(
      tokenProvider: () async =>
          authRepo != null ? await authRepo.currentToken() : null,
    );
    _loadUsers();
  }

  int get _activeAdminCount {
    return _users.where((u) {
      final role = (u['role'] ?? '').toString().toLowerCase();
      final isActive = u['is_active'] != false;
      return role == 'admin' && isActive;
    }).length;
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _editedRoles.clear();
      _editedStatuses.clear();
    });

    try {
      final list = await _apiClient.getUsers();
      if (!mounted) return;
      setState(() {
        _users = list;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _open(BuildContext context, UserRole role) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider(
          create: (_) => CreateAccountCubit(
            createAccount: context.read<CreateAccountUseCase>(),
          ),
          child: CreateAccountPage(role: role),
        ),
      ),
    );
    if (mounted) {
      _loadUsers();
    }
  }

  String _formatDate(dynamic dateVal) {
    if (dateVal == null) return 'N/A';
    try {
      final dt = DateTime.parse(dateVal.toString()).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return dateVal.toString();
    }
  }

  Color _roleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return const Color(0xFF7C3AED);
      case 'lecturer':
        return AppColors.primary;
      case 'student':
      default:
        return const Color(0xFF0D9488);
    }
  }

  String _roleLabel(BuildContext context, String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return context.l10n.roleAdminLabel;
      case 'lecturer':
        return context.l10n.roleLecturerLabel;
      case 'student':
      default:
        return context.l10n.roleStudentLabel;
    }
  }

  Widget _buildRoleBadge(BuildContext context, String role) {
    final color = _roleColor(role);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _roleLabel(context, role),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
          fontFamily: 'Manrope',
        ),
      ),
    );
  }

  Future<void> _saveUserChanges(
    String userId,
    String email,
    String fullName,
  ) async {
    final newRole = _editedRoles[userId];
    final newStatus = _editedStatuses[userId];

    if (newRole == null && newStatus == null) return;

    // Safety check: Don't deactivate or demote last admin
    final user = _users.firstWhere(
      (u) => u['id']?.toString() == userId,
      orElse: () => {},
    );
    final isCurrentlyAdmin =
        (user['role'] ?? '').toString().toLowerCase() == 'admin';
    final isCurrentlyActive = user['is_active'] != false;

    if (isCurrentlyAdmin && isCurrentlyActive) {
      final isDemotingOrDeactivating =
          (newStatus == false) || (newRole != null && newRole != 'admin');
      if (isDemotingOrDeactivating && _activeAdminCount <= 1) {
        AppNotification.showError(
          context,
          context.l10n.cannotDemoteLastAdmin,
          title: context.l10n.unauthorizedActionTitle,
        );
        return;
      }
    }

    setState(() {
      _savingUserIds.add(userId);
    });

    try {
      final updated = await _apiClient.updateUser(
        userId,
        role: newRole,
        isActive: newStatus,
      );

      if (!mounted) return;
      setState(() {
        _savingUserIds.remove(userId);
        _editedRoles.remove(userId);
        _editedStatuses.remove(userId);

        // Update local list
        final index = _users.indexWhere((u) => u['id']?.toString() == userId);
        if (index != -1) {
          if (updated.isNotEmpty) {
            _users[index] = updated;
          } else {
            if (newRole != null) _users[index]['role'] = newRole;
            if (newStatus != null) _users[index]['is_active'] = newStatus;
          }
        }
      });

      AppNotification.showSuccess(
        context,
        context.l10n.userUpdateSuccess(email),
        title: context.l10n.updateSuccessTitle,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _savingUserIds.remove(userId);
      });
      AppNotification.showError(
        context,
        context.l10n.userUpdateError(
          e.toString().replaceFirst('Exception: ', ''),
        ),
        title: context.l10n.updateFailedTitle,
      );
    }
  }

  void _discardUserChanges(String userId) {
    setState(() {
      _editedRoles.remove(userId);
      _editedStatuses.remove(userId);
    });
  }

  void _confirmDeleteUser(
    String userId,
    String fullName,
    String email,
    bool isAdmin,
  ) {
    if (isAdmin && _activeAdminCount <= 1) {
      AppNotification.showError(
        context,
        context.l10n.cannotDeleteLastAdmin,
        title: context.l10n.unauthorizedActionTitle,
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.error,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              context.l10n.confirmDeleteUserTitle,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontFamily: 'Manrope',
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.confirmDeleteUserDesc,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontFamily: 'Manrope',
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName.isNotEmpty ? fullName : 'User',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontFamily: 'Manrope',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        fontFamily: 'Manrope',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                context.l10n.confirmDeleteUserWarning,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.error,
                  fontFamily: 'Manrope',
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              context.l10n.cancel,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontFamily: 'Manrope',
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              setState(() => _deletingUserIds.add(userId));
              try {
                await _apiClient.deleteUser(userId);
                if (!mounted) return;
                setState(() {
                  _deletingUserIds.remove(userId);
                  _users.removeWhere((u) => u['id']?.toString() == userId);
                  _editedRoles.remove(userId);
                  _editedStatuses.remove(userId);
                });
                AppNotification.showSuccess(
                  context,
                  context.l10n.userDeleteSuccess(email),
                  title: context.l10n.deleteUserTitle,
                );
              } catch (e) {
                if (!mounted) return;
                setState(() => _deletingUserIds.remove(userId));
                AppNotification.showError(
                  context,
                  context.l10n.userDeleteError(
                    e.toString().replaceFirst('Exception: ', ''),
                  ),
                  title: context.l10n.deleteFailedTitle,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              context.l10n.deletePermanently,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontFamily: 'Manrope',
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.usersViewTitle,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Manrope',
                      color: AppColors.textPrimary,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.usersViewSubtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textMuted,
                      fontFamily: 'Manrope',
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: _loadUsers,
                icon: const Icon(Icons.refresh_rounded),
                tooltip: context.l10n.reloadUsers,
                color: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Action Cards (Student & Lecturer Creation)
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 750;
              if (isNarrow) {
                return Column(
                  children: [
                    _ActionCard(
                      icon: Icons.school_outlined,
                      title: context.l10n.createStudentTitle,
                      subtitle: context.l10n.createStudentSubtitle,
                      badgeText: context.l10n.roleBadgeStudent,
                      onTap: () => _open(context, UserRole.student),
                      isExpanded: false,
                    ),
                    const SizedBox(height: 14),
                    _ActionCard(
                      icon: Icons.co_present_outlined,
                      title: context.l10n.createLecturerTitle,
                      subtitle: context.l10n.createLecturerSubtitle,
                      badgeText: context.l10n.roleBadgeLecturer,
                      onTap: () => _open(context, UserRole.lecturer),
                      isExpanded: false,
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  _ActionCard(
                    icon: Icons.school_outlined,
                    title: context.l10n.createStudentTitle,
                    subtitle: context.l10n.createStudentSubtitle,
                    badgeText: context.l10n.roleBadgeStudent,
                    onTap: () => _open(context, UserRole.student),
                  ),
                  const SizedBox(width: 20),
                  _ActionCard(
                    icon: Icons.co_present_outlined,
                    title: context.l10n.createLecturerTitle,
                    subtitle: context.l10n.createLecturerSubtitle,
                    badgeText: context.l10n.roleBadgeLecturer,
                    onTap: () => _open(context, UserRole.lecturer),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 28),

          // User Accounts Table
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: LayoutBuilder(
              builder: (context, tableConstraints) {
                final tableWidth = tableConstraints.maxWidth > 920
                    ? tableConstraints.maxWidth
                    : 920.0;
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: SizedBox(
                    width: tableWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          decoration: const BoxDecoration(
                            color: AppColors.surfaceSoft,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  context.l10n.colFullName,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSubtle,
                                    fontFamily: 'Manrope',
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 4,
                                child: Text(
                                  context.l10n.colAccountEmail,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSubtle,
                                    fontFamily: 'Manrope',
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  context.l10n.colRole,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSubtle,
                                    fontFamily: 'Manrope',
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  context.l10n.colStatus,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSubtle,
                                    fontFamily: 'Manrope',
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 80,
                                child: Text(
                                  context.l10n.colActions,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSubtle,
                                    fontFamily: 'Manrope',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (_isLoading)
                          const Padding(
                            padding: EdgeInsets.all(48),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (_error != null)
                          Padding(
                            padding: const EdgeInsets.all(32),
                            child: Center(
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.error_outline_rounded,
                                    color: AppColors.error,
                                    size: 36,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _error!,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontFamily: 'Manrope',
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  OutlinedButton.icon(
                                    onPressed: _loadUsers,
                                    icon: const Icon(
                                      Icons.refresh_rounded,
                                      size: 16,
                                    ),
                                    label: Text(context.l10n.retry),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else if (_users.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(48),
                            child: Center(
                              child: Text(
                                context.l10n.noUsersFound,
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontFamily: 'Manrope',
                                ),
                              ),
                            ),
                          )
                        else
                          for (int i = 0; i < _users.length; i++) ...[
                            _buildUserRow(_users[i]),
                            if (i < _users.length - 1)
                              const Divider(
                                height: 1,
                                color: AppColors.borderSoft,
                              ),
                          ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserRow(Map<String, dynamic> user) {
    final userId = user['id']?.toString() ?? '';
    final fullName =
        user['full_name'] ?? user['name'] ?? context.l10n.unknownUser;
    final email = user['email'] ?? '';
    final origRole = (user['role'] ?? 'student').toString().toLowerCase();
    final origStatus = user['is_active'] != false;

    final currentRole = _editedRoles[userId] ?? origRole;
    final currentStatus = _editedStatuses[userId] ?? origStatus;

    final isRoleEdited =
        _editedRoles.containsKey(userId) && _editedRoles[userId] != origRole;
    final isStatusEdited =
        _editedStatuses.containsKey(userId) &&
        _editedStatuses[userId] != origStatus;
    final isDirty = isRoleEdited || isStatusEdited;

    final isSaving = _savingUserIds.contains(userId);
    final isDeleting = _deletingUserIds.contains(userId);
    final isAdmin = origRole == 'admin';
    final isLastAdmin = isAdmin && _activeAdminCount <= 1;

    return Container(
      color: isDirty ? AppColors.surfaceSoft.withAlpha(60) : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        children: [
          // 1. Full name
          Expanded(
            flex: 3,
            child: Text(
              fullName,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontFamily: 'Manrope',
              ),
            ),
          ),

          // 2. Email & Created Date
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  email,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontFamily: 'Manrope',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${context.l10n.joined}: ${_formatDate(user['created_at'] ?? user['createdAt'])}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    fontFamily: 'Manrope',
                  ),
                ),
              ],
            ),
          ),

          // 3. Role Dropdown
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: isRoleEdited
                      ? Border.all(color: AppColors.primary, width: 1.5)
                      : null,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value:
                        ['student', 'lecturer', 'admin'].contains(currentRole)
                        ? currentRole
                        : 'student',
                    isDense: true,
                    borderRadius: BorderRadius.circular(8),
                    dropdownColor: AppColors.surface,
                    icon: const Icon(
                      Icons.arrow_drop_down_rounded,
                      size: 18,
                      color: AppColors.textSubtle,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'student',
                        child: _buildRoleBadge(context, 'student'),
                      ),
                      DropdownMenuItem(
                        value: 'lecturer',
                        child: _buildRoleBadge(context, 'lecturer'),
                      ),
                      DropdownMenuItem(
                        value: 'admin',
                        child: _buildRoleBadge(context, 'admin'),
                      ),
                    ],
                    onChanged: (newRole) {
                      if (newRole != null) {
                        setState(() {
                          if (newRole == origRole) {
                            _editedRoles.remove(userId);
                          } else {
                            _editedRoles[userId] = newRole;
                          }
                        });
                      }
                    },
                  ),
                ),
              ),
            ),
          ),

          // 4. Status Dropdown
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: isStatusEdited
                      ? Border.all(color: AppColors.primary, width: 1.5)
                      : null,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<bool>(
                    value: currentStatus,
                    isDense: true,
                    borderRadius: BorderRadius.circular(8),
                    dropdownColor: AppColors.surface,
                    icon: const Icon(
                      Icons.arrow_drop_down_rounded,
                      size: 18,
                      color: AppColors.textSubtle,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: true,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 14,
                              color: AppColors.green700,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              context.l10n.activeStatus,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.green700,
                                fontFamily: 'Manrope',
                              ),
                            ),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: false,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.cancel_rounded,
                              size: 14,
                              color: AppColors.error,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              context.l10n.inactiveStatus,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.error,
                                fontFamily: 'Manrope',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (newStatus) {
                      if (newStatus != null) {
                        setState(() {
                          if (newStatus == origStatus) {
                            _editedStatuses.remove(userId);
                          } else {
                            _editedStatuses[userId] = newStatus;
                          }
                        });
                      }
                    },
                  ),
                ),
              ),
            ),
          ),

          // 5. Action column (Mini-Action Bar)
          SizedBox(
            width: 80,
            child: isSaving || isDeleting
                ? const Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : isDirty
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Tooltip(
                        message: context.l10n.saveChanges,
                        child: InkWell(
                          onTap: () =>
                              _saveUserChanges(userId, email, fullName),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Tooltip(
                        message: context.l10n.cancelChanges,
                        child: InkWell(
                          onTap: () => _discardUserChanges(userId),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSoft,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: AppColors.textSubtle,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: _SubtleDeleteButton(
                      isLastAdmin: isLastAdmin,
                      onPressed: isLastAdmin
                          ? () {
                              AppNotification.showError(
                                context,
                                context.l10n.cannotDeleteLastAdmin,
                                title: context.l10n.unauthorizedActionTitle,
                              );
                            }
                          : () => _confirmDeleteUser(
                              userId,
                              fullName,
                              email,
                              isAdmin,
                            ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String badgeText;
  final VoidCallback onTap;
  final bool isExpanded;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.onTap,
    this.isExpanded = true,
  });

  @override
  Widget build(BuildContext context) {
    final cardContent = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: isExpanded ? null : double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink900.withAlpha(4),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.blue50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 22),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    badgeText,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      fontFamily: 'Manrope',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontFamily: 'Manrope',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
                fontFamily: 'Manrope',
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  context.l10n.initiateNow,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    fontFamily: 'Manrope',
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                  color: AppColors.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (isExpanded) {
      return Expanded(child: cardContent);
    }
    return cardContent;
  }
}

class _SubtleDeleteButton extends StatefulWidget {
  final bool isLastAdmin;
  final VoidCallback onPressed;

  const _SubtleDeleteButton({
    required this.isLastAdmin,
    required this.onPressed,
  });

  @override
  State<_SubtleDeleteButton> createState() => _SubtleDeleteButtonState();
}

class _SubtleDeleteButtonState extends State<_SubtleDeleteButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    if (widget.isLastAdmin) {
      return IconButton(
        onPressed: widget.onPressed,
        icon: const Icon(Icons.delete_outline_rounded, size: 18),
        color: AppColors.slate300,
        tooltip: context.l10n.cannotDeleteLastAdmin,
        splashRadius: 18,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        padding: EdgeInsets.zero,
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: IconButton(
        onPressed: widget.onPressed,
        icon: const Icon(Icons.delete_outline_rounded, size: 18),
        color: _isHovered ? AppColors.error : AppColors.textSubtle,
        tooltip: context.l10n.deleteAccountTooltip,
        splashRadius: 18,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        padding: EdgeInsets.zero,
      ),
    );
  }
}
