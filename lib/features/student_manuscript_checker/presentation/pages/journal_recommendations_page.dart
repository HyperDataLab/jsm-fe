import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../domain/repositories/student_manuscript_repository.dart';
import '../cubit/journal_recommendations_cubit.dart';
import '../cubit/journal_recommendations_state.dart';
import '../widgets/compatibility_radar_chart.dart';
import '../widgets/priority_improvements_card.dart';
import '../widgets/recommendations_comparison_chart.dart';
import '../widgets/recommendations_dimension_table.dart';
import '../widgets/recommendations_input_card.dart';
import '../widgets/recommendations_pipeline_screen.dart';
import '../widgets/recommendations_ranked_list.dart';
import '../widgets/recommendations_top_match_card.dart';
import '../widgets/rhetorical_move_card.dart';
import '../widgets/score_rating_card.dart';
import '../widgets/section_scores_card.dart';
import '../widgets/sentence_length_card.dart';
import '../widgets/stance_card.dart';
import '../widgets/style_deviation_matrix_card.dart';
import '../widgets/voice_person_card.dart';
import '../widgets/warnings_list_card.dart';

import '../../../auth/domain/repositories/auth_repository.dart';
import '../../data/repositories/student_manuscript_repository_impl.dart';
import '../cubit/evaluation_history_cubit.dart';

class JournalRecommendationsPage extends StatelessWidget {
  final StudentManuscriptRepository? repository;
  final JournalRecommendationsCubit? cubit;

  const JournalRecommendationsPage({super.key, this.repository, this.cubit});

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider<JournalRecommendationsCubit>.value(
        value: cubit!,
        child: const _JournalRecommendationsView(),
      );
    }

    StudentManuscriptRepository repo;
    if (repository != null) {
      repo = repository!;
    } else {
      try {
        repo = context.read<StudentManuscriptRepository>();
      } catch (_) {
        AuthRepository? authRepo;
        try {
          authRepo = context.read<AuthRepository>();
        } catch (_) {}
        repo = StudentManuscriptRepositoryImpl(authRepository: authRepo);
      }
    }

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<StudentManuscriptRepository>.value(value: repo),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<JournalRecommendationsCubit>(
            create: (context) =>
                JournalRecommendationsCubit(repository: repo)..init(),
          ),
          BlocProvider<EvaluationHistoryCubit>(
            create: (context) =>
                EvaluationHistoryCubit(repository: repo)..loadHistory(),
          ),
        ],
        child: const _JournalRecommendationsView(),
      ),
    );
  }
}

