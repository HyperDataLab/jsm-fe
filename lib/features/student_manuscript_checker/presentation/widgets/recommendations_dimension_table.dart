import 'package:material_ui/material_ui.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../domain/entities/journal_recommendation_item.dart';

class RecommendationsDimensionTable extends StatelessWidget {
  final List<JournalRecommendationItem> recommendations;

  const RecommendationsDimensionTable({
    super.key,
    required this.recommendations,
  });

  Color _getCellBgColor(double score) {
    if (score >= 80) return AppColors.successSurface;
    if (score >= 60) return AppColors.warningSurface;
    return AppColors.errorSurface;
  }

  Color _getCellTextColor(double score) {
    if (score >= 80) return AppColors.success;
    if (score >= 60) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    if (recommendations.isEmpty) return const SizedBox.shrink();

    final dimensions = [
      (
        context.l10n.dimStructureAlignment,
        (JournalRecommendationItem r) => r.dimensions.structure,
        false,
      ),
      (
        context.l10n.dimSentenceStyle,
        (JournalRecommendationItem r) => r.dimensions.sentenceStyle,
        false,
      ),
      (
        context.l10n.dimVoicePerson,
        (JournalRecommendationItem r) => r.dimensions.voiceAndPerson,
        false,
      ),
      (
        context.l10n.dimEpistemicStyle,
        (JournalRecommendationItem r) => r.dimensions.epistemicStyle,
        false,
      ),
      (
        context.l10n.dimRhetoricalMoves,
        (JournalRecommendationItem r) => r.dimensions.rhetoricalMoves,
        false,
      ),
      (
        context.l10n.dimOverallMatch,
        (JournalRecommendationItem r) => r.compatibilityScore,
        true,
      ),
    ];

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
            children: [
              const Icon(
                Icons.grid_view_rounded,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                context.l10n.crossJournalHeatmapTitle,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Manrope',
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final minTableWidth = recommendations.length * 130.0 + 160.0;
              final effectiveWidth = constraints.maxWidth > minTableWidth
                  ? constraints.maxWidth
                  : minTableWidth;

              final Map<int, TableColumnWidth> colWidths = {
                0: const FlexColumnWidth(1.2), // Dimension column
                for (int i = 0; i < recommendations.length; i++)
                  i + 1: const FlexColumnWidth(1.0), // Equal journal columns
              };

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: effectiveWidth),
                  child: Table(
                    columnWidths: colWidths,
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    border: TableBorder.all(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(8),
                      width: 1,
                    ),
                    children: [
                      // Header row
                      TableRow(
                        decoration: const BoxDecoration(
                          color: AppColors.surfaceSoft,
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 11,
                            ),
                            child: Text(
                              context.l10n.dimensionCol,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                fontFamily: 'Manrope',
                              ),
                            ),
                          ),
                          ...recommendations.map(
                            (rec) => Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 11,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    rec.journalName,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                      fontFamily: 'Manrope',
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '#${rec.rank}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                      fontFamily: 'Manrope',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Data rows
                      ...dimensions.map((dim) {
                        final isOverall = dim.$3;
                        return TableRow(
                          decoration: BoxDecoration(
                            color: isOverall
                                ? AppColors.primarySoft.withValues(alpha: 0.35)
                                : Colors.transparent,
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              child: Text(
                                dim.$1,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isOverall
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isOverall
                                      ? AppColors.primary
                                      : AppColors.textPrimary,
                                  fontFamily: 'Manrope',
                                ),
                              ),
                            ),
                            ...recommendations.map((rec) {
                              final score = dim.$2(rec);
                              final bg = _getCellBgColor(score);
                              final textClr = _getCellTextColor(score);
                              return Container(
                                color: isOverall ? null : bg,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${score.toStringAsFixed(1)}%',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isOverall
                                        ? FontWeight.w800
                                        : FontWeight.w700,
                                    color: isOverall
                                        ? AppColors.primary
                                        : textClr,
                                    fontFamily: 'Manrope',
                                  ),
                                ),
                              );
                            }),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          // Legend aligned to table boundary
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildLegendItem(
                context.l10n.legendStrong,
                AppColors.success,
                AppColors.successSurface,
              ),
              const SizedBox(width: 16),
              _buildLegendItem(
                context.l10n.legendModerate,
                AppColors.warning,
                AppColors.warningSurface,
              ),
              const SizedBox(width: 16),
              _buildLegendItem(
                context.l10n.legendLow,
                AppColors.error,
                AppColors.errorSurface,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color textColor, Color bgColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.all(color: textColor.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: textColor,
            fontWeight: FontWeight.w600,
            fontFamily: 'Manrope',
          ),
        ),
      ],
    );
  }
}
