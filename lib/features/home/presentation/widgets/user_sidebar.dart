import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../../core/localization/app_localizations.dart';

class UserSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onDestinationSelected;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;

  const UserSidebar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.isCollapsed,
    required this.onToggleCollapse,
  });

  @override
  Widget build(BuildContext context) {
    const duration = Duration(milliseconds: 240);
    const curve = Cubic(0.16, 1.0, 0.3, 1.0);

    return AnimatedContainer(
      duration: duration,
      curve: curve,
      width: isCollapsed ? 76 : 260,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.sidebarBackground,
        border: Border(right: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBrandHeader(context),
          const Divider(color: Color(0xFFF1F5F9), height: 1),

          // Menu navigation
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
              children: [
                _SidebarNavItem(
                  index: 0,
                  isSelected: selectedIndex == 0,
                  isCollapsed: isCollapsed,
                  icon: Icons.rate_review_outlined,
                  activeIcon: Icons.rate_review_rounded,
                  title: AppLocalizations.of(context).navManuscriptChecker,
                  showIconInExpanded: false,
                  onTap: onDestinationSelected,
                ),
                const SizedBox(height: 3),
                _SidebarNavItem(
                  index: 1,
                  isSelected: selectedIndex == 1,
                  isCollapsed: isCollapsed,
                  icon: Icons.recommend_outlined,
                  activeIcon: Icons.recommend_rounded,
                  title: AppLocalizations.of(context).navJournalRecommendations,
                  showIconInExpanded: false,
                  onTap: onDestinationSelected,
                ),
                const SizedBox(height: 3),
                _SidebarNavItem(
                  index: 2,
                  isSelected: selectedIndex == 2,
                  isCollapsed: isCollapsed,
                  icon: Icons.history_rounded,
                  activeIcon: Icons.history_rounded,
                  title: AppLocalizations.of(context).navEvaluationHistory,
                  showIconInExpanded: false,
                  onTap: onDestinationSelected,
                ),
              ],
            ),
          ),

          const Divider(color: Color(0xFFF1F5F9), height: 1),
          _buildAccountProfile(context),
        ],
      ),
    );
  }

  Widget _buildBrandHeader(BuildContext context) {
    return Container(
      height: 72,
      padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 14 : 16),
      alignment: Alignment.centerLeft,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: isCollapsed
            ? Center(
                key: const ValueKey('brand_collapsed'),
                child: Tooltip(
                  message: AppLocalizations.of(context).expandSidebar,
                  child: InkWell(
                    onTap: onToggleCollapse,
                    borderRadius: BorderRadius.circular(8),
                    hoverColor: const Color(0xFFF0F7FC),
                    focusColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    splashColor: const Color(0xFF0071BC)
                        .withValues(alpha: 0.08),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/images/app_logo.png',
                        width: 38,
                        height: 38,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              )
            : Row(
                key: const ValueKey('brand_expanded'),
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/images/app_logo.png',
                      width: 38,
                      height: 38,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'HyperData Lab',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            fontFamily: 'Manrope',
                            letterSpacing: -0.2,
                            height: 1.15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Academic Portal',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0071BC),
                            fontFamily: 'Manrope',
                            letterSpacing: 0.4,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Tooltip(
                    message: AppLocalizations.of(context).collapseSidebar,
                    child: InkWell(
                      onTap: onToggleCollapse,
                      borderRadius: BorderRadius.circular(8),
                      hoverColor: const Color(0xFFF0F7FC),
                      focusColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      splashColor: const Color(0xFF0071BC)
                          .withValues(alpha: 0.08),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(
                          Icons.menu_open_rounded,
                          size: 20,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'U';
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  Widget _buildAccountProfile(BuildContext context) {
    AuthUser? user;
    try {
      final state = context.watch<AuthCubit>().state;
      if (state is AuthAuthenticated) {
        user = state.user;
      }
    } catch (_) {}

    final displayName = (user?.name != null && user!.name!.trim().isNotEmpty)
        ? user.name!
        : (user?.email?.split('@').first ?? AppLocalizations.of(context).user);
    final email = user?.email ?? 'scholar.user@lab.edu.vn';
    final role = (user?.role ?? 'USER').toUpperCase();
    final initials = _getInitials(displayName);
    final bool isAdminRole = role == 'ADMIN';

    Color badgeBg = const Color(0xFFF0FDFA);
    Color badgeText = const Color(0xFF0D9488);
    Color badgeBorder = const Color(0xFF99F6E4);

    if (isAdminRole) {
      badgeBg = const Color(0xFFFEE2E2);
      badgeText = const Color(0xFFDC2626);
      badgeBorder = const Color(0xFFFECACA);
    } else if (role == 'LECTURER') {
      badgeBg = const Color(0xFFF3E8FF);
      badgeText = const Color(0xFF7E22CE);
      badgeBorder = const Color(0xFFD8B4FE);
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: isCollapsed
          ? Container(
              key: const ValueKey('profile_collapsed'),
              padding: const EdgeInsets.symmetric(vertical: 14),
              alignment: Alignment.center,
              child: PopupMenuButton<String>(
                tooltip: '$displayName ($role)',
                offset: const Offset(56, -10),
                elevation: 8,
                shadowColor: Colors.black.withValues(alpha: 0.18),
                color: AppColors.surface,
                surfaceTintColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                onSelected: (val) =>
                    _handleProfileMenuAction(context, val, isAdminRole),
                itemBuilder: (popupContext) => _buildProfileMenuItems(
                  context: context,
                  displayName: displayName,
                  email: email,
                  role: role,
                  badgeBg: badgeBg,
                  badgeBorder: badgeBorder,
                  badgeText: badgeText,
                  isAdmin: isAdminRole,
                  includeHeader: true,
                ),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFF0071BC),
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            )
          : Container(
              key: const ValueKey('profile_expanded'),
              padding: const EdgeInsets.all(10),
              child: PopupMenuButton<String>(
                tooltip: '',
                offset: const Offset(252, -10),
                elevation: 8,
                shadowColor: Colors.black.withValues(alpha: 0.18),
                color: AppColors.surface,
                surfaceTintColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                onSelected: (val) =>
                    _handleProfileMenuAction(context, val, isAdminRole),
                itemBuilder: (popupContext) => _buildProfileMenuItems(
                  context: context,
                  displayName: displayName,
                  email: email,
                  role: role,
                  badgeBg: badgeBg,
                  badgeBorder: badgeBorder,
                  badgeText: badgeText,
                  isAdmin: isAdminRole,
                  includeHeader: false,
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    hoverColor: const Color(0xFFF0F7FC),
                    focusColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    splashColor: const Color(0xFF0071BC)
                        .withValues(alpha: 0.08),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 17,
                            backgroundColor: const Color(0xFF0071BC),
                            child: Text(
                              initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  displayName,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                    fontFamily: 'Manrope',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 1.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: badgeBg,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: badgeBorder,
                                          width: 0.5,
                                        ),
                                      ),
                                      child: Text(
                                        role,
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: badgeText,
                                          fontFamily: 'Manrope',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Expanded(
                                      child: Text(
                                        email,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF64748B),
                                          fontFamily: 'Manrope',
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.unfold_more_rounded,
                            size: 18,
                            color: Color(0xFF64748B),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  List<PopupMenuEntry<String>> _buildProfileMenuItems({
    required BuildContext context,
    required String displayName,
    required String email,
    required String role,
    required Color badgeBg,
    required Color badgeBorder,
    required Color badgeText,
    required bool isAdmin,
    bool includeHeader = false,
  }) {
    return [
      if (includeHeader) ...[
        PopupMenuItem<String>(
          enabled: false,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                displayName,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Color(0xFF0F172A),
                  fontFamily: 'Manrope',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                email,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                  fontFamily: 'Manrope',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: badgeBorder, width: 0.5),
                ),
                child: Text(
                  role,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: badgeText,
                    fontFamily: 'Manrope',
                  ),
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
      ],
      PopupMenuItem<String>(
        value: 'info',
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
          child: Row(
            children: [
              const Icon(
                Icons.person_outline_rounded,
                size: 16,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 10),
              Text(
                AppLocalizations.of(context).accountProfile,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                  fontFamily: 'Manrope',
                ),
              ),
            ],
          ),
        ),
      ),
      if (isAdmin)
        PopupMenuItem<String>(
          value: 'admin',
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                const Icon(
                  Icons.admin_panel_settings_outlined,
                  size: 16,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 10),
                Text(
                  AppLocalizations.of(context).adminManagement,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                    fontFamily: 'Manrope',
                  ),
                ),
              ],
            ),
          ),
        ),
      const PopupMenuDivider(height: 8),
      PopupMenuItem<String>(
        value: 'logout',
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF1F2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFFECDD3), width: 0.8),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.logout_rounded,
                size: 16,
                color: Color(0xFFDC2626),
              ),
              const SizedBox(width: 10),
              Text(
                AppLocalizations.of(context).signOut,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFDC2626),
                  fontFamily: 'Manrope',
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  void _handleProfileMenuAction(
    BuildContext context,
    String action,
    bool isAdmin,
  ) {
    switch (action) {
      case 'info':
        Navigator.of(context).pushNamed('/user-info');
        break;
      case 'admin':
        Navigator.of(context).pushReplacementNamed('/admin');
        break;
      case 'logout':
        try {
          context.read<AuthCubit>().logout();
        } catch (_) {}
        break;
    }
  }
}

class _SidebarNavItem extends StatefulWidget {
  final int index;
  final bool isSelected;
  final bool isCollapsed;
  final IconData icon;
  final IconData activeIcon;
  final String title;
  final bool showIconInExpanded;
  final ValueChanged<int> onTap;

  const _SidebarNavItem({
    required this.index,
    required this.isSelected,
    required this.isCollapsed,
    required this.icon,
    required this.activeIcon,
    required this.title,
    this.showIconInExpanded = false,
    required this.onTap,
  });

  @override
  State<_SidebarNavItem> createState() => _SidebarNavItemState();
}

class _SidebarNavItemState extends State<_SidebarNavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bool isSelected = widget.isSelected;
    final bool isCollapsed = widget.isCollapsed;

    // Smooth gradual fade duration: 200ms
    const duration = Duration(milliseconds: 200);
    const curve = Curves.easeInOut;

    // App style palette: refined HyperData Lab Blue system
    const Color hoverBlueBg = Color(0xFFF0F7FC);
    const Color activeBlueBg = Color(0xFFE0F2FE);
    const Color activeHoverBlueBg = Color(0xFFD6EEFD);

    // CRITICAL: NEVER use Colors.transparent (which is 0x00000000 = transparent black)
    // because interpolating 0x00000000 -> LightBlue creates a momentary dark flash!
    // By using hoverBlueBg.withValues(alpha: 0.0), RGB stays constant and only Alpha fades in!
    final Color bgColor = isSelected
        ? (_isHovered ? activeHoverBlueBg : activeBlueBg)
        : (_isHovered ? hoverBlueBg : hoverBlueBg.withValues(alpha: 0.0));

    final Color contentColor = isSelected
        ? const Color(0xFF0071BC)
        : (_isHovered ? const Color(0xFF0071BC) : const Color(0xFF64748B));

    final Color textColor = isSelected
        ? const Color(0xFF0071BC)
        : (_isHovered ? const Color(0xFF0F172A) : const Color(0xFF475569));

    Widget item = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      hitTestBehavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: duration,
        curve: curve,
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: InkWell(
          onTap: () => widget.onTap(widget.index),
          borderRadius: BorderRadius.circular(8),
          hoverColor: Colors.transparent,
          focusColor: Colors.transparent,
          highlightColor: Colors.transparent,
          splashColor: const Color(0xFF0071BC).withValues(alpha: 0.08),
          mouseCursor: SystemMouseCursors.click,
          child: SizedBox(
            height: 42,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 0 : 12),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                child: isCollapsed
                    ? Center(
                        key: const ValueKey('nav_collapsed'),
                        child: TweenAnimationBuilder<Color?>(
                          duration: duration,
                          curve: curve,
                          tween: ColorTween(end: contentColor),
                          builder: (context, color, _) => Icon(
                            isSelected ? widget.activeIcon : widget.icon,
                            color: color,
                            size: 20,
                          ),
                        ),
                      )
                    : Row(
                        key: const ValueKey('nav_expanded'),
                        children: [
                          if (widget.showIconInExpanded) ...[
                            TweenAnimationBuilder<Color?>(
                              duration: duration,
                              curve: curve,
                              tween: ColorTween(end: contentColor),
                              builder: (context, color, _) => Icon(
                                isSelected ? widget.activeIcon : widget.icon,
                                color: color,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            child: AnimatedDefaultTextStyle(
                              duration: duration,
                              curve: curve,
                              style: TextStyle(
                                color: textColor,
                                fontSize: 13.5,
                                fontFamily: 'Manrope',
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w600, // Stable weight to prevent text jitter
                                letterSpacing: -0.1,
                              ),
                              child: Text(
                                widget.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );

    if (isCollapsed) {
      return Tooltip(message: widget.title, preferBelow: false, child: item);
    }
    return item;
  }
}
