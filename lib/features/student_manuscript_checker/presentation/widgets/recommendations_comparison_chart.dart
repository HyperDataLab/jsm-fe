import 'package:material_ui/material_ui.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../domain/entities/journal_recommendation_item.dart';

class RecommendationsComparisonChart extends StatelessWidget {
  final List<JournalRecommendationItem> recommendations;
  final ValueChanged<JournalRecommendationItem>? onSelectJournal;

  const RecommendationsComparisonChart({
    super.key,
    required this.recommendations,
    this.onSelectJournal,
  });

  Color _getScoreColor(double score) {
    if (score >= 80) return const Color(0xFF10B981);
    if (score >= 60) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    if (recommendations.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.bar_chart_rounded,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    context.l10n.overallCompatibilityRankingTitle,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Manrope',
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                context.l10n.journalsEvaluatedCount(recommendations.length),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontFamily: 'Manrope',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            children: recommendations.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final color = _getScoreColor(item.compatibilityScore);
              final isTop = index == 0;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: InkWell(
                  onTap: () => onSelectJournal?.call(item),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 5,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Rank badge
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isTop
                                ? AppColors.primary
                                : AppColors.surfaceSoft,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '#${item.rank}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Manrope',
                              color: isTop
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Journal Name
                        SizedBox(
                          width: 180,
                          child: Text(
                            item.journalName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isTop
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontFamily: 'Manrope',
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Horizontal Bar (Subtle, clean, 9px height, pill-shaped)
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4.5),
                            child: Container(
                              height: 9,
                              color: const Color(0xFFF1F5F9),
                              alignment: Alignment.centerLeft,
                              child: FractionallySizedBox(
                                widthFactor: (item.compatibilityScore / 100)
                                    .clamp(0.0, 1.0),
                                child: Container(
                                  height: 9,
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(4.5),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Score text
                        SizedBox(
                          width: 50,
                          child: Text(
                            '${item.compatibilityScore.toStringAsFixed(1)}%',
                            textAlign: TextAlign.end,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: color,
                              fontFamily: 'Manrope',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
