import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_notification.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/datasources/admin_api_client.dart';

class JobMonitorView extends StatefulWidget {
  final Function(int) onNavigateToTab;
  final VoidCallback? onTriggerNewAnalysis;

  const JobMonitorView({
    super.key,
    required this.onNavigateToTab,
    this.onTriggerNewAnalysis,
  });

  @override
  State<JobMonitorView> createState() => _JobMonitorViewState();
}

class _JobMonitorViewState extends State<JobMonitorView> {
  final AdminApiClient _apiClient = AdminApiClient();
  String _selectedFilter = 'ALL';
  List<Map<String, dynamic>> _jobs = [];
  bool _isLoading = true;
  String? _error;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadJobs();
    // Auto-refresh every 8 seconds for live progress tracking
    _refreshTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (mounted) _loadJobs(silent: true);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadJobs({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final list = await _apiClient.getAnalysisJobs();
      if (!mounted) return;
      setState(() {
        _jobs = list;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (!silent) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _retryJob(String jobId) async {
    try {
      final retried = await _apiClient.retryFailedArticles(jobId);
      if (mounted) {
        AppNotification.showSuccess(
          context,
          context.l10n.retriedArticles(retried),
          title: context.l10n.retrySuccess,
        );
        _loadJobs();
      }
    } catch (e) {
      if (mounted) {
        AppNotification.showError(
          context,
          'Lỗi: $e',
          title: context.l10n.retryFailed,
        );
      }
    }
  }

  String _mapStatusText(BuildContext context, String status) {
    switch (status.toUpperCase()) {
      case 'RUNNING':
        return context.l10n.statusRunning;
      case 'COMPLETED':
        return context.l10n.statusCompleted;
      case 'PENDING':
        return context.l10n.statusPending;
      case 'FAILED':
        return context.l10n.statusFailed;
      case 'CANCELLED':
        return context.l10n.statusCancelled;
      default:
        return status;
    }
  }

  Color _mapStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'RUNNING':
        return AppColors.primary;
      case 'COMPLETED':
        return AppColors.green700;
      case 'PENDING':
        return const Color(0xFFD97706);
      case 'FAILED':
        return AppColors.error;
      case 'CANCELLED':
        return AppColors.textMuted;
      default:
        return AppColors.textSecondary;
    }
  }

  Future<void> _confirmCancelJob(String jobId, String journalTitle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          context.l10n.confirmCancelTitle,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontFamily: 'Manrope',
          ),
        ),
        content: Text(
          context.l10n.confirmCancelDesc(journalTitle),
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            fontFamily: 'Manrope',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              context.l10n.dismiss,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontFamily: 'Manrope',
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              context.l10n.stopTask,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _apiClient.cancelJob(jobId);
      if (!mounted) return;
      if (success) {
        AppNotification.showSuccess(
          context,
          context.l10n.jobCancelledSuccess,
          title: context.l10n.jobCancelledTitle,
        );
        _loadJobs();
      } else {
        AppNotification.showError(
          context,
          context.l10n.jobCancelFailed,
          title: context.l10n.jobCancelFailedTitle,
        );
      }
    }
  }

