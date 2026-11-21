import 'package:material_ui/material_ui.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../constants/app_constants.dart';
import '../../../localization/app_localizations.dart';
import 'update_dialog.dart';

/// Header action button to trigger the check for updates dialog.
/// Matches the styling of LanguageSwitcher on navigation headers.
class CheckUpdateButton extends StatelessWidget {
  final bool isLight;
  final bool? compact;

  const CheckUpdateButton({super.key, this.isLight = false, this.compact});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final screenWidth = MediaQuery.maybeOf(context)?.size.width ?? 1200;
    final showLabel = compact == null ? (screenWidth >= 900) : !compact!;

    return Tooltip(
      message: l10n.updateTooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => UpdateDialog.show(context),
          borderRadius: BorderRadius.circular(10),
          hoverColor: AppColors.primarySoft,
          splashColor: AppColors.primary.withAlpha(20),
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isLight
                  ? Colors.white.withAlpha(200)
                  : AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isLight ? Colors.white.withAlpha(80) : AppColors.border,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.system_update_alt_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
                if (showLabel) ...[
                  const SizedBox(width: 6),
                  Text(
                    l10n.checkUpdate,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontFamily: 'Manrope',
                      letterSpacing: -0.1,
                    ),
                  ),
                ],
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.border, width: 0.8),
                  ),
                  child: const Text(
                    'v${AppConstants.appVersion}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      fontFamily: 'Manrope',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
