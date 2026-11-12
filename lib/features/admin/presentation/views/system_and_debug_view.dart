import 'package:material_ui/material_ui.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../users/presentation/views/users_view.dart';
import 'job_monitor_view.dart';
import 'settings_view.dart';

/// System & Debug Unified Workspace (Tab 2)
/// Consolidates Job Monitoring, Article Debugging, System Services Configuration,
/// and User Administration into a single administrative hub.
class SystemAndDebugView extends StatefulWidget {
  final Function(int) onNavigateToTab;
  final VoidCallback? onTriggerNewAnalysis;
  final int initialSubTabIndex;

  const SystemAndDebugView({
    super.key,
    required this.onNavigateToTab,
    this.onTriggerNewAnalysis,
    this.initialSubTabIndex = 0,
  });

  @override
  State<SystemAndDebugView> createState() => _SystemAndDebugViewState();
}

class _SystemAndDebugViewState extends State<SystemAndDebugView> {
  late int _activeSubTab;

  @override
  void initState() {
    super.initState();
    _activeSubTab = widget.initialSubTabIndex;
  }

  @override
  void didUpdateWidget(covariant SystemAndDebugView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSubTabIndex != widget.initialSubTabIndex) {
      setState(() => _activeSubTab = widget.initialSubTabIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Segmented Navigation Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(
              bottom: BorderSide(color: AppColors.border, width: 1),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildSegmentItem(
                  index: 0,
                  icon: Icons.monitor_heart_rounded,
                  title: context.l10n.tabJobMonitorTitle,
                  subtitle: context.l10n.tabJobMonitorSubtitle,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildSegmentItem(
                  index: 1,
                  icon: Icons.tune_rounded,
                  title: context.l10n.tabServiceSettingsTitle,
                  subtitle: context.l10n.tabServiceSettingsSubtitle,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildSegmentItem(
                  index: 2,
                  icon: Icons.manage_accounts_rounded,
                  title: context.l10n.tabUserManagementTitle,
                  subtitle: context.l10n.tabUserManagementSubtitle,
                ),
              ),
            ],
          ),
        ),

        // Sub-view Body (Using IndexedStack to preserve child state)
        Expanded(
          child: IndexedStack(
            index: _activeSubTab,
            children: [
              JobMonitorView(
                onNavigateToTab: widget.onNavigateToTab,
                onTriggerNewAnalysis: widget.onTriggerNewAnalysis,
              ),
              const SettingsView(),
              const UsersView(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentItem({
    required int index,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _activeSubTab == index;

    return InkWell(
      onTap: () => setState(() => _activeSubTab = index),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.blue50 : AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w600,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                      fontFamily: 'Manrope',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      fontFamily: 'Manrope',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
