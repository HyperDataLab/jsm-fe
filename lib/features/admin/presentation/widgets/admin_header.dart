import 'package:material_ui/material_ui.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/search_input_box.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/language_switcher.dart';

class AdminHeader extends StatelessWidget {
  final int selectedIndex;
  final VoidCallback? onNewJobPressed;
  final ValueChanged<String>? onSearchChanged;

  const AdminHeader({
    super.key,
    required this.selectedIndex,
    this.onNewJobPressed,
    this.onSearchChanged,
  });

  String _getTitle(BuildContext context) {
    switch (selectedIndex) {
      case 0:
        return context.l10n.titleJournalsMining;
      case 1:
        return context.l10n.titleNlpProfiles;
      case 2:
        return context.l10n.titleSystemDebug;
      default:
        return context.l10n.titleAdminDashboard;
    }
  }

  String _getBreadcrumb(BuildContext context) {
    switch (selectedIndex) {
      case 0:
        return context.l10n.breadcrumbResearch;
      case 1:
        return context.l10n.breadcrumbAcademic;
      case 2:
        return context.l10n.breadcrumbSystem;
      default:
        return context.l10n.breadcrumbAdmin;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: Row(
        children: [
          // Breadcrumb & Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _getBreadcrumb(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Manrope',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getTitle(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    fontFamily: 'Manrope',
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Sleek animated search input (ResearchPulse FE style)
          SearchInputBox(
            hintText: context.l10n.searchPlaceholder,
            height: 38,
            expandOnFocus: true,
            width: 270,
            expandedWidth: 320,
            onChanged: onSearchChanged,
          ),
          const SizedBox(width: 14),

          // Language Switcher on navbar right
          const LanguageSwitcher(),
        ],
      ),
    );
  }
}
