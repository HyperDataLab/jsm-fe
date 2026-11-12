import 'package:material_ui/material_ui.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_notification.dart';
import '../../../../core/localization/app_localizations.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  bool _autoPurge = true;
  double _retentionDays = 30.0;
  bool _politePool = true;
  double _requestsPerSecond = 10.0;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            context.l10n.settingsTitle,
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
            context.l10n.settingsSubtitle,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textMuted,
              fontFamily: 'Manrope',
            ),
          ),
          const SizedBox(height: 24),

          // SSO Authentication Panel
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      context.l10n.ssoTitle,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontFamily: 'Manrope',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderSoft),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.green50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.green100),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: AppColors.green700,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.ssoConnected,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                fontFamily: 'Manrope',
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              context.l10n.ssoProvider,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                                fontFamily: 'Manrope',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.green50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          context.l10n.ssoActive,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.green700,
                            fontFamily: 'Manrope',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Privacy & Retention Panel
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.privacy_tip_outlined,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      context.l10n.privacyTitle,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontFamily: 'Manrope',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  context.l10n.privacyDesc,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                    fontFamily: 'Manrope',
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    context.l10n.autoPurgeTitle,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Manrope',
                    ),
                  ),
                  subtitle: Text(
                    context.l10n.autoPurgeSubtitle(_retentionDays.toInt()),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      fontFamily: 'Manrope',
                    ),
                  ),
                  value: _autoPurge,
                  activeThumbColor: AppColors.primary,
                  onChanged: (val) => setState(() => _autoPurge = val),
                ),
                Slider(
                  value: _retentionDays,
                  min: 1,
                  max: 30,
                  divisions: 29,
                  activeColor: AppColors.primary,
                  onChanged: _autoPurge
                      ? (val) => setState(() => _retentionDays = val)
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Polite Crawler Panel
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.speed_rounded,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      context.l10n.politePoolTitle,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontFamily: 'Manrope',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  context.l10n.politePoolDesc,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                    fontFamily: 'Manrope',
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    context.l10n.politePoolEnable,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Manrope',
                    ),
                  ),
                  subtitle: Text(
                    context.l10n.politePoolSubtitle(_requestsPerSecond.toInt()),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      fontFamily: 'Manrope',
                    ),
                  ),
                  value: _politePool,
                  activeThumbColor: AppColors.primary,
                  onChanged: (val) => setState(() => _politePool = val),
                ),
                Slider(
                  value: _requestsPerSecond,
                  min: 1,
                  max: 20,
                  divisions: 19,
                  activeColor: AppColors.primary,
                  onChanged: _politePool
                      ? (val) => setState(() => _requestsPerSecond = val)
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Save button
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () {
                AppNotification.showSuccess(
                  context,
                  context.l10n.settingsSaved,
                  title: 'Đã lưu cấu hình',
                );
              },
              icon: const Icon(Icons.save_rounded, size: 18),
              label: Text(context.l10n.saveAllSettings),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
