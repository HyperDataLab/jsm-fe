import 'package:material_ui/material_ui.dart';

/// Hyperdata Lab FE Design System Tokens
/// Primary brand color: #0071bc
/// Design language: quiet research-grade product UI, generous whitespace,
/// cool paper surfaces, confident blue actions.
class AppColors {
  AppColors._();

  // Primitive: Brand palette
  static const Color blue700 = Color(0xFF005F9E);
  static const Color blue600 = Color(0xFF0071BC); // Primary Brand
  static const Color blue100 = Color(0xFFDBEEF9);
  static const Color blue50 = Color(0xFFF0F7FC);

  // Primitive: Cool neutral palette
  static const Color ink900 = Color(0xFF122331);
  static const Color slate600 = Color(0xFF647381);
  static const Color slate400 = Color(0xFF8B9AA4);
  static const Color slate300 = Color(0xFFC5D1D9);
  static const Color slate200 = Color(0xFFDCE4E9);
  static const Color slate100 = Color(0xFFE8EEF2);
  static const Color paper50 = Color(0xFFF7F9FA); // Page background
  static const Color surface0 = Colors.white;

  // Primitive: Feedback
  static const Color red700 = Color(0xFFB42318);
  static const Color red100 = Color(0xFFF2B8B5);
  static const Color red50 = Color(0xFFFFF5F4);

  static const Color green700 = Color(0xFF176B36);
  static const Color green100 = Color(0xFFB7DFC5);
  static const Color green50 = Color(0xFFF2FBF5);

  // Semantic Aliases
  static const Color primary = blue600;
  static const Color primaryHover = blue700;
  static const Color primarySoft = blue50;
  static const Color onPrimary = Colors.white;

  static const Color background = paper50;
  static const Color surface = surface0;
  static const Color surfaceSoft = Color(0xFFF3F6F9);
  static const Color surfaceMuted = Color(0xFFEDF3F7);

  static const Color textPrimary = ink900;
  static const Color textSecondary = slate600;
  static const Color textMuted = slate600;
  static const Color textSubtle = slate400;
  static const Color border = slate200;
  static const Color borderSoft = slate100;

  static const Color error = red700;
  static const Color errorBorder = red100;
  static const Color errorSurface = red50;

  static const Color success = green700;
  static const Color successBorder = green100;
  static const Color successSurface = green50;

  static const Color warning = Color(0xFFB45309);
  static const Color warningBorder = Color(0xFFFDE68A);
  static const Color warningSurface = Color(0xFFFFFBEB);

  static const Color primaryAccent = blue600;
  static const Color statusSuccess = green700;
  static const Color statusError = red700;
  static const Color statusRunning = blue600;
  static const Color statusWarning = Color(0xFFF59E0B);

  // Sidebar styling: Light, clean, cool paper look matching screenshot
  static const Color sidebarBackground = Colors.white;
  static const Color sidebarBorder = Color(0xFFE8EEF2);
  static const Color sidebarSectionText = Color(0xFF8B9AA4);
  static const Color sidebarHover = Color(0xFFF7F9FA);
  static const Color sidebarActive = Color(
    0xFFE1F0FA,
  ); // Soft blue selection pill
  static const Color sidebarActiveText = blue600; // #0071bc
  static const Color sidebarActiveIcon = blue600;
  static const Color sidebarTextActive = blue600;
  static const Color sidebarTextInactive = Color(0xFF334155);
  static const Color sidebarIconInactive = Color(0xFF64748B);
}
