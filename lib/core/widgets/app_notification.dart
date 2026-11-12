import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../app/theme/app_colors.dart';

enum AppNotificationType { success, error, warning, info }

class AppNotification {
  static final AppNotification _instance = AppNotification._internal();
  factory AppNotification() => _instance;
  AppNotification._internal();

  static OverlayEntry? _overlayEntry;
  static final List<_NotificationItemData> _items = [];
  static final GlobalKey<_NotificationContainerState> _containerKey =
      GlobalKey<_NotificationContainerState>();

  /// Hiển thị thông báo thành công
  static void showSuccess(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onAction,
    IconData? icon,
  }) {
    show(
      context,
      message: message,
      title: title ?? 'Thành công',
      type: AppNotificationType.success,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
      icon: icon,
    );
  }

  /// Hiển thị thông báo lỗi
  static void showError(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 5),
    String? actionLabel,
    VoidCallback? onAction,
    IconData? icon,
  }) {
    show(
      context,
      message: message,
      title: title ?? 'Đã có lỗi xảy ra',
      type: AppNotificationType.error,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
      icon: icon,
    );
  }

  /// Hiển thị thông báo cảnh báo
  static void showWarning(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onAction,
    IconData? icon,
  }) {
    show(
      context,
      message: message,
      title: title ?? 'Cảnh báo',
      type: AppNotificationType.warning,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
      icon: icon,
    );
  }

  /// Hiển thị thông báo thông tin
  static void showInfo(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onAction,
    IconData? icon,
  }) {
    show(
      context,
      message: message,
      title: title ?? 'Thông báo',
      type: AppNotificationType.info,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
      icon: icon,
    );
  }

  /// Hiển thị thông báo chung
  static void show(
    BuildContext context, {
    required String message,
    String? title,
    AppNotificationType type = AppNotificationType.info,
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onAction,
    IconData? icon,
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    final item = _NotificationItemData(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      message: message,
      title: title,
      type: type,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
      icon: icon,
    );

    _items.insert(0, item);
    // Limit visible notifications to 5
    if (_items.length > 5) {
      _items.removeLast();
    }

    if (_overlayEntry == null) {
      _overlayEntry = OverlayEntry(
        builder: (context) => _NotificationContainer(
          key: _containerKey,
          items: _items,
          onDismiss: _removeItem,
        ),
      );
      overlay.insert(_overlayEntry!);
    } else {
      _containerKey.currentState?.updateItems(_items);
    }
  }

  static void _removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    if (_items.isEmpty) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    } else {
      _containerKey.currentState?.updateItems(_items);
    }
  }

  /// Xóa toàn bộ thông báo đang hiện
  static void clear() {
    _items.clear();
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}

class _NotificationItemData {
  final String id;
  final String message;
  final String? title;
  final AppNotificationType type;
  final Duration duration;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? icon;

  _NotificationItemData({
    required this.id,
    required this.message,
    this.title,
    required this.type,
    required this.duration,
    this.actionLabel,
    this.onAction,
    this.icon,
  });
}

class _NotificationContainer extends StatefulWidget {
  final List<_NotificationItemData> items;
  final Function(String id) onDismiss;

  const _NotificationContainer({
    super.key,
    required this.items,
    required this.onDismiss,
  });

  @override
  State<_NotificationContainer> createState() => _NotificationContainerState();
}

class _NotificationContainerState extends State<_NotificationContainer> {
  late List<_NotificationItemData> _currentItems;

  @override
  void initState() {
    super.initState();
    _currentItems = List.from(widget.items);
  }

