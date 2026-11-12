import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/theme/app_colors.dart';
import '../localization/app_localizations.dart';
import '../localization/locale_cubit.dart';

/// Compact language switcher button designed for navbars and headers.
/// Displays the current active language (EN / VI) and allows switching.
class LanguageSwitcher extends StatelessWidget {
  final bool isLight;

  const LanguageSwitcher({super.key, this.isLight = false});

  @override
  Widget build(BuildContext context) {
    Locale? locale;
    try {
      locale = context.watch<LocaleCubit?>()?.state;
    } catch (_) {}
    locale ??= Localizations.maybeLocaleOf(context) ?? const Locale('vi');
    final isVi = locale.languageCode == 'vi';

    return Tooltip(
      message: context.l10n.languageSwitcherTooltip,
      child: PopupMenuButton<String>(
        tooltip: '',
        offset: const Offset(0, 40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        color: AppColors.surface,
        elevation: 4,
        onSelected: (String code) {
          try {
            context.read<LocaleCubit?>()?.setLocale(Locale(code));
          } catch (_) {}
        },
        itemBuilder: (BuildContext ctx) => [
          PopupMenuItem<String>(
            value: 'en',
            height: 40,
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: AppColors.border),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'EN',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      fontFamily: 'Manrope',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'English',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Manrope',
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (!isVi)
                  const Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
              ],
            ),
          ),
          const PopupMenuDivider(height: 1),
          PopupMenuItem<String>(
            value: 'vi',
            height: 40,
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: AppColors.border),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'VI',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      fontFamily: 'Manrope',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Tiếng Việt',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Manrope',
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (isVi)
                  const Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
              ],
            ),
          ),
        ],
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
              Icon(
                Icons.language_rounded,
                size: 16,
                color: isVi ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                isVi ? 'VI' : 'EN',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isVi ? AppColors.primary : AppColors.textPrimary,
                  fontFamily: 'Manrope',
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: AppColors.textSubtle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
