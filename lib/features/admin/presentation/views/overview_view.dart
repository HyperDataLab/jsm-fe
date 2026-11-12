import '../../../../core/localization/app_localizations.dart';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../users/data/datasources/users_api_client.dart';
import '../../data/datasources/admin_api_client.dart';

/// Phase 02: Interactive Pipeline Overview Dashboard
/// Serves as the central mission control for JSM Admin, connected to live APIs.
class OverviewView extends StatefulWidget {
  final Function(int) onNavigateToTab;
  final VoidCallback onTriggerNewAnalysis;

  const OverviewView({
    super.key,
    required this.onNavigateToTab,
    required this.onTriggerNewAnalysis,
  });

  @override
  State<OverviewView> createState() => _OverviewViewState();
}

class _OverviewViewState extends State<OverviewView> {
  final AdminApiClient _adminApiClient = AdminApiClient();
  late final UsersApiClient _usersApiClient;

  bool _isLoading = true;
  int _journalsCount = 0;
  int _runningJobsCount = 0;
  int _totalJobsCount = 0;
  int _snapshotsCount = 0;
  int _configsCount = 0;
  int _usersCount = 0;
  bool _backendAlive = true;
  bool _grobidAlive = false;
  int _minioFiles = 0;
  List<Map<String, dynamic>> _recentJobs = [];

  @override
  void initState() {
    super.initState();
    final authRepo = context.read<AuthRepository?>();
    _usersApiClient = UsersApiClient(
      tokenProvider: () async =>
          authRepo != null ? await authRepo.currentToken() : null,
    );
    _loadOverviewData();
  }

