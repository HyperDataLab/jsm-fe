import 'package:material_ui/material_ui.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../cubit/journal_recommendations_state.dart';

class RecommendationsPipelineScreen extends StatelessWidget {
  final JournalRecommendationsState state;

  const RecommendationsPipelineScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final availableCount = state.availableJournalsCount > 0
        ? '${state.availableJournalsCount}'
        : (context.l10n.isVietnamese ? 'các' : 'available');

    final steps = [
      (
        title: context.l10n.pipelineExtractFeaturesTitle,
        subtitle: context.l10n.pipelineExtractFeaturesSub,
        threshold: 0.15,
      ),
      (
        title: context.l10n.pipelineRetrieveProfilesTitle,
        subtitle: context.l10n.pipelineRetrieveProfilesSub(availableCount),
        threshold: 0.45,
      ),
      (
        title: context.l10n.pipelineCompareStyleTitle,
        subtitle: context.l10n.pipelineCompareStyleSub,
        threshold: 0.75,
      ),
      (
        title: context.l10n.pipelineRankSynthesizeTitle,
        subtitle: context.l10n.pipelineRankSynthesizeSub,
        threshold: 0.95,
      ),
    ];

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.findingSuitableJournalsTitle,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Manrope',
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            state.fileName != null
                                ? context.l10n.evaluatingFile(state.fileName!)
                                : context.l10n.analyzingAgainstDataset,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: state.pipelineProgress > 0
                        ? state.pipelineProgress
                        : null,
                    backgroundColor: AppColors.surfaceSoft,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 28),
                // Pipeline Steps
                Column(
                  children: steps.map((step) {
                    final isDone = state.pipelineProgress > step.threshold;
                    final isCurrent =
                        state.pipelineProgress >= (step.threshold - 0.25) &&
                        state.pipelineProgress <= step.threshold;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDone
                                  ? AppColors.successSurface
                                  : (isCurrent
                                        ? AppColors.primarySoft
                                        : AppColors.surfaceSoft),
                              border: Border.all(
                                color: isDone
                                    ? AppColors.success
                                    : (isCurrent
                                          ? AppColors.primary
                                          : AppColors.border),
                              ),
                            ),
                            child: Center(
                              child: isDone
                                  ? const Icon(
                                      Icons.check_rounded,
                                      size: 16,
                                      color: AppColors.success,
                                    )
                                  : (isCurrent
                                        ? const SizedBox(
                                            width: 12,
                                            height: 12,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    AppColors.primary,
                                                  ),
                                            ),
                                          )
                                        : Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: AppColors.textSecondary,
                                            ),
                                          )),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  step.title,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isCurrent || isDone
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isCurrent || isDone
                                        ? AppColors.textPrimary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  step.subtitle,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
