import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/language_switcher.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../data/repositories/student_manuscript_repository_impl.dart';
import '../../domain/repositories/student_manuscript_repository.dart';
import '../../domain/usecases/check_manuscript_usecase.dart';
import '../../domain/usecases/get_available_journals_usecase.dart';
import '../cubit/student_manuscript_checker_cubit.dart';
import '../cubit/student_manuscript_checker_state.dart';
import '../widgets/compatibility_radar_chart.dart';
import '../widgets/manuscript_analysis_loading_view.dart';
import '../widgets/manuscript_input_card.dart';
import '../widgets/priority_improvements_card.dart';
import '../widgets/rhetorical_move_card.dart';
import '../widgets/score_rating_card.dart';
import '../widgets/section_scores_card.dart';
import '../widgets/sentence_length_card.dart';
import '../widgets/stance_card.dart';
import '../widgets/style_deviation_matrix_card.dart';
import '../widgets/voice_person_card.dart';
import '../widgets/warnings_list_card.dart';

/// Main page for the Student Manuscript Checker feature.
class StudentManuscriptCheckerPage extends StatelessWidget {
  final StudentManuscriptRepository? repository;
  final StudentManuscriptCheckerCubit? cubit;
  final bool showAppBar;

  const StudentManuscriptCheckerPage({
    super.key,
    this.repository,
    this.cubit,
    this.showAppBar = true,
  });

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider<StudentManuscriptCheckerCubit>.value(
        value: cubit!,
        child: _StudentManuscriptCheckerView(showAppBar: showAppBar),
      );
    }

    try {
      context.read<StudentManuscriptCheckerCubit>();
      return _StudentManuscriptCheckerView(showAppBar: showAppBar);
    } catch (_) {}

    AuthRepository? authRepo;
    try {
      authRepo = context.read<AuthRepository>();
    } catch (_) {}

    final repo =
        repository ?? StudentManuscriptRepositoryImpl(authRepository: authRepo);

    return BlocProvider<StudentManuscriptCheckerCubit>(
      create: (_) => StudentManuscriptCheckerCubit(
        checkManuscriptUseCase: CheckManuscriptUseCase(repo),
        getAvailableJournalsUseCase: GetAvailableJournalsUseCase(repo),
      )..loadJournals(),
      child: _StudentManuscriptCheckerView(showAppBar: showAppBar),
    );
  }
}

class _StudentManuscriptCheckerView extends StatelessWidget {
  final bool showAppBar;
  const _StudentManuscriptCheckerView({this.showAppBar = true});

  @override
  Widget build(BuildContext context) {
    final body = SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = MediaQuery.of(context).size.width;

          double maxCardWidth;
          if (screenWidth >= 1440) {
            maxCardWidth = 1180;
          } else if (screenWidth >= 1200) {
            maxCardWidth = 1050;
          } else {
            maxCardWidth = double.infinity;
          }

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxCardWidth),
              child:
                  BlocBuilder<
                    StudentManuscriptCheckerCubit,
                    StudentManuscriptCheckerState
                  >(
                    builder: (context, state) {
                      if (state is StudentManuscriptCheckerLoading) {
                        return ManuscriptAnalysisLoadingView(
                          state: state,
                          onRetry: () {
                            context
                                .read<StudentManuscriptCheckerCubit>()
                                .reset();
                          },
                        );
                      }

                      if (state is StudentManuscriptCheckerFailure) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ErrorView(
                                  message: state.message,
                                  onRetry: () {
                                    context
                                        .read<StudentManuscriptCheckerCubit>()
                                        .reset();
                                  },
                                ),
                                const SizedBox(height: 12),
                                OutlinedButton(
                                  onPressed: () {
                                    context
                                        .read<StudentManuscriptCheckerCubit>()
                                        .reset();
                                  },
                                  child: Text(
                                    context.l10n.returnToSubmissionForm,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      if (state is StudentManuscriptCheckerEmpty) {
                        return Center(
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
                                    Icons.find_in_page_outlined,
                                    size: 48,
                                    color: AppColors.textSubtle,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  context.l10n.noManuscriptSectionsFound,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                    fontFamily: 'Manrope',
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  state.message,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textMuted,
                                    fontFamily: 'Manrope',
                                  ),
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    context
                                        .read<StudentManuscriptCheckerCubit>()
                                        .reset();
                                  },
                                  icon: const Icon(
                                    Icons.arrow_back_rounded,
                                    size: 16,
                                  ),
                                  label: Text(context.l10n.submitAnotherDraft),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      if (state is StudentManuscriptCheckerSuccess) {
                        return _ResultsView(state: state);
                      }

                      // Initial State
                      final initial = state is StudentManuscriptCheckerInitial
                          ? state
                          : const StudentManuscriptCheckerInitial();

                      return SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 24,
                        ),
                        child: ManuscriptInputCard(initialState: initial),
                      );
                    },
                  ),
            ),
          );
        },
      ),
    );

    if (!showAppBar) {
      return Container(color: AppColors.background, child: body);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.studentCheckerTitle),
        actions: [
          BlocBuilder<
            StudentManuscriptCheckerCubit,
            StudentManuscriptCheckerState
          >(
            builder: (context, state) {
              if (state is StudentManuscriptCheckerSuccess ||
                  state is StudentManuscriptCheckerEmpty ||
                  state is StudentManuscriptCheckerFailure) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: OutlinedButton.icon(
                    onPressed: () {
                      context.read<StudentManuscriptCheckerCubit>().reset();
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: Text(context.l10n.newCheck),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          const LanguageSwitcher(),
          const SizedBox(width: 12),
        ],
      ),
      body: body,
    );
  }
}

class _ResultsView extends StatelessWidget {
  final StudentManuscriptCheckerSuccess state;

  const _ResultsView({required this.state});

  @override
  Widget build(BuildContext context) {
    final result = state.result;
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
              // LEVEL 1 & 2: DECISION & VISUAL OVERVIEW
              // Row 1: Compatibility Overview (5 cols) & Radar Chart (7 cols)
              if (isDesktop) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: ScoreRatingCard(
                        result: result,
                        journalTitle: state.targetJournalTitle,
                        filename: state.manuscriptFileName,
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
                  journalTitle: state.targetJournalTitle,
                  filename: state.manuscriptFileName,
                ),
                const SizedBox(height: 16),
                CompatibilityRadarChart(result: result),
              ],

              const SizedBox(height: 16),

              // LEVEL 3: ACTION — PRIORITY IMPROVEMENTS
              PriorityImprovementsCard(result: result),

              const SizedBox(height: 16),

              // LEVEL 4: STYLE COMPARISON
              // Section Alignment & Sentence Length
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

              // Bottom Action
              Center(
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.read<StudentManuscriptCheckerCubit>().reset();
                  },
                  icon: const Icon(Icons.arrow_back_rounded, size: 16),
                  label: Text(context.l10n.checkAnotherManuscript),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
