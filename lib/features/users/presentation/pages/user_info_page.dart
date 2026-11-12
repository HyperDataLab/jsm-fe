import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../widgets/local_data_backup_card.dart';

import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/language_switcher.dart';
import '../../../../core/widgets/app_notification.dart';

/// Displays the authenticated user's Central SSO profile information.
/// Unified with the HyperData Lab scientific platform design system.
class UserInfoPage extends StatelessWidget {
  const UserInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildCustomHeader(context),
          Expanded(
            child: BlocBuilder<AuthCubit, AuthState>(
              builder: (context, state) {
                if (state is! AuthAuthenticated) {
                  return Center(
                    child: Text(
                      context.l10n.notSignedIn,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontFamily: 'Manrope',
                      ),
                    ),
                  );
                }
                final user = state.user;
                return _buildProfileDashboard(context, user);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomHeader(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
            tooltip: 'Quay lại',
          ),
          const SizedBox(width: 8),
          const Text(
            'System / Account',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
              fontFamily: 'Manrope',
            ),
          ),
          const Spacer(),
          const LanguageSwitcher(),
        ],
      ),
    );
  }

  Widget _buildProfileDashboard(BuildContext context, AuthUser user) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: SingleChildScrollView(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Page Title & Subtitle
                  const Text(
                    'Account Profile',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      fontFamily: 'Manrope',
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Manage your account information and authentication details.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      fontFamily: 'Manrope',
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── 1. Profile Identity Cover (Top) ──
                  _ProfileIdentityCard(user: user),
                  const SizedBox(height: 24),

                  // ── 2. Profile Details & Account Access (Bottom 2-col) ──
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 768;

                      if (isWide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 55,
                              child: _ProfileDetailsCard(user: user),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              flex: 45,
                              child: _AccountAccessCard(user: user),
                            ),
                          ],
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _ProfileDetailsCard(user: user),
                          const SizedBox(height: 24),
                          _AccountAccessCard(user: user),
                        ],
                      );
                    },
                  ),
                  const LocalDataBackupCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. Profile Identity Card
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileIdentityCard extends StatelessWidget {
  final AuthUser user;

  const _ProfileIdentityCard({required this.user});

  String _cleanName(String rawName) {
    return rawName
        .replaceAll(
          RegExp(r'\s*\((?:Admin|admin|ADMIN|User|USER|Editor|EDITOR)\)\s*'),
          '',
        )
        .trim();
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    final rawName = user.name ?? user.email ?? 'Unknown User';
    final displayName = _cleanName(rawName);
    final email = user.email ?? '—';
    final role = (user.role ?? 'USER').toUpperCase();

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink900.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Subtle top accent line curving with card radius
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(height: 3, color: AppColors.primary),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.blue50,
                    border: Border.all(color: AppColors.blue100, width: 2),
                    image: user.picture != null
                        ? DecorationImage(
                            image: NetworkImage(user.picture!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: user.picture == null
                      ? Center(
                          child: Text(
                            _initials(displayName),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                              fontFamily: 'Manrope',
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 24),

                // Name, Email & Status Badges
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          fontFamily: 'Manrope',
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          fontFamily: 'Manrope',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _RoleBadge(role: role),
                          const SizedBox(width: 12),
                          const _ActiveStatusDot(),
                        ],
                      ),
                    ],
                  ),
                ),

                // Account Context (Desktop only)
                if (MediaQuery.of(context).size.width >= 768) ...[
                  Container(
                    width: 1,
                    height: 50,
                    color: AppColors.borderSoft,
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                  ),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _CompactMetadataItem(
                        label: 'ACCOUNT',
                        value: 'SSO Managed',
                      ),
                      SizedBox(height: 12),
                      _CompactMetadataItem(
                        label: 'ORGANIZATION',
                        value: 'HyperData Lab',
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactMetadataItem extends StatelessWidget {
  final String label;
  final String value;

  const _CompactMetadataItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.textSubtle,
            fontFamily: 'Manrope',
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            fontFamily: 'Manrope',
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. Profile Details Card
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileDetailsCard extends StatelessWidget {
  final AuthUser user;

  const _ProfileDetailsCard({required this.user});

  String _cleanName(String rawName) {
    return rawName
        .replaceAll(
          RegExp(r'\s*\((?:Admin|admin|ADMIN|User|USER|Editor|EDITOR)\)\s*'),
          '',
        )
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    final rawName = user.name ?? '—';
    final displayName = _cleanName(rawName);
    final email = user.email ?? '—';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Profile Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFamily: 'Manrope',
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Personal information associated with your account.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                    fontFamily: 'Manrope',
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.borderSoft),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _DetailRow(
                  icon: Icons.person_outline_rounded,
                  label: 'Full name',
                  valueWidget: Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontFamily: 'Manrope',
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.borderSoft,
                ),
                const SizedBox(height: 20),
                _DetailRow(
                  icon: Icons.mail_outline_rounded,
                  label: 'Email address',
                  valueWidget: Text(
                    email,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontFamily: 'Manrope',
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.borderSoft,
                ),
                const SizedBox(height: 20),
                const _DetailRow(
                  icon: Icons.business_rounded,
                  label: 'Organization',
                  valueWidget: Text(
                    'HyperData Lab',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontFamily: 'Manrope',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. Account & Access Card
// ─────────────────────────────────────────────────────────────────────────────

class _AccountAccessCard extends StatelessWidget {
  final AuthUser user;

  const _AccountAccessCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final role = (user.role ?? 'USER').toUpperCase();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Account & Access',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFamily: 'Manrope',
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Authentication and permissions for this account.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                    fontFamily: 'Manrope',
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.borderSoft),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow(
                  icon: Icons.shield_outlined,
                  label: 'Account role',
                  valueWidget: Text(
                    role,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontFamily: 'Manrope',
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.borderSoft,
                ),
                const SizedBox(height: 20),
                const _DetailRow(
                  icon: Icons.lock_outline_rounded,
                  label: 'Authentication',
                  valueWidget: Text(
                    'Single Sign-On',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontFamily: 'Manrope',
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.borderSoft,
                ),
                const SizedBox(height: 20),
                _DetailRow(
                  icon: Icons.fingerprint_rounded,
                  label: 'Subject ID',
                  valueWidget: _CopyableSubjectId(subjectId: user.sub),
                ),
                const SizedBox(height: 28),
                const _SsoManagedNotice(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Components
// ─────────────────────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget valueWidget;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.valueWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF94A3B8)), // slate-400
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                  fontFamily: 'Manrope',
                ),
              ),
              const SizedBox(height: 4),
              valueWidget,
            ],
          ),
        ),
      ],
    );
  }
}

class _CopyableSubjectId extends StatefulWidget {
  final String subjectId;

  const _CopyableSubjectId({required this.subjectId});

  @override
  State<_CopyableSubjectId> createState() => _CopyableSubjectIdState();
}

class _CopyableSubjectIdState extends State<_CopyableSubjectId> {
  bool _copied = false;

  void _handleCopy() {
    Clipboard.setData(ClipboardData(text: widget.subjectId));
    setState(() => _copied = true);
    AppNotification.showSuccess(
      context,
      'Subject ID copied to clipboard',
      duration: const Duration(seconds: 2),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9), // slate-100
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFE2E8F0)), // slate-200
            ),
            child: Text(
              widget.subjectId,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
                fontFamily: 'JetBrains Mono',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: 'Copy Subject ID',
          child: InkWell(
            onTap: _handleCopy,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                _copied ? Icons.check_rounded : Icons.copy_rounded,
                size: 16,
                color: _copied ? AppColors.green700 : AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SsoManagedNotice extends StatelessWidget {
  const _SsoManagedNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(8), // Very subtle blue tint (~3%)
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withAlpha(30)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.verified_user_outlined,
            size: 18,
            color: AppColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Managed by Single Sign-On',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    fontFamily: 'Manrope',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Identity and authentication are securely managed by your organization\'s SSO provider.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary.withAlpha(200),
                    fontFamily: 'Manrope',
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;

  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.primary.withAlpha(60), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.shield_outlined, size: 12, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            role,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              letterSpacing: 0.4,
              fontFamily: 'Manrope',
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveStatusDot extends StatelessWidget {
  const _ActiveStatusDot();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: Color(0xFF16A34A),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        const Text(
          'Active',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF16A34A),
            fontFamily: 'Manrope',
          ),
        ),
      ],
    );
  }
}
