import 'package:material_ui/material_ui.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../domain/entities/manuscript_check_result.dart';
import '../../domain/repositories/student_manuscript_repository.dart';
import '../widgets/compatibility_radar_chart.dart';
import '../widgets/priority_improvements_card.dart';
import '../widgets/rhetorical_move_card.dart';
import '../widgets/score_rating_card.dart';
import '../widgets/section_scores_card.dart';
import '../widgets/sentence_length_card.dart';
import '../widgets/stance_card.dart';
import '../widgets/style_deviation_matrix_card.dart';
import '../widgets/voice_person_card.dart';
import '../widgets/warnings_list_card.dart';

class EvaluationHistoryDetailPage extends StatefulWidget {
  final String evaluationId;
  final StudentManuscriptRepository repository;
  final VoidCallback onBack;
  final VoidCallback? onRunNewEvaluation;

  const EvaluationHistoryDetailPage({
    super.key,
    required this.evaluationId,
    required this.repository,
    required this.onBack,
    this.onRunNewEvaluation,
  });

  @override
  State<EvaluationHistoryDetailPage> createState() =>
      _EvaluationHistoryDetailPageState();
}

class _EvaluationHistoryDetailPageState
    extends State<EvaluationHistoryDetailPage> {
  late Future<ManuscriptCheckResult> _detailFuture;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  void _loadDetail() {
    _detailFuture = widget.repository.getEvaluationDetail(widget.evaluationId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<ManuscriptCheckResult>(
        future: _detailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingSkeleton();
          }

          if (snapshot.hasError) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.errorSurface,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.error_outline_rounded,
                          size: 40,
                          color: AppColors.error,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.errorLoadingHistory,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          fontFamily: 'Manrope',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        snapshot.error.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontFamily: 'Manrope',
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            onPressed: widget.onBack,
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              size: 16,
                            ),
                            label: Text(l10n.navEvaluationHistory),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _loadDetail();
                              });
                            },
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: Text(l10n.tryAgain),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final result = snapshot.data!;
          return _buildHistoricalResultView(result);
        },
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            height: 280,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoricalResultView(ManuscriptCheckResult result) {
    final l10n = AppLocalizations.of(context);
    final comparison = result.featureComparison;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final isDesktop = availableWidth >= 960;
        final isTablet = availableWidth >= 680;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // HISTORICAL CONTEXT BANNER
              _buildHistoricalContextBanner(l10n),

              const SizedBox(height: 20),

              // LEVEL 1 & 2: DECISION & VISUAL OVERVIEW
              if (isDesktop) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: ScoreRatingCard(
                        result: result,
                        journalTitle: l10n.targetJournalBenchmark,
                        filename: l10n.archivedManuscriptDraft,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 7,
                      child: CompatibilityRadarChart(result: result),
                    ),
                  ],
                ),
              ] else ...[
                ScoreRatingCard(
                  result: result,
                  journalTitle: l10n.targetJournalBenchmark,
                  filename: l10n.archivedManuscriptDraft,
                ),
                const SizedBox(height: 16),
                CompatibilityRadarChart(result: result),
              ],

              const SizedBox(height: 16),

              // LEVEL 3: ACTION — PRIORITY IMPROVEMENTS
              PriorityImprovementsCard(result: result),

              const SizedBox(height: 16),

              // LEVEL 4: STYLE COMPARISON
              if (isTablet) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: SectionScoresCard(
                        sectionScores: result.sectionScores,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SentenceLengthCard(
                        comparison: comparison.sentenceLength,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: VoicePersonCard(
                        comparison: comparison.voiceAndPerson,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: StanceCard(comparison: comparison.stance)),
                  ],
                ),
              ] else ...[
                SectionScoresCard(sectionScores: result.sectionScores),
                const SizedBox(height: 16),
                SentenceLengthCard(comparison: comparison.sentenceLength),
                const SizedBox(height: 16),
                VoicePersonCard(comparison: comparison.voiceAndPerson),
                const SizedBox(height: 16),
                StanceCard(comparison: comparison.stance),
              ],

              const SizedBox(height: 16),

              // Rhetorical Moves Pipeline
              RhetoricalMoveCard(
                moveWarnings: result.rhetoricalMoveWarnings,
                totalSections: result.sectionScores.length,
              ),

              const SizedBox(height: 16),

              // LEVEL 5: STYLISTIC DEVIATION MATRIX & EXPANDABLE DIAGNOSTICS
              StyleDeviationMatrixCard(result: result),

              const SizedBox(height: 16),

              WarningsListCard(warnings: result.warnings),

              const SizedBox(height: 24),

              // Bottom Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: widget.onBack,
                    icon: const Icon(Icons.arrow_back_rounded, size: 16),
                    label: Text(l10n.navEvaluationHistory),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                    ),
                  ),
                  if (widget.onRunNewEvaluation != null) ...[
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: widget.onRunNewEvaluation,
                      icon: const Icon(Icons.replay_rounded, size: 16),
                      label: Text(l10n.runNewEvaluation),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHistoricalContextBanner(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back_rounded, size: 20),
                tooltip: l10n.navEvaluationHistory,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surfaceSoft,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary.withAlpha(50)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.history_rounded,
                      size: 15,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l10n.historicalEvaluationTitle,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        fontFamily: 'Manrope',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  l10n.archivedSnapshotAudited,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    fontFamily: 'Manrope',
                  ),
                ),
              ),
              const Spacer(),
              if (widget.onRunNewEvaluation != null)
                OutlinedButton.icon(
                  onPressed: widget.onRunNewEvaluation,
                  icon: const Icon(Icons.refresh_rounded, size: 14),
                  label: Text(l10n.runNewEvaluation),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),
          Wrap(
            spacing: 24,
            runSpacing: 10,
            children: [
              _buildContextItem(
                Icons.description_outlined,
                l10n.manuscriptIdRef,
                widget.evaluationId.substring(
                  0,
                  widget.evaluationId.length > 8
                      ? 8
                      : widget.evaluationId.length,
                ),
              ),
              _buildContextItem(
                Icons.rule_folder_outlined,
                l10n.journalProfile,
                l10n.preservedV1Profile,
              ),
              _buildContextItem(
                Icons.verified_user_outlined,
                l10n.snapshotIntegrity,
                l10n.immutableSnapshotNotice,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContextItem(IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontFamily: 'Manrope',
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontFamily: 'Manrope',
              ),
            ),
          ],
        ),
      ],
    );
  }
}