class _JournalRecommendationsView extends StatelessWidget {
  const _JournalRecommendationsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body:
          BlocBuilder<JournalRecommendationsCubit, JournalRecommendationsState>(
            builder: (context, state) {
              if (state.isLoading) {
                return RecommendationsPipelineScreen(state: state);
              }

              if (state.hasDetailedView) {
                return _buildDetailedComparisonView(context, state);
              }

              if (state.isSuccess && state.recommendationResponse != null) {
                return _buildRecommendationsDashboard(context, state);
              }

              return _buildInputView(context);
            },
          ),
    );
  }

  Widget _buildInputView(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(
            title: context.l10n.journalRecommendationsTitle,
            subtitle: context.l10n.journalRecommendationsSubtitle,
          ),
          const SizedBox(height: 24),
          RecommendationsInputCard(
            onAnalyze: () {
              context
                  .read<JournalRecommendationsCubit>()
                  .submitRecommendationRequest();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsDashboard(
    BuildContext context,
    JournalRecommendationsState state,
  ) {
    final response = state.recommendationResponse!;
    final recommendations = response.recommendations;

    if (recommendations.isEmpty) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceSoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.inbox_rounded,
                    size: 48,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  context.l10n.noEligibleJournalsTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Manrope',
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.noEligibleJournalsDesc,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    context.read<JournalRecommendationsCubit>().reset();
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: Text(context.l10n.tryAnotherManuscript),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final topMatch = recommendations.first;
    final otherMatches = recommendations.length > 1
        ? recommendations.sublist(1)
        : <dynamic>[];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header & Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildHeader(
                  title: context.l10n.journalRecommendationsTitle,
                  subtitle: context.l10n.evaluatedAgainstJournals(
                    response.candidateCount,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  context.read<JournalRecommendationsCubit>().reset();
                },
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: Text(context.l10n.evaluateAnother),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  side: const BorderSide(color: AppColors.border),
                  foregroundColor: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // #1 Best Match Card
          RecommendationsTopMatchCard(
            item: topMatch,
            onViewComparison: () {
              context.read<JournalRecommendationsCubit>().viewComparison(
                topMatch,
              );
            },
          ),

          const SizedBox(height: 24),

          // Overall Comparison Chart
          RecommendationsComparisonChart(
            recommendations: recommendations,
            onSelectJournal: (item) {
              context.read<JournalRecommendationsCubit>().viewComparison(item);
            },
          ),

          const SizedBox(height: 24),

          // Dimension Comparison Heatmap Table
          RecommendationsDimensionTable(recommendations: recommendations),

          if (otherMatches.isNotEmpty) ...[
            const SizedBox(height: 24),
            RecommendationsRankedList(
              recommendations: recommendations.sublist(1),
              onViewComparison: (item) {
                context.read<JournalRecommendationsCubit>().viewComparison(
                  item,
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailedComparisonView(
    BuildContext context,
    JournalRecommendationsState state,
  ) {
    final selectedItem = state.selectedJournalForDetailedView!;
    final checkResult = selectedItem.checkResult;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final isDesktop = availableWidth >= 960;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Bar with Back Button
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => context
                          .read<JournalRecommendationsCubit>()
                          .closeComparison(),
                      tooltip: context.l10n.backToRecommendations,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                context.l10n.comparisonDetailFor(
                                  selectedItem.journalName,
                                ),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Manrope',
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primarySoft,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  context.l10n.rankMatchBadge(
                                    selectedItem.rank,
                                    selectedItem.compatibilityScore
                                        .toStringAsFixed(1),
                                  ),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            context.l10n.targetJournalBenchmarkFor(
                              selectedItem.journalName,
                            ),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => context
                          .read<JournalRecommendationsCubit>()
                          .closeComparison(),
                      icon: const Icon(
                        Icons.format_list_bulleted_rounded,
                        size: 16,
                      ),
                      label: Text(context.l10n.backToRecommendations),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Reused Dashboard Components
              if (isDesktop) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: ScoreRatingCard(
                        result: checkResult,
                        journalTitle: selectedItem.journalName,
                        filename:
                            state.fileName ??
                            context.l10n.studentManuscriptLabel,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 7,
                      child: CompatibilityRadarChart(result: checkResult),
                    ),
                  ],
                ),
              ] else ...[
                ScoreRatingCard(
                  result: checkResult,
                  journalTitle: selectedItem.journalName,
                  filename:
                      state.fileName ?? context.l10n.studentManuscriptLabel,
                ),
                const SizedBox(height: 16),
                CompatibilityRadarChart(result: checkResult),
              ],

              const SizedBox(height: 16),
              PriorityImprovementsCard(result: checkResult),
              const SizedBox(height: 16),
              SectionScoresCard(sectionScores: checkResult.sectionScores),
              const SizedBox(height: 16),
              SentenceLengthCard(
                comparison: checkResult.featureComparison.sentenceLength,
              ),
              const SizedBox(height: 16),
              VoicePersonCard(
                comparison: checkResult.featureComparison.voiceAndPerson,
              ),
              const SizedBox(height: 16),
              StanceCard(comparison: checkResult.featureComparison.stance),
              const SizedBox(height: 16),
              RhetoricalMoveCard(
                moveWarnings: checkResult.rhetoricalMoveWarnings,
                totalSections: checkResult.sectionScores.length,
              ),
              const SizedBox(height: 16),
              StyleDeviationMatrixCard(result: checkResult),
              const SizedBox(height: 16),
              WarningsListCard(warnings: checkResult.warnings),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader({required String title, required String subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            fontFamily: 'Manrope',
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            fontFamily: 'Manrope',
          ),
        ),
      ],
    );
  }
}
