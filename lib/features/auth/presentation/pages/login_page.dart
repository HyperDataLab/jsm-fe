import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/app_notification.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/language_switcher.dart';
import '../../domain/entities/auth_provider.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

/// Login page: Academic / Research-grade design matching Hyperdata Lab design language.
/// Uses Central SSO (OIDC + PKCE) for universal authentication.
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const LoginView();
  }
}

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _cardFade;
  late final Animation<Offset> _cardSlide;
  late final Animation<double> _emblemScale;
  String? _lastFailureMessage;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _cardFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.75, curve: Curves.easeOutCubic),
    );

    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.0, 0.85, curve: Curves.easeOutCubic),
          ),
        );

    _emblemScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.15, 0.9, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = context.read<AuthCubit>().state;
      if (state is AuthFailure) _showFailure(context, state);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _launch(BuildContext context, AuthProvider provider) {
    context.read<AuthCubit>().login(provider);
  }

  void _showFailure(BuildContext context, AuthFailure state) {
    if (_lastFailureMessage == state.message) return;
    _lastFailureMessage = state.message;
    final message =
        state.message == 'Login was cancelled.' ||
            state.message == 'Login was cancelled or could not be completed.'
        ? context.l10n.loginCancelledMessage
        : state.message;
    AppNotification.showError(
      context,
      message,
      title: context.l10n.loginFailedTitle,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background ambient gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFEEF5FA),
                    AppColors.background,
                    Color(0xFFE9F1F7),
                  ],
                ),
              ),
            ),
          ),

          // Ambient subtle background glows for visual depth
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withAlpha(18),
                    AppColors.primary.withAlpha(0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF00B4D8).withAlpha(14),
                    const Color(0xFF00B4D8).withAlpha(0),
                  ],
                ),
              ),
            ),
          ),

          // Top Header Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    // Brand Logo
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/images/app_logo.png',
                        width: 34,
                        height: 34,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 10),
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 16,
                          letterSpacing: -0.2,
                        ),
                        children: [
                          TextSpan(
                            text: 'HyperData',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextSpan(
                            text: 'Lab',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.hub_rounded,
                            size: 13,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'journal system miner',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                              fontFamily: 'Manrope',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    const LanguageSwitcher(),
                  ],
                ),
              ),
            ),
          ),

          // Center Authentication Card
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: BlocConsumer<AuthCubit, AuthState>(
                  listener: (context, state) {
                    if (state is AuthFailure) {
                      _showFailure(context, state);
                    }
                  },
                  builder: (context, state) {
                    final busy = state is AuthLoading;

                    return FadeTransition(
                      opacity: _cardFade,
                      child: SlideTransition(
                        position: _cardSlide,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Card
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.border,
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.ink900.withAlpha(12),
                                    blurRadius: 28,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 32,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Icon emblem with scale pop
                                  ScaleTransition(
                                    scale: _emblemScale,
                                    child: Container(
                                      width: 52,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        color: AppColors.blue50,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppColors.blue100,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.lock_rounded,
                                          color: AppColors.primary,
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 18),

                                  // Title
                                  Text(
                                    context.l10n.signIn,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      fontFamily: 'Manrope',
                                      color: AppColors.textPrimary,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 6),

                                  // Subtitle
                                  Text(
                                    context.l10n.authPortalSubtitle,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                      fontFamily: 'Manrope',
                                      height: 1.45,
                                    ),
                                  ),
                                  const SizedBox(height: 18),

                                  // SSO security chip
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.blue50,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: AppColors.blue100,
                                        width: 1,
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.security_rounded,
                                          size: 13,
                                          color: AppColors.primary,
                                        ),
                                        SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            'Central SSO • OIDC PKCE',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.primary,
                                              fontFamily: 'Manrope',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 26),

                                  // Primary Button: Sign in
                                  SizedBox(
                                    width: double.infinity,
                                    height: 48,
                                    child: Semantics(
                                      button: true,
                                      label: context.l10n.signIn,
                                      child: ElevatedButton(
                                        onPressed: busy
                                            ? null
                                            : () => _launch(
                                                context,
                                                AuthProvider.web,
                                              ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shadowColor: AppColors.primary
                                              .withAlpha(60),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        child: AnimatedSwitcher(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          transitionBuilder:
                                              (child, animation) =>
                                                  FadeTransition(
                                                    opacity: animation,
                                                    child: child,
                                                  ),
                                          child: busy
                                              ? const SizedBox(
                                                  key: ValueKey('loading'),
                                                  height: 20,
                                                  width: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: Colors.white,
                                                      ),
                                                )
                                              : Row(
                                                  key: const ValueKey(
                                                    'content',
                                                  ),
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    const Icon(
                                                      Icons.login_rounded,
                                                      size: 18,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      context.l10n.signIn,
                                                      style: const TextStyle(
                                                        fontSize: 14.5,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        fontFamily: 'Manrope',
                                                        letterSpacing: 0.1,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  if (!AppConstants.isProduction) ...[
                                    const SizedBox(height: 20),

                                    // Divider: Test Mock Accounts
                                    Row(
                                      children: [
                                        const Expanded(
                                          child: Divider(
                                            color: AppColors.border,
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                          ),
                                          child: Text(
                                            context.l10n.orSimulateSso,
                                            style: const TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textSubtle,
                                              fontFamily: 'Manrope',
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                        const Expanded(
                                          child: Divider(
                                            color: AppColors.border,
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 14),

                                    // Button Mock ADMIN
                                    SizedBox(
                                      width: double.infinity,
                                      height: 46,
                                      child: OutlinedButton(
                                        onPressed: busy
                                            ? null
                                            : () => context
                                                  .read<AuthCubit>()
                                                  .mockLogin(
                                                    sub: 'mock-sso-admin-id',
                                                    email: 'admin@jsm.edu.vn',
                                                    name: context
                                                        .l10n
                                                        .ssoAdminRole,
                                                    role: 'ADMIN',
                                                  ),
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(
                                            color: Color(0xFF7C3AED),
                                            width: 1.5,
                                          ),
                                          backgroundColor: const Color(
                                            0xFFF5F3FF,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons
                                                  .admin_panel_settings_rounded,
                                              size: 18,
                                              color: Color(0xFF7C3AED),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                context.l10n.ssoAdminBtn,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFF7C3AED),
                                                  fontFamily: 'Manrope',
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFEDE9FE),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: const Text(
                                                'ADMIN',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w800,
                                                  color: Color(0xFF7C3AED),
                                                  fontFamily: 'Manrope',
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 8),

                                    // Button Mock USER
                                    SizedBox(
                                      width: double.infinity,
                                      height: 46,
                                      child: OutlinedButton(
                                        onPressed: busy
                                            ? null
                                            : () => context
                                                  .read<AuthCubit>()
                                                  .mockLogin(
                                                    sub: 'mock-sso-user-id',
                                                    email: 'scholar.user@lab.edu.vn',
                                                    name: context
                                                        .l10n
                                                        .ssoScholarRole,
                                                    role: 'USER',
                                                  ),
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(
                                            color: Color(0xFF0D9488),
                                            width: 1.5,
                                          ),
                                          backgroundColor: const Color(
                                            0xFFF0FDFA,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.person_rounded,
                                              size: 18,
                                              color: Color(0xFF0D9488),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                context.l10n.ssoUserBtn,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFF0D9488),
                                                  fontFamily: 'Manrope',
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFCCFBF1),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: const Text(
                                                'USER',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w800,
                                                  color: Color(0xFF0D9488),
                                                  fontFamily: 'Manrope',
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],

                                  const SizedBox(height: 20),

                                  // Explanatory note
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.paper50,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: AppColors.borderSoft,
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.info_outline_rounded,
                                          size: 15,
                                          color: AppColors.slate600,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            context.l10n.ssoNote,
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              color: AppColors.slate600,
                                              fontFamily: 'Manrope',
                                              height: 1.4,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Security guarantee
                            Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                const Icon(
                                  Icons.verified_user_rounded,
                                  size: 13,
                                  color: AppColors.textSubtle,
                                ),
                                Text(
                                  context.l10n.securityStandard,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.textSubtle,
                                    fontFamily: 'Manrope',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              '© 2026 HyperDataLab • All rights reserved.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textSubtle,
                                fontFamily: 'Manrope',
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
