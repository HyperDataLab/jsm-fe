import 'package:material_ui/material_ui.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../domain/entities/journal_recommendation_item.dart';

class RecommendationsRankedList extends StatelessWidget {
  final List<JournalRecommendationItem> recommendations;
  final ValueChanged<JournalRecommendationItem> onViewComparison;

  const RecommendationsRankedList({
    super.key,
    required this.recommendations,
    required this.onViewComparison,
  });

  Color _getScoreColor(double score) {
    if (score >= 80) return const Color(0xFF10B981);
    if (score >= 60) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    if (recommendations.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.l10n.otherCandidateJournals,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'Manrope',
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...recommendations.map((item) {
          final scoreColor = _getScoreColor(item.compatibilityScore);

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.border),
            ),
            color: AppColors.surface,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Rank & Info
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSoft,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '#${item.rank}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.journalName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Manrope',
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            if (item.issn != null && item.issn!.isNotEmpty)
                              _buildTag('ISSN: ${item.issn}'),
                            if (item.field != null && item.field!.isNotEmpty)
                              _buildTag(
                                context.l10n.localizeField(item.field!),
                              ),
                            if (item.publisher != null &&
                                item.publisher!.isNotEmpty)
                              _buildTag(
                                item.publisher!,
                                color: AppColors.primary,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Score & Level
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${item.compatibilityScore.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: scoreColor,
                            fontFamily: 'Manrope',
                          ),
                        ),
                        Text(
                          item.compatibilityLevel.replaceAll('_', ' '),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: scoreColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Notable differences info
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item.notableDifferences.isNotEmpty)
                          Text(
                            context.l10n.localizeAnalysisString(
                              item.notableDifferences.first,
                            ),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          )
                        else if (item.weakestDimension.isNotEmpty)
                          Text(
                            context.l10n.distinctionLabel(
                              item.weakestDimension.replaceAll('_', ' '),
                            ),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Action Button
                  OutlinedButton.icon(
                    onPressed: () => onViewComparison(item),
                    icon: const Icon(Icons.open_in_new_rounded, size: 14),
                    label: Text(context.l10n.viewComparisonBtn),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      side: const BorderSide(color: AppColors.primary),
                      foregroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTag(String text, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: (color ?? AppColors.textSecondary).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: (color ?? AppColors.textSecondary).withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color ?? AppColors.textSecondary,
        ),
      ),
    );
  }
}