  Future<void> _confirmDeleteJob(String jobId, String journalTitle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          context.l10n.deleteJob,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontFamily: 'Manrope',
          ),
        ),
        content: Text(
          context.l10n.confirmCancelDesc(journalTitle),
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            fontFamily: 'Manrope',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              context.l10n.dismiss,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontFamily: 'Manrope',
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              context.l10n.deleteJob,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _apiClient.deleteJob(jobId);
      if (!mounted) return;
      if (success) {
        AppNotification.showSuccess(
          context,
          context.l10n.jobDeletedSuccess,
          title: context.l10n.jobDeletedTitle,
        );
        _loadJobs();
      } else {
        AppNotification.showError(
          context,
          context.l10n.jobDeleteFailed,
          title: context.l10n.jobDeleteFailedTitle,
        );
      }
    }
  }

  int _currentStageNumber(String step, String status) {
    if (status.toUpperCase() == 'COMPLETED') return 6;
    final s = step.toUpperCase();
    if (s.contains('QUEUED') ||
        s.contains('PENDING') ||
        s.contains('HARVEST')) {
      return 1;
    }
    if (s.contains('FETCH')) return 2;
    if (s.contains('GROBID') || s.contains('PARS')) return 3;
    if (s.contains('NORM')) return 4;
    if (s.contains('NLP') || s.contains('MOVE') || s.contains('STANCE')) {
      return 5;
    }
    return 6;
  }

  String _stageDescription(
    BuildContext context,
    int stageNum,
    String step,
    String status,
  ) {
    if (status.toUpperCase() == 'COMPLETED') {
      return context.l10n.stageCompleted;
    }
    if (status.toUpperCase() == 'CANCELLED') {
      return context.l10n.stageCancelled;
    }
    switch (stageNum) {
      case 1:
        return context.l10n.stage1;
      case 2:
        return context.l10n.stage2;
      case 3:
        return context.l10n.stage3;
      case 4:
        return context.l10n.stage4;
      case 5:
        return context.l10n.stage5;
      case 6:
      default:
        return context.l10n.stage6;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredJobs = _jobs.where((job) {
      if (_selectedFilter == 'ALL') return true;
      final st = (job['status'] ?? '').toString().toUpperCase();
      return st == _selectedFilter;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.jobMonitorTitle,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontFamily: 'Manrope',
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.l10n.jobMonitorSubtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textMuted,
                        fontFamily: 'Manrope',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () => _loadJobs(),
                icon: const Icon(Icons.refresh_rounded),
                tooltip: context.l10n.reloadJobs,
                color: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Filters Toolbar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildFilterTab('ALL', context.l10n.filterAll),
                const SizedBox(width: 8),
                _buildFilterTab('RUNNING', context.l10n.statusRunning),
                const SizedBox(width: 8),
                _buildFilterTab('PENDING', context.l10n.statusPending),
                const SizedBox(width: 8),
                _buildFilterTab('COMPLETED', context.l10n.statusCompleted),
                const SizedBox(width: 8),
                _buildFilterTab('FAILED', context.l10n.statusFailed),
                const SizedBox(width: 8),
                _buildFilterTab('CANCELLED', context.l10n.statusCancelled),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Job Cards List
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(64),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.error,
                      size: 36,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontFamily: 'Manrope',
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => _loadJobs(),
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: Text(context.l10n.retry),
                    ),
                  ],
                ),
              ),
            )
          else if (filteredJobs.isEmpty)
            Padding(
              padding: const EdgeInsets.all(48),
              child: Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.monitor_heart_outlined,
                      size: 48,
                      color: AppColors.slate300,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.l10n.noJobsFound,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontFamily: 'Manrope',
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: [
                for (int i = 0; i < filteredJobs.length; i++) ...[
                  _buildJobCard(filteredJobs[i]),
                  if (i < filteredJobs.length - 1) const SizedBox(height: 16),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String code, String label) {
    final isSelected = _selectedFilter == code;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = code),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontFamily: 'Manrope',
          ),
        ),
      ),
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job) {
    final journal = job['journal'] as Map<String, dynamic>?;
    final journalTitle = journal?['title'] ?? context.l10n.miningJournal;
    final issn = journal?['issn_l'] ?? 'N/A';
    final status = (job['status'] ?? 'PENDING').toString();
    final step = (job['current_step'] ?? 'QUEUED').toString();
    final stageNum = _currentStageNumber(step, status);
    final stageText = _stageDescription(context, stageNum, step, status);

    double progress = ((job['progress'] as num?)?.toDouble() ?? 0.0);
    if (progress > 1.0) progress = progress / 100.0;
    progress = progress.clamp(0.0, 1.0);

    final statusText = _mapStatusText(context, status);
    final statusColor = _mapStatusColor(status);
    final jobId = job['id'].toString();

    final metrics = job['metrics'] as Map<String, dynamic>?;
    final totalArticles = (metrics?['total_articles'] as num?)?.toInt() ?? 0;
    final fetched = (metrics?['fetched'] as num?)?.toInt() ?? 0;
    final parsed = (metrics?['parsed'] as num?)?.toInt() ?? 0;
    final normalized = (metrics?['normalized'] as num?)?.toInt() ?? 0;
    final failed = (metrics?['failed'] as num?)?.toInt() ?? 0;
    final isDone = status.toUpperCase() == 'COMPLETED';

    final successCount = isDone
        ? totalArticles
        : (normalized > 0 ? normalized : (parsed > 0 ? parsed : fetched));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink900.withAlpha(4),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, cardConstraints) {
              final isNarrowCard = cardConstraints.maxWidth < 700;

              final titleCol = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        journalTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          fontFamily: 'Manrope',
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSoft,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'ISSN: $issn',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontFamily: 'Manrope',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${context.l10n.jobIdLabel}: $jobId',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      fontFamily: 'Manrope',
                    ),
                  ),
                ],
              );

              final actionsWrap = Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    height: 26,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(24),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                            fontFamily: 'Manrope',
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (failed > 0 || status == 'FAILED')
                    SizedBox(
                      height: 26,
                      child: ElevatedButton.icon(
                        onPressed: () => _retryJob(jobId),
                        icon: const Icon(Icons.refresh_rounded, size: 14),
                        label: Text(
                          failed > 0
                              ? context.l10n.retryFailedArticles(failed)
                              : context.l10n.retry,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  if (status == 'RUNNING' || status == 'PENDING')
                    SizedBox(
                      height: 26,
                      child: OutlinedButton.icon(
                        onPressed: () => _confirmCancelJob(jobId, journalTitle),
                        icon: const Icon(
                          Icons.stop_circle_outlined,
                          size: 14,
                          color: AppColors.error,
                        ),
                        label: Text(
                          context.l10n.cancelJob,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.error,
                            fontFamily: 'Manrope',
                            height: 1.1,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: AppColors.error.withAlpha(120),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  SizedBox(
                    height: 26,
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmDeleteJob(jobId, journalTitle),
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        size: 14,
                        color: AppColors.error,
                      ),
                      label: Text(
                        context.l10n.deleteJob,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.error,
                          fontFamily: 'Manrope',
                          height: 1.1,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.error.withAlpha(120)),
                        backgroundColor: AppColors.error.withAlpha(
                          10,
                        ), // Subtle red tint
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              );

              if (isNarrowCard) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [titleCol, const SizedBox(height: 12), actionsWrap],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: titleCol),
                  const SizedBox(width: 14),
                  actionsWrap,
                ],
              );
            },
          ),
          const SizedBox(height: 18),

          // Progress Bar with Article Count
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  stageText,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontFamily: 'Manrope',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      fontFamily: 'Manrope',
                    ),
                  ),
                  if (totalArticles > 0) ...[
                    const SizedBox(width: 8),
                    Text(
                      '•  $successCount/$totalArticles ${context.l10n.papers}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontFamily: 'Manrope',
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.surfaceSoft,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          const SizedBox(height: 14),

          // Real-time Article State Tracking Strip
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border.withAlpha(120)),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                Wrap(
                  spacing: 14,
                  runSpacing: 6,
                  children: [
                    _buildMetricBadge(
                      icon: Icons.article_outlined,
                      label: context.l10n.totalTarget,
                      value: '$totalArticles',
                    ),
                    _buildMetricBadge(
                      icon: Icons.download_done_rounded,
                      label: context.l10n.downloadedPdf,
                      value: '$fetched',
                    ),
                    _buildMetricBadge(
                      icon: Icons.integration_instructions_outlined,
                      label: context.l10n.parsedTeiXml,
                      value: '$parsed',
                    ),
                    _buildMetricBadge(
                      icon: Icons.verified_outlined,
                      label: context.l10n.normalizedDb,
                      value: '$normalized',
                    ),
                    if (failed > 0)
                      _buildMetricBadge(
                        icon: Icons.warning_amber_rounded,
                        label: context.l10n.failedArticles,
                        value: '$failed',
                        color: AppColors.error,
                      ),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: () => _showJobArticlesDialog(
                    context,
                    jobId,
                    journalTitle,
                    metrics,
                    status: status,
                  ),
                  icon: const Icon(
                    Icons.format_list_bulleted_rounded,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  label: Text(
                    context.l10n.articleDetails,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontFamily: 'Manrope',
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBadge({
    required IconData icon,
    required String label,
    required String value,
    Color? color,
  }) {
    final finalColor = color ?? AppColors.textPrimary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.textPrimary),
        const SizedBox(width: 5),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontFamily: 'Manrope',
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: finalColor,
            fontFamily: 'Manrope',
          ),
        ),
      ],
    );
  }

  void _showJobArticlesDialog(
    BuildContext context,
    String jobId,
    String journalTitle,
    Map<String, dynamic>? metrics, {
    String status = '',
  }) {
    showDialog(
      context: context,
      builder: (ctx) {
        String filter = 'ALL';
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              titlePadding: const EdgeInsets.fromLTRB(24, 20, 16, 12),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 8,
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.articleDetailsFor(journalTitle),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            fontFamily: 'Manrope',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.l10n.jobMetricsSummary(
                            jobId,
                            (metrics?['total_articles'] as num?)?.toInt() ?? 0,
                          ),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                            fontFamily: 'Manrope',
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(Icons.close_rounded, size: 20),
                    color: AppColors.textMuted,
                  ),
                ],
              ),
              content: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 700,
                  maxHeight: MediaQuery.of(context).size.height * 0.75,
                ),
                child: SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _buildDialogFilterChip(
                              context.l10n.filterAll,
                              'ALL',
                              filter,
                              (val) => setDialogState(() => filter = val),
                            ),
                            const SizedBox(width: 8),
                            _buildDialogFilterChip(
                              context.l10n.filterNormalizedTEI,
                              'NORMALIZED',
                              filter,
                              (val) => setDialogState(() => filter = val),
                            ),
                            const SizedBox(width: 8),
                            _buildDialogFilterChip(
                              context.l10n.filterFetchedPDF,
                              'FETCHED',
                              filter,
                              (val) => setDialogState(() => filter = val),
                            ),
                            const SizedBox(width: 8),
                            _buildDialogFilterChip(
                              context.l10n.filterError,
                              'FAILED',
                              filter,
                              (val) => setDialogState(() => filter = val),
                              isError: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: FutureBuilder<List<Map<String, dynamic>>>(
                          future: _apiClient.getJobArticles(
                            jobId,
                            perPage: 100,
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            if (snapshot.hasError) {
                              return Center(
                                child: Text(
                                  context.l10n.errorLoadingArticles +
                                      snapshot.error.toString(),
                                  style: const TextStyle(
                                    color: AppColors.error,
                                    fontFamily: 'Manrope',
                                  ),
                                ),
                              );
                            }
                            final allArticles = snapshot.data ?? [];
                            final filtered = allArticles.where((a) {
                              if (filter == 'ALL') return true;
                              return (a['status'] ?? '')
                                      .toString()
                                      .toUpperCase() ==
                                  filter;
                            }).toList();

                            if (filtered.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.inbox_outlined,
                                      size: 40,
                                      color: AppColors.slate300,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      allArticles.isEmpty
                                          ? context.l10n.noArticlesInJob
                                          : context.l10n.noArticlesWithStatus,
                                      style: const TextStyle(
                                        color: AppColors.textMuted,
                                        fontFamily: 'Manrope',
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (ctx, i) => const Divider(
                                height: 1,
                                color: AppColors.border,
                              ),
                              itemBuilder: (context, index) {
                                final art = filtered[index];
                                final artStatus = (art['status'] ?? '')
                                    .toString()
                                    .toUpperCase();
                                final artTitle =
                                    (art['title'] ??
                                            context.l10n.untitledArticle)
                                        .toString();
                                final doi = (art['doi'] ?? 'N/A').toString();
                                final year = art['year']?.toString() ?? 'N/A';
                                final errorMsg = art['error_message']
                                    ?.toString();

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                    horizontal: 4,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildArticleStatusIcon(artStatus),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              artTitle,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textPrimary,
                                                fontFamily: 'Manrope',
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Text(
                                                  'DOI: $doi',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: AppColors.textMuted,
                                                    fontFamily: 'Manrope',
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Text(
                                                  context.l10n.yearLabel +
                                                      year.toString(),
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: AppColors.textMuted,
                                                    fontFamily: 'Manrope',
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (errorMsg != null &&
                                                errorMsg.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                'Lỗi: $errorMsg',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: AppColors.error,
                                                  fontFamily: 'Manrope',
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      _buildArticleStatusBadge(artStatus),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                if (((metrics?['failed'] as num?)?.toInt() ?? 0) > 0)
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _retryJob(jobId);
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 14),
                    label: Text(
                      context.l10n.retryFailedArticlesBtn(
                        (metrics?['failed'] as num?)?.toInt() ?? 0,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _confirmDeleteJob(jobId, journalTitle);
                  },
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 14,
                    color: AppColors.error,
                  ),
                  label: const Text(
                    'Xóa tác vụ',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      color: AppColors.error,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.error.withAlpha(120)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(
                    context.l10n.close,
                    style: const TextStyle(fontFamily: 'Manrope'),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDialogFilterChip(
    String label,
    String value,
    String current,
    Function(String) onSelect, {
    bool isError = false,
  }) {
    final isSelected = current == value;
    return InkWell(
      onTap: () => onSelect(value),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? (isError ? AppColors.error : AppColors.primary)
              : AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? (isError ? AppColors.error : AppColors.primary)
                : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isError ? AppColors.error : AppColors.textSecondary),
            fontFamily: 'Manrope',
          ),
        ),
      ),
    );
  }

  Widget _buildArticleStatusIcon(String status) {
    switch (status) {
      case 'NORMALIZED':
        return const Icon(
          Icons.check_circle_rounded,
          size: 18,
          color: AppColors.green700,
        );
      case 'PARSED':
        return const Icon(
          Icons.integration_instructions_outlined,
          size: 18,
          color: AppColors.primary,
        );
      case 'FETCHED':
        return const Icon(
          Icons.download_done_rounded,
          size: 18,
          color: Color(0xFF6366F1),
        );
      case 'FAILED':
        return const Icon(
          Icons.error_outline_rounded,
          size: 18,
          color: AppColors.error,
        );
      case 'HARVESTED':
      default:
        return const Icon(
          Icons.schedule_rounded,
          size: 18,
          color: AppColors.textMuted,
        );
    }
  }

  Widget _buildArticleStatusBadge(String status) {
    Color col;
    String txt;
    switch (status) {
      case 'NORMALIZED':
        col = AppColors.green700;
        txt = context.l10n.filterNormalizedTEI;
        break;
      case 'PARSED':
        col = AppColors.primary;
        txt = 'Parse TEI';
        break;
      case 'FETCHED':
        col = const Color(0xFF6366F1);
        txt = context.l10n.filterFetchedPDF;
        break;
      case 'FAILED':
        col = AppColors.error;
        txt = context.l10n.filterError;
        break;
      case 'HARVESTED':
      default:
        col = AppColors.textMuted;
        txt = context.l10n.statusPending;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: col.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        txt,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: col,
          fontFamily: 'Manrope',
        ),
      ),
    );
  }
}
