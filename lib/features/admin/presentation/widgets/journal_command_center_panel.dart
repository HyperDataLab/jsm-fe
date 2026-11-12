import '../../../../core/localization/app_localizations.dart';

import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_notification.dart';
import '../../data/datasources/admin_api_client.dart';

/// Journal All-in-One Command Center Panel
/// Provides 1-touch preset mining execution, real-time 4-stage pipeline stepper,
/// live article metrics, and instant NLP Style Profile visualization.
class JournalCommandCenterPanel extends StatefulWidget {
  final Map<String, dynamic> journal;
  final Map<String, dynamic>? initialConfig;
  final Function(int) onNavigateToTab;
  final VoidCallback onRefreshParent;

  const JournalCommandCenterPanel({
    super.key,
    required this.journal,
    this.initialConfig,
    required this.onNavigateToTab,
    required this.onRefreshParent,
  });

  @override
  State<JournalCommandCenterPanel> createState() =>
      _JournalCommandCenterPanelState();
}

class _JournalCommandCenterPanelState extends State<JournalCommandCenterPanel> {
  final AdminApiClient _apiClient = AdminApiClient();

  bool _isLoading = true;
  bool _isTriggering = false;
  Map<String, dynamic>? _config;
  Map<String, dynamic>? _activeJob;
  Map<String, dynamic>? _jobMetrics;
  Map<String, dynamic>? _styleProfile;
  String? _currentArticleTitle;
  Timer? _pollingTimer;

  // Advanced overrides state
  bool _isAdvancedExpanded = false;
  late int _targetArticles;
  late int _yearFrom;
  late int _yearTo;
  late TextEditingController _domainController;