  Future<void> _loadOverviewData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _adminApiClient.getOverviewStats(),
        _adminApiClient.getJournals(),
        _adminApiClient.getAnalysisJobs(),
        _adminApiClient.getSnapshots(),
        _usersApiClient.getUsers(),
        _adminApiClient.checkHealth(),
        _adminApiClient.getConfigurations(),
      ]);

      if (!mounted) return;

      final stats = results[0] as Map<String, dynamic>;
      final journals = results[1] as List<Map<String, dynamic>>;
      final jobs = results[2] as List<Map<String, dynamic>>;
      final snapshots = results[3] as List<Map<String, dynamic>>;
      final users = results[4] as List<Map<String, dynamic>>;
      final backendOk = results[5] as bool;
      final configs = results[6] as List<Map<String, dynamic>>;

      final summary = stats['summary'] as Map<String, dynamic>?;
      final isGrobidAlive = summary?['grobid_alive'] == true;
      final rawMinioFiles = summary?['minio_raw_files'] as int? ?? 0;

      int running = 0;
      for (final j in jobs) {
        final st = (j['status'] ?? '').toString().toUpperCase();
        if (st == 'RUNNING' || st == 'PENDING') running++;
      }

      setState(() {
        _journalsCount = journals.length;
        _totalJobsCount = jobs.length;
        _runningJobsCount = running;
        _snapshotsCount = snapshots.length;
        _configsCount = configs.length;
        _usersCount = users.length;
        _backendAlive = backendOk;
        _grobidAlive = isGrobidAlive;
        _minioFiles = rawMinioFiles;
        _recentJobs = jobs.take(4).toList();
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroBanner(context),
          const SizedBox(height: 24),
          _buildKpiGrid(),
          const SizedBox(height: 28),
          _buildPipelineFlowSection(),
          const SizedBox(height: 28),
          _buildBottomSection(),
        ],
      ),
    );
  }

  Widget _buildHeroBanner(BuildContext context) {
    final isHealthy = _backendAlive && _grobidAlive;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink900.withAlpha(6),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.blue50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.hub_rounded,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 6),
                          Text(
                            context.l10n.dataMinerCoordination,
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Manrope',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isHealthy
                            ? AppColors.green50
                            : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isHealthy
                                ? Icons.check_circle_outline_rounded
                                : Icons.info_outline_rounded,
                            size: 14,
                            color: isHealthy
                                ? AppColors.green700
                                : const Color(0xFFD97706),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isHealthy
                                ? context.l10n.pipelineReady
                                : context.l10n.systemSyncing,
                            style: TextStyle(
                              color: isHealthy
                                  ? AppColors.green700
                                  : const Color(0xFFD97706),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Manrope',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _loadOverviewData,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      tooltip: context.l10n.refreshMetrics,
                      color: AppColors.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  context.l10n.journalMiningOverview,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFamily: 'Manrope',
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.l10n.pipelineDescription,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textMuted,
                    fontFamily: 'Manrope',
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Column(
            children: [
              ElevatedButton.icon(
                onPressed: widget.onTriggerNewAnalysis,
                icon: const Icon(Icons.bolt_rounded, size: 18),
                label: Text(context.l10n.startNewAnalysis),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => widget.onNavigateToTab(1),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(context.l10n.registerNewJournal),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKpiGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double itemWidth = (constraints.maxWidth - (3 * 16)) / 4;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildKpiCard(
              width: itemWidth.clamp(220, 400),
              title: context.l10n.trackedJournals,
              value: _isLoading ? '...' : '$_journalsCount',
              delta: context.l10n.savedInDatabase,
              deltaPositive: true,
              icon: Icons.menu_book_rounded,
              iconColor: AppColors.primary,
              iconBgColor: AppColors.blue50,
              onTap: () => widget.onNavigateToTab(1),
            ),
            _buildKpiCard(
              width: itemWidth.clamp(220, 400),
              title: context.l10n.jobsRunningTotal,
              value: _isLoading
                  ? '...'
                  : '$_runningJobsCount / $_totalJobsCount',
              delta: _grobidAlive
                  ? 'Grobid & Pipeline active'
                  : 'Grobid Standby',
              deltaPositive: _grobidAlive,
              icon: Icons.monitor_heart_rounded,
              iconColor: const Color(0xFFD97706),
              iconBgColor: const Color(0xFFFEF3C7),
              onTap: () => widget.onNavigateToTab(3),
            ),
            _buildKpiCard(
              width: itemWidth.clamp(220, 400),
              title: 'Kho Corpus Snapshots',
              value: _isLoading ? '...' : '$_snapshotsCount',
              delta: context.l10n.frozenDatasets,
              deltaPositive: true,
              icon: Icons.layers_rounded,
              iconColor: const Color(0xFF7C3AED),
              iconBgColor: const Color(0xFFF3E8FF),
              onTap: () => widget.onNavigateToTab(4),
            ),
            _buildKpiCard(
              width: itemWidth.clamp(220, 400),
              title: context.l10n.userAccounts,
              value: _isLoading ? '...' : '$_usersCount',
              delta: context.l10n.lecturersAndStudents,
              deltaPositive: true,
              icon: Icons.people_alt_rounded,
              iconColor: const Color(0xFF0D9488),
              iconBgColor: const Color(0xFFCCFBF1),
              onTap: () => widget.onNavigateToTab(7),
            ),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard({
    required double width,
    required String title,
    required String value,
    required String delta,
    required bool deltaPositive,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(20),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                fontFamily: 'Manrope',
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  deltaPositive
                      ? Icons.check_circle_outline_rounded
                      : Icons.info_outline_rounded,
                  size: 13,
                  color: deltaPositive
                      ? AppColors.green700
                      : AppColors.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  delta,
                  style: TextStyle(
                    fontSize: 11,
                    color: deltaPositive
                        ? AppColors.green700
                        : AppColors.textMuted,
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPipelineFlowSection() {
    final stages = [
      _PipelineStageData(
        number: 1,
        title: context.l10n.categoryAndConfig,
        subtitle: context.l10n.journalsAndConfigsCount(
          _journalsCount,
          _configsCount,
        ),
        status: context.l10n.systemReady,
        icon: Icons.tune_rounded,
        targetTab: 1,
      ),
      _PipelineStageData(
        number: 2,
        title: 'Grobid TEI Parse',
        subtitle: context.l10n.runningJobsCountLabel(_runningJobsCount),
        status: _runningJobsCount > 0
            ? context.l10n.running
            : context.l10n.systemReady,
        icon: Icons.monitor_heart_rounded,
        targetTab: 3,
      ),
      _PipelineStageData(
        number: 3,
        title: 'Freeze Snapshot',
        subtitle: context.l10n.snapshotsCountLabel(_snapshotsCount),
        status: context.l10n.secured,
        icon: Icons.layers_rounded,
        targetTab: 4,
      ),
      _PipelineStageData(
        number: 4,
        title: context.l10n.styleProfiles,
        subtitle: 'Stance, CARS, Hedges',
        status: context.l10n.systemReady,
        icon: Icons.psychology_outlined,
        targetTab: 5,
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.dataPipelineFlow,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontFamily: 'Manrope',
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    context.l10n.clickPhaseToNavigate,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                      fontFamily: 'Manrope',
                    ),
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: () => widget.onNavigateToTab(3),
                icon: const Icon(Icons.play_circle_outline_rounded, size: 16),
                label: Text(context.l10n.viewJobDetails),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              for (int i = 0; i < stages.length; i++) ...[
                Expanded(child: _buildStageCard(stages[i])),
                if (i < stages.length - 1)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: AppColors.slate300,
                    ),
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStageCard(_PipelineStageData stage) {
    return InkWell(
      onTap: () => widget.onNavigateToTab(stage.targetTab),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${stage.number}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontFamily: 'Manrope',
                      ),
                    ),
                  ),
                ),
                Icon(stage.icon, size: 16, color: AppColors.primary),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              stage.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontFamily: 'Manrope',
              ),
            ),
            const SizedBox(height: 2),
            Text(
              stage.subtitle,
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
    );
  }

  Widget _buildBottomSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column: Recent Jobs Table (Flex 3)
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.l10n.recentMiningJobs,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontFamily: 'Manrope',
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => widget.onNavigateToTab(3),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                      label: Text(context.l10n.viewAll),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_recentJobs.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        context.l10n.noRecentJobs,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontFamily: 'Manrope',
                        ),
                      ),
                    ),
                  )
                else
                  for (int i = 0; i < _recentJobs.length; i++) ...[
                    _buildRecentJobItem(_recentJobs[i]),
                    if (i < _recentJobs.length - 1)
                      const Divider(height: 20, color: AppColors.borderSoft),
                  ],
              ],
            ),
          ),
        ),
        const SizedBox(width: 20),

        // Right Column: System Services Health (Flex 2)
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.systemServiceStatus,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFamily: 'Manrope',
                  ),
                ),
                const SizedBox(height: 16),
                _buildHealthItem(
                  name: 'FastAPI Backend Core',
                  endpoint: 'http://127.0.0.1:8000/api/v1',
                  isOk: _backendAlive,
                ),
                const SizedBox(height: 12),
                _buildHealthItem(
                  name: 'Grobid PDF Parser',
                  endpoint: 'Jetty 11 (Port 8070 / REST)',
                  isOk: _grobidAlive,
                ),
                const SizedBox(height: 12),
                _buildHealthItem(
                  name: 'PostgreSQL Database',
                  endpoint: 'Port 5432 (jsm_database)',
                  isOk: _backendAlive,
                ),
                const SizedBox(height: 12),
                _buildHealthItem(
                  name: 'MinIO Raw Storage',
                  endpoint: 'Port 9000 ($_minioFiles files raw)',
                  isOk: _backendAlive,
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: () => widget.onNavigateToTab(6),
                  icon: const Icon(Icons.settings_outlined, size: 16),
                  label: Text(context.l10n.configSystemParams),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentJobItem(Map<String, dynamic> job) {
    final journal = job['journal'] as Map<String, dynamic>?;
    final title = journal?['title'] ?? context.l10n.miningJournal;
    final issn = journal?['issn_l'] ?? 'N/A';
    final status = (job['status'] ?? 'PENDING').toString();
    final step = (job['current_step'] ?? 'QUEUED').toString();

    double progress = ((job['progress'] as num?)?.toDouble() ?? 0.0);
    if (progress > 1.0) progress = progress / 100.0;
    progress = progress.clamp(0.0, 1.0);

    Color statusColor = AppColors.primary;
    String statusLabel = context.l10n.statusProcessing;
    if (status.toUpperCase() == 'COMPLETED') {
      statusColor = AppColors.green700;
      statusLabel = context.l10n.statusCompleted;
    } else if (status.toUpperCase() == 'PENDING') {
      statusColor = const Color(0xFFD97706);
      statusLabel = context.l10n.statusPending;
    } else if (status.toUpperCase() == 'FAILED') {
      statusColor = AppColors.error;
      statusLabel = context.l10n.statusFailed;
    }

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontFamily: 'Manrope',
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'ISSN: $issn • Step: $step',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  fontFamily: 'Manrope',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              statusLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: statusColor,
                fontFamily: 'Manrope',
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 80,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: AppColors.surfaceSoft,
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHealthItem({
    required String name,
    required String endpoint,
    required bool isOk,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontFamily: 'Manrope',
                ),
              ),
              Text(
                endpoint,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  fontFamily: 'Manrope',
                ),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isOk ? AppColors.green700 : AppColors.error,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                isOk ? 'OK' : 'Error',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isOk ? AppColors.green700 : AppColors.error,
                  fontFamily: 'Manrope',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PipelineStageData {
  final int number;
  final String title;
  final String subtitle;
  final String status;
  final IconData icon;
  final int targetTab;

  const _PipelineStageData({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.icon,
    required this.targetTab,
  });
}