  void updateItems(List<_NotificationItemData> items) {
    if (mounted) {
      setState(() {
        _currentItems = List.from(items);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isMobile = mediaQuery.size.width < 500;
    final width = isMobile ? mediaQuery.size.width - 32 : 390.0;

    return Positioned(
      top: mediaQuery.padding.top + 16,
      right: isMobile ? 16 : 24,
      width: width,
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: _currentItems.map((item) {
            return Padding(
              key: ValueKey(item.id),
              padding: const EdgeInsets.only(bottom: 10),
              child: _NotificationCard(
                data: item,
                onDismiss: () => widget.onDismiss(item.id),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatefulWidget {
  final _NotificationItemData data;
  final VoidCallback onDismiss;

  const _NotificationCard({required this.data, required this.onDismiss});

  @override
  State<_NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<_NotificationCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  Timer? _dismissTimer;
  DateTime? _timerStartTime;
  Duration _remainingDuration = Duration.zero;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _remainingDuration = widget.data.duration;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );

    _slideAnim = Tween<Offset>(begin: const Offset(1.15, 0), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );

    _animController.forward();
    _startTimer();
  }

  void _startTimer() {
    _timerStartTime = DateTime.now();
    _dismissTimer?.cancel();
    _dismissTimer = Timer(_remainingDuration, _closeNotification);
  }

  void _pauseTimer() {
    if (_timerStartTime != null) {
      final elapsed = DateTime.now().difference(_timerStartTime!);
      _remainingDuration = _remainingDuration - elapsed;
      if (_remainingDuration.isNegative) {
        _remainingDuration = Duration.zero;
      }
    }
    _dismissTimer?.cancel();
  }

  void _resumeTimer() {
    if (_remainingDuration > Duration.zero) {
      _startTimer();
    } else {
      _closeNotification();
    }
  }

  void _closeNotification() async {
    if (!mounted) return;
    _dismissTimer?.cancel();
    await _animController.reverse();
    if (mounted) {
      widget.onDismiss();
    }
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  Color get _accentColor {
    switch (widget.data.type) {
      case AppNotificationType.success:
        return const Color(0xFF10B981);
      case AppNotificationType.error:
        return const Color(0xFFEF4444);
      case AppNotificationType.warning:
        return const Color(0xFFF59E0B);
      case AppNotificationType.info:
        return AppColors.blue600;
    }
  }

  Color get _accentBgColor {
    switch (widget.data.type) {
      case AppNotificationType.success:
        return const Color(0xFFECFDF5);
      case AppNotificationType.error:
        return const Color(0xFFFEF2F2);
      case AppNotificationType.warning:
        return const Color(0xFFFFFBEB);
      case AppNotificationType.info:
        return const Color(0xFFEFF6FF);
    }
  }

  Color get _accentBorderColor {
    switch (widget.data.type) {
      case AppNotificationType.success:
        return const Color(0xFFA7F3D0);
      case AppNotificationType.error:
        return const Color(0xFFFECACA);
      case AppNotificationType.warning:
        return const Color(0xFFFDE68A);
      case AppNotificationType.info:
        return const Color(0xFFBFDBFE);
    }
  }

  IconData get _defaultIcon {
    switch (widget.data.type) {
      case AppNotificationType.success:
        return Icons.check_circle_rounded;
      case AppNotificationType.error:
        return Icons.error_rounded;
      case AppNotificationType.warning:
        return Icons.warning_amber_rounded;
      case AppNotificationType.info:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconData = widget.data.icon ?? _defaultIcon;

    return SlideTransition(
      position: _slideAnim,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: MouseRegion(
          onEnter: (_) {
            setState(() => _isHovered = true);
            _pauseTimer();
          },
          onExit: (_) {
            setState(() => _isHovered = false);
            _resumeTimer();
          },
          child: Dismissible(
            key: ValueKey(widget.data.id),
            direction: DismissDirection.endToStart,
            onDismissed: (_) => widget.onDismiss(),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _accentBorderColor.withValues(alpha: 0.9),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: _accentColor.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  // Main Notification Content
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon Box
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _accentBgColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(iconData, color: _accentColor, size: 20),
                        ),
                        const SizedBox(width: 12),

                        // Text Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.data.title != null &&
                                  widget.data.title!.isNotEmpty) ...[
                                Text(
                                  widget.data.title!,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.ink900,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                              ],
                              Text(
                                widget.data.message,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: widget.data.title == null
                                      ? FontWeight.w500
                                      : FontWeight.w400,
                                  color: widget.data.title == null
                                      ? AppColors.ink900
                                      : AppColors.slate600,
                                  height: 1.35,
                                ),
                              ),
                              if (widget.data.actionLabel != null &&
                                  widget.data.onAction != null) ...[
                                const SizedBox(height: 6),
                                InkWell(
                                  onTap: () {
                                    widget.data.onAction?.call();
                                    _closeNotification();
                                  },
                                  borderRadius: BorderRadius.circular(4),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 2,
                                      horizontal: 4,
                                    ),
                                    child: Text(
                                      widget.data.actionLabel!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: _accentColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Close Button
                        InkWell(
                          onTap: _closeNotification,
                          borderRadius: BorderRadius.circular(16),
                          hoverColor: AppColors.slate100,
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: AppColors.slate400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bottom Auto-Dismiss Progress Indicator
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _NotificationProgressBar(
                      duration: widget.data.duration,
                      color: _accentColor,
                      isPaused: _isHovered,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationProgressBar extends StatefulWidget {
  final Duration duration;
  final Color color;
  final bool isPaused;

  const _NotificationProgressBar({
    required this.duration,
    required this.color,
    required this.isPaused,
  });

  @override
  State<_NotificationProgressBar> createState() =>
      _NotificationProgressBarState();
}

class _NotificationProgressBarState extends State<_NotificationProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _progressController.forward();
  }

  @override
  void didUpdateWidget(covariant _NotificationProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPaused != oldWidget.isPaused) {
      if (widget.isPaused) {
        _progressController.stop();
      } else {
        _progressController.forward();
      }
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progressController,
      builder: (context, child) {
        return FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: (1.0 - _progressController.value).clamp(0.0, 1.0),
          child: Container(
            height: 2.5,
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: 0.75),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
              ),
            ),
          ),
        );
      },
    );
  }
}
