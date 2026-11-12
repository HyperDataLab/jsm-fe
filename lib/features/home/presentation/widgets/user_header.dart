import 'package:material_ui/material_ui.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/language_switcher.dart';
import '../../../../core/localization/app_localizations.dart';

class UserHeader extends StatelessWidget {
  final int selectedIndex;
  final VoidCallback? onResetCheck;

  const UserHeader({super.key, required this.selectedIndex, this.onResetCheck});

  String _getBreadcrumb(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (selectedIndex) {
      case 0:
        return '${l10n.academicWorkspace} / ${l10n.navManuscriptChecker}';
      case 1:
        return '${l10n.academicWorkspace} / ${l10n.navJournalRecommendations}';
      case 2:
        return '${l10n.academicWorkspace} / ${l10n.navEvaluationHistory}';
      default:
        return l10n.academicWorkspace;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.sidebarBorder, width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            _getBreadcrumb(context),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSubtle,
              fontWeight: FontWeight.w500,
              fontFamily: 'Manrope',
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.sidebarActive,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              context.l10n.journalDashboardBadge,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                fontFamily: 'Manrope',
              ),
            ),
          ),
          const Spacer(),
          const LanguageSwitcher(),
        ],
      ),
    );
  }
}