  @override
  void initState() {
    super.initState();
    _domainController = TextEditingController();
    _initSettings(isInit: true);
    _loadJournalData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_domainController.text.isEmpty) {
      _domainController.text = context.l10n.defaultDomainCs;
    }
  }

  @override
  void didUpdateWidget(covariant JournalCommandCenterPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.journal['id'] != widget.journal['id']) {
      _stopPolling();
      _initSettings(isInit: false);
      _loadJournalData();
    }
  }

  @override
  void dispose() {
    _stopPolling();
    _domainController.dispose();
    super.dispose();
  }

  void _initSettings({bool isInit = false}) {
    _config = widget.initialConfig;
    _targetArticles = _config != null
        ? (_config!['target_articles'] ?? 300)
        : 300;
    _yearFrom = _config != null ? (_config!['year_from'] ?? 2022) : 2022;
    _yearTo = _config != null ? (_config!['year_to'] ?? 2024) : 2024;
    _domainController.text =
        _config?['domain']?.toString() ??
        widget.journal['field']?.toString() ??
        (isInit ? '' : context.l10n.defaultDomainCs);
  }

  void _startPolling() {
    _stopPolling();
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _pollJobStatus(),
    );
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _loadJournalData() async {
    setState(() => _isLoading = true);
    final journalId = widget.journal['id']?.toString() ?? '';
    if (journalId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // 1. Fetch configs if not supplied
      if (_config == null) {
        final configs = await _apiClient.getConfigurations();
        for (final c in configs) {
          final jId =
              c['journal_id']?.toString() ?? c['journal']?['id']?.toString();
          if (jId == journalId) {
            _config = c;
            _targetArticles = c['target_articles'] ?? 300;
            _yearFrom = c['year_from'] ?? 2022;
            _yearTo = c['year_to'] ?? 2024;
            if (c['domain'] != null) {
              _domainController.text = c['domain'].toString();
            }
            break;
          }
        }
      }

      // 2. Fetch latest jobs for this journal
      final jobs = await _apiClient.getAnalysisJobs(journalId: journalId);
      if (jobs.isNotEmpty) {
        _activeJob = jobs.first;
        final jobId = _activeJob!['id']?.toString() ?? '';
        if (jobId.isNotEmpty) {
          _jobMetrics = await _apiClient.getJobMetrics(jobId);
          try {
            final articles = await _apiClient.getJobArticles(
              jobId,
              page: 1,
              perPage: 2,
            );
            if (articles.isNotEmpty) {
              _currentArticleTitle = articles.first['title']?.toString();
            }
          } catch (_) {}
        }

        final status = _activeJob!['status']?.toString().toUpperCase() ?? '';
        if (status == 'RUNNING' || status == 'PENDING') {
          _startPolling();
        }
      } else {
        _activeJob = null;
        _jobMetrics = null;
      }

      // 3. Fetch Style Profile if available
      final profiles = await _apiClient.getStyleProfiles(journalId: journalId);
      if (profiles.isNotEmpty) {
        _styleProfile = profiles.first;
      } else {
        _styleProfile = null;
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pollJobStatus() async {
    final journalId = widget.journal['id']?.toString() ?? '';
    if (journalId.isEmpty) return;

    try {
      final jobs = await _apiClient.getAnalysisJobs(journalId: journalId);
      if (jobs.isEmpty) return;

      final latest = jobs.first;
      final status = latest['status']?.toString().toUpperCase() ?? '';
      final jobId = latest['id']?.toString() ?? '';

      Map<String, dynamic>? metrics;
      if (jobId.isNotEmpty) {
        metrics = await _apiClient.getJobMetrics(jobId);
        try {
          final articles = await _apiClient.getJobArticles(
            jobId,
            page: 1,
            perPage: 1,
          );
          if (articles.isNotEmpty) {
            _currentArticleTitle = articles.first['title']?.toString();
          }
        } catch (_) {}
      }

      // Check if job completed
      if (status == 'COMPLETED' ||
          status == 'FAILED' ||
          status == 'CANCELLED') {
        _stopPolling();
        // Refresh style profile when job completes
        final profiles = await _apiClient.getStyleProfiles(
          journalId: journalId,
        );
        if (mounted) {
          setState(() {
            _activeJob = latest;
            _jobMetrics = metrics;
            if (profiles.isNotEmpty) {
              _styleProfile = profiles.first;
            }
          });
          widget.onRefreshParent();
        }
      } else {
        if (mounted) {
          setState(() {
            _activeJob = latest;
            _jobMetrics = metrics;
          });
        }
      }
    } catch (_) {
      // Ignore transient polling network errors
    }
  }

  /// 1-Touch Smart Preset Trigger
  Future<void> _handleOneTouchExecute() async {
    final journalId = widget.journal['id']?.toString() ?? '';
    final journalTitle =
        widget.journal['title']?.toString() ?? context.l10n.journal;
    if (journalId.isEmpty) return;

    setState(() => _isTriggering = true);

    try {
      String activeConfigId;
      if (_config != null) {
        activeConfigId = _config!['id'].toString();
        // Update if user changed values in advanced settings
        if (_isAdvancedExpanded) {
          await _apiClient.updateConfiguration(
            activeConfigId,
            domain: _domainController.text.trim(),
            targetArticles: _targetArticles,
            yearFrom: _yearFrom,
            yearTo: _yearTo,
          );
        }
      } else {
        // Auto-create configuration with 300 articles preset
        final created = await _apiClient.createConfiguration(
          journalId: journalId,
          domain: _domainController.text.trim().isNotEmpty
              ? _domainController.text.trim()
              : (widget.journal['field']?.toString() ??
                    context.l10n.defaultDomainCs),
          yearFrom: _yearFrom,
          yearTo: _yearTo,
          targetArticles: _targetArticles,
          referenceCorpusName: 'Academic Core Corpus',
        );
        _config = created;
        activeConfigId = created['id']?.toString() ?? '';
      }

      // Trigger analysis pipeline
      if (activeConfigId.isNotEmpty) {
        await _apiClient.triggerAnalysis(activeConfigId);
        if (mounted) {
          AppNotification.showSuccess(
            context,
            'Đã kích hoạt chu trình khai phá cho "$journalTitle"',
            title: context.l10n.success,
            icon: Icons.bolt_rounded,
          );
        }
      }

      // Refresh state and start live polling
      await _loadJournalData();
      widget.onRefreshParent();
      _startPolling();
    } catch (e) {
      if (mounted) {
        AppNotification.showError(
          context,
          'Lỗi kích hoạt khai phá: $e',
          title: context.l10n.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isTriggering = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(strokeWidth: 2.5),
              const SizedBox(height: 16),
              Text(
                context.l10n.syncCommandCenterDesc,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                  fontFamily: 'Manrope',
                ),
              ),
            ],
          ),
        ),
      );
    }

    final title = widget.journal['title'] ?? context.l10n.unknownJournalTitle;
    final publisher =
        widget.journal['publisher'] ?? context.l10n.unknownPublisher;
    final issn =
        widget.journal['issn_l'] ??
        ((widget.journal['issns'] is List &&
                (widget.journal['issns'] as List).isNotEmpty)
            ? widget.journal['issns'][0].toString()
            : 'N/A');
    final worksCount = widget.journal['works_count'] ?? 0;
    final citedCount = widget.journal['cited_by_count'] ?? 0;

    final jobStatus = _activeJob?['status']?.toString().toUpperCase() ?? 'NONE';
    final isRunning = jobStatus == 'RUNNING' || jobStatus == 'PENDING';
    final isCompleted = jobStatus == 'COMPLETED';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. HERO HEADER
          _buildHeroHeader(
            title,
            publisher,
            issn,
            worksCount,
            citedCount,
            jobStatus,
          ),

          const Divider(height: 1, color: AppColors.borderSoft),

          // 2. ONE-TOUCH ACTION & ADVANCED CONTROLS
          _buildActionAndControls(isRunning, isCompleted),

          const Divider(height: 1, color: AppColors.borderSoft),

          // 3. REALTIME ACTIVE ANALYSIS CARD
          _buildActiveAnalysisSection(jobStatus, isRunning, isCompleted),

          // 4. INSTANT NLP STYLE PROFILE
          if (_styleProfile != null || isCompleted) ...[
            const Divider(height: 1, color: AppColors.borderSoft),
            _buildStyleProfileSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeroHeader(
    String title,
    String publisher,
    String issn,
    dynamic worksCount,
    dynamic citedCount,
    String jobStatus,
  ) {
    Color badgeBg;
    Color badgeText;
    String badgeLabel;
    IconData badgeIcon;

    if (jobStatus == 'RUNNING') {
      badgeBg = AppColors.blue100;
      badgeText = AppColors.blue700;
      badgeLabel = context.l10n.badgeMining;
      badgeIcon = Icons.autorenew_rounded;
    } else if (jobStatus == 'COMPLETED') {
      badgeBg = AppColors.green100;
      badgeText = AppColors.green700;
      badgeLabel = context.l10n.badgeCompleteProfile;
      badgeIcon = Icons.check_circle_rounded;
    } else if (jobStatus == 'FAILED') {
      badgeBg = AppColors.red100;
      badgeText = AppColors.red700;
      badgeLabel = context.l10n.badgePipelineError;
      badgeIcon = Icons.error_outline_rounded;
    } else if (_config != null) {
      badgeBg = AppColors.surfaceSoft;
      badgeText = AppColors.textPrimary;
      badgeLabel = context.l10n.badgeReadyMining;
      badgeIcon = Icons.schedule_rounded;
    } else {
      badgeBg = AppColors.surfaceSoft;
      badgeText = AppColors.textMuted;
      badgeLabel = context.l10n.badgeNotConfigured;
      badgeIcon = Icons.help_outline_rounded;
    }

    return Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: AppColors.textPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        fontFamily: 'Manrope',
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      publisher,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
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
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(badgeIcon, size: 14, color: badgeText),
                    const SizedBox(width: 5),
                    Text(
                      badgeLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: badgeText,
                        fontFamily: 'Manrope',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildMetaTag(Icons.fingerprint_rounded, 'ISSN: $issn'),
              _buildMetaTag(Icons.category_rounded, _domainController.text),
              _buildMetaTag(
                Icons.library_books_rounded,
                '${context.l10n.papersCountLabel(worksCount)} ${context.l10n.worksOnOpenAlexLabel}',
              ),
              _buildMetaTag(
                Icons.format_quote_rounded,
                '${context.l10n.papersCountLabel(citedCount)} ${context.l10n.citationsLabel}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaTag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              fontFamily: 'Manrope',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionAndControls(bool isRunning, bool isCompleted) {
    return Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1-Touch Primary Button
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: (_isTriggering || isRunning)
                      ? null
                      : _handleOneTouchExecute,
                  icon: _isTriggering
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          isCompleted
                              ? Icons.replay_rounded
                              : Icons.play_arrow_rounded,
                          size: 18,
                        ),
                  label: Text(
                    _isTriggering
                        ? 'Đang khởi chạy...'
                        : (isRunning
                              ? 'Đang khai phá theo chu trình...'
                              : (isCompleted
                                    ? context.l10n.reMineActionCount(
                                        _targetArticles,
                                      )
                                    : context.l10n.startMiningActionCount(
                                        _targetArticles,
                                      ))),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Manrope',
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Quick config toggle
              IconButton(
                onPressed: () {
                  setState(() => _isAdvancedExpanded = !_isAdvancedExpanded);
                },
                tooltip: context.l10n.customMiningParams,
                icon: Icon(
                  _isAdvancedExpanded
                      ? Icons.tune_rounded
                      : Icons.tune_outlined,
                  color: _isAdvancedExpanded
                      ? AppColors.primary
                      : AppColors.textMuted,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: _isAdvancedExpanded
                      ? AppColors.blue100
                      : AppColors.surfaceSoft,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: _isAdvancedExpanded
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Preset hint
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.flash_on_rounded,
                size: 13,
                color: AppColors.primary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  context.l10n.defaultOptimizedConfigDetails(
                    _targetArticles,
                    _yearFrom,
                    _yearTo,
                  ),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                    fontFamily: 'Manrope',
                  ),
                ),
              ),
            ],
          ),

          // Collapsible Advanced Settings
          if (_isAdvancedExpanded) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tùy chỉnh tham số khai phá',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontFamily: 'Manrope',
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Target articles presets
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.targetPapersColon,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Manrope',
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [50, 100, 200, 300, 500].map((preset) {
                          final isSel = _targetArticles == preset;
                          return InkWell(
                            onTap: () =>
                                setState(() => _targetArticles = preset),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isSel
                                    ? AppColors.textPrimary
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isSel
                                      ? AppColors.textPrimary
                                      : AppColors.border,
                                ),
                              ),
                              child: Text(
                                context.l10n.papersCountLabel(preset),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isSel
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                  fontFamily: 'Manrope',
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Year range
                  Row(
                    children: [
                      const Text(
                        'Khoảng năm xuất bản:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Manrope',
                        ),
                      ),
                      const SizedBox(width: 12),
                      DropdownButton<int>(
                        value: _yearFrom,
                        underline: const SizedBox(),
                        dropdownColor: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        focusColor: Colors.transparent,
                        elevation: 4,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          fontFamily: 'Manrope',
                        ),
                        items: [2018, 2019, 2020, 2021, 2022, 2023].map((y) {
                          return DropdownMenuItem(value: y, child: Text('$y'));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _yearFrom = val);
                        },
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          '➔',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      ),
                      DropdownButton<int>(
                        value: _yearTo,
                        underline: const SizedBox(),
                        dropdownColor: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        focusColor: Colors.transparent,
                        elevation: 4,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          fontFamily: 'Manrope',
                        ),
                        items: [2022, 2023, 2024, 2025, 2026].map((y) {
                          return DropdownMenuItem(value: y, child: Text('$y'));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _yearTo = val);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActiveAnalysisSection(
    String jobStatus,
    bool isRunning,
    bool isCompleted,
  ) {
    double progressPercent = 0.0;
    final progressVal = (_activeJob?['progress'] as num?)?.toDouble() ?? 0.0;
    progressPercent = progressVal / 100.0;

    if (isCompleted) {
      progressPercent = 1.0;
    }

    final totalArticles =
        (_activeJob?['total_articles'] as num?)?.toInt() ?? _targetArticles;
    final processedArticles =
        (_activeJob?['processed_articles'] as num?)?.toInt() ??
        (_jobMetrics?['normalized'] as num?)?.toInt() ??
        0;
    final failedCount = (_jobMetrics?['failed'] as num?)?.toInt() ?? 0;

    String cardTitle;
    if (isRunning) {
      cardTitle = context.l10n.analyzingCardTitle;
    } else if (isCompleted) {
      cardTitle = context.l10n.completedAnalysisCardTitle;
    } else {
      cardTitle = context.l10n.progressAnalysisCardTitle;
    }

    return Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isRunning
                        ? Icons.autorenew_rounded
                        : (isCompleted
                              ? Icons.check_circle_rounded
                              : Icons.pending_actions_rounded),
                    size: 18,
                    color: isCompleted
                        ? AppColors.green700
                        : (isRunning ? AppColors.primary : AppColors.textMuted),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    cardTitle,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontFamily: 'Manrope',
                    ),
                  ),
                ],
              ),
              if (isRunning)
                Row(
                  children: [
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Đang xử lý • ${(progressPercent * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                        fontFamily: 'Manrope',
                      ),
                    ),
                  ],
                )
              else if (isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.green50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.green100),
                  ),
                  child: const Text(
                    '100% Hoàn thành',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.green700,
                      fontFamily: 'Manrope',
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Linear Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: isCompleted
                  ? 1.0
                  : (isRunning ? progressPercent.clamp(0.05, 1.0) : 0.0),
              minHeight: 7,
              backgroundColor: AppColors.surfaceSoft,
              valueColor: AlwaysStoppedAnimation<Color>(
                isCompleted ? AppColors.green700 : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Active Article Box (Human-first, shows exactly what's being analyzed)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isRunning
                  ? AppColors.blue50.withAlpha(80)
                  : AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isRunning
                    ? AppColors.primary.withAlpha(60)
                    : AppColors.border,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppColors.green50
                        : (isRunning ? Colors.white : AppColors.surface),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isRunning
                        ? Icons.article_rounded
                        : (isCompleted
                              ? Icons.task_alt_rounded
                              : Icons.menu_book_rounded),
                    size: 20,
                    color: isCompleted
                        ? AppColors.green700
                        : (isRunning ? AppColors.primary : AppColors.textMuted),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            isRunning
                                ? context.l10n.parsingPaperProgress(
                                    processedArticles < totalArticles
                                        ? processedArticles + 1
                                        : totalArticles,
                                    totalArticles,
                                  )
                                : (isCompleted
                                      ? 'Đã bóc tách & phân tích hoàn tất'
                                      : 'Chưa có tác vụ phân tích'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isRunning
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                              fontFamily: 'Manrope',
                            ),
                          ),
                          if (isRunning) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'LIVE',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  fontFamily: 'Manrope',
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isRunning
                            ? (_currentArticleTitle != null &&
                                      _currentArticleTitle!.isNotEmpty
                                  ? _currentArticleTitle!
                                  : 'Bài nghiên cứu ${processedArticles < totalArticles ? processedArticles + 1 : totalArticles}: Trích xuất cấu trúc câu IMRAD & CARS Moves...')
                            : (isCompleted
                                  ? context.l10n.miningCompleteStatus(
                                      processedArticles,
                                    )
                                  : context.l10n.clickMineAbovePrompt(
                                      _targetArticles,
                                    )),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isRunning
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: isRunning
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          fontFamily: 'Manrope',
                          fontStyle: isRunning && _currentArticleTitle == null
                              ? FontStyle.italic
                              : FontStyle.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Metric Counters Row
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 8,
              spacing: 12,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 15,
                      color: AppColors.green700,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      context.l10n.completedPapersFraction(
                        processedArticles,
                        totalArticles,
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontFamily: 'Manrope',
                      ),
                    ),
                  ],
                ),
                if (failedCount > 0 && processedArticles < totalArticles)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 15,
                        color: AppColors.error,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        context.l10n.failedPapersCount(failedCount),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.error,
                          fontFamily: 'Manrope',
                        ),
                      ),
                    ],
                  ),
                InkWell(
                  onTap: () => widget.onNavigateToTab(
                    2,
                  ), // Navigate to Tab 2 (Hệ thống & Giám sát logs)
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.l10n.viewJobAndLogsDetails,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                          fontFamily: 'Manrope',
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 13,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStyleProfileSection() {
    final metrics =
        (_styleProfile?['sentence_metrics'] as Map<String, dynamic>?) ?? {};
    final stance = (_styleProfile?['stance'] as Map<String, dynamic>?) ?? {};
    final carsMoves =
        (_styleProfile?['cars_moves'] as Map<String, dynamic>?) ?? {};

    final meanLen = metrics['mean_length'] ?? 21.0;
    final p50Len = metrics['p50'] ?? 20.0;
    final hedges1k = metrics['hedges_per_1k'] ?? 14.5;
    final boosters1k = metrics['boosters_per_1k'] ?? 6.2;

    final territoryMove =
        ((carsMoves['territory'] as num?)?.toDouble() ?? 0.85) * 100;
    final nicheMove = ((carsMoves['niche'] as num?)?.toDouble() ?? 0.72) * 100;

    final supportStance =
        ((stance['support'] as num?)?.toDouble() ?? 0.35) * 100;
    final neutralStance =
        ((stance['neutral'] as num?)?.toDouble() ?? 0.58) * 100;

    return Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 8,
            spacing: 12,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    context.l10n.nlpStyleProfileSectionTitle,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontFamily: 'Manrope',
                    ),
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: () =>
                    widget.onNavigateToTab(1), // Tab 1: Hồ sơ & Đối chuẩn NLP
                icon: const Icon(Icons.analytics_outlined, size: 15),
                label: Text(
                  context.l10n.viewComprehensiveCorpusBenchmark,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Manrope',
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary, width: 1.2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  minimumSize: const Size(0, 36),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 3 Metric Cards Grid
          LayoutBuilder(
            builder: (context, box) {
              final isTight = box.maxWidth < 460;
              if (isTight) {
                return Column(
                  children: [
                    _buildMetricTile(
                      context.l10n.sentenceLengthWords,
                      '$p50Len ${context.l10n.unitWordsPerSentence}',
                      '${context.l10n.avgLabel}: $meanLen • ${context.l10n.academicStandard}',
                      Icons.text_fields_rounded,
                    ),
                    const SizedBox(height: 8),
                    _buildMetricTile(
                      context.l10n.hylandStance,
                      '$hedges1k ${context.l10n.cautiousTone}',
                      'Boosters: $boosters1k • Stance Neutral: ${neutralStance.toInt()}%',
                      Icons.psychology_rounded,
                    ),
                    const SizedBox(height: 8),
                    _buildMetricTile(
                      'CARS Moves (Swales)',
                      'M1: ${territoryMove.toInt()}%',
                      'M2 Niche: ${nicheMove.toInt()}% • M3 Solution',
                      Icons.account_tree_rounded,
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      context.l10n.sentenceLengthWords,
                      '$p50Len ${context.l10n.unitWordsPerSentence}',
                      '${context.l10n.avgLabel}: $meanLen • ${context.l10n.academicStandard}',
                      Icons.text_fields_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricTile(
                      context.l10n.hylandStance,
                      '$hedges1k ${context.l10n.cautiousTone}',
                      'Boosters: $boosters1k • Stance: ${supportStance.toInt()}% sup, ${neutralStance.toInt()}% neu',
                      Icons.psychology_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricTile(
                      'CARS Moves (Swales)',
                      'M1: ${territoryMove.toInt()}%',
                      'M2 Niche: ${nicheMove.toInt()}% • M3 Solution',
                      Icons.account_tree_rounded,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(
    String title,
    String mainValue,
    String subText,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: AppColors.primary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                    fontFamily: 'Manrope',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            mainValue,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              fontFamily: 'Manrope',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
              fontFamily: 'Manrope',
            ),
          ),
        ],
      ),
    );
  }
}
