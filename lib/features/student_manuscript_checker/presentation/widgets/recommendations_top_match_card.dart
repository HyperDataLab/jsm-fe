import 'package:material_ui/material_ui.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../domain/entities/journal_recommendation_item.dart';

class RecommendationsTopMatchCard extends StatelessWidget {
  final JournalRecommendationItem item;
  final VoidCallback onViewComparison;

  const RecommendationsTopMatchCard({
    super.key,
    required this.item,
    required this.onViewComparison,
  });

  Color _getScoreColor(double score) {
    if (score >= 80) return const Color(0xFF10B981);
    if (score >= 60) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  String _formatDimensionName(BuildContext context, String key) {
    switch (key.toLowerCase()) {
      case 'structure':
        return context.l10n.dimStructureAlignment;
      case 'sentencestyle':
      case 'sentence_style':
        return context.l10n.dimSentenceStyle;
      case 'voiceperson':
      case 'voice_person':
      case 'voiceandperson':
      case 'voice_and_person':
        return context.l10n.dimVoicePerson;
      case 'epistemicstyle':
      case 'epistemic_style':
        return context.l10n.dimEpistemicStyle;
      case 'rhetoricalmoves':
      case 'rhetorical_moves':
        return context.l10n.dimRhetoricalMoves;
      default:
        return key.replaceAll('_', ' ');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scoreColor = _getScoreColor(item.compatibilityScore);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    context.l10n.bestMatchBadge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: 0.5,
                      fontFamily: 'Manrope',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  context.l10n.highestStylisticCompatibility,
                  style: TextStyle(
                    color: AppColors.primary.withValues(alpha: 0.85),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Title + Score badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.journalName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Manrope',
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
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
                                _buildTag(item.publisher!),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: scoreColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: scoreColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                item.compatibilityScore.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'Manrope',
                                  color: scoreColor,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '%',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: scoreColor,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            item.compatibilityLevel.replaceAll('_', ' '),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: scoreColor,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                const Divider(color: AppColors.border, height: 1),
                const SizedBox(height: 20),

                // Dimension Breakdown
                Text(
                  context.l10n.styleCompatibilityBreakdown,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Manrope',
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),

                Column(
                  children: [
                    _buildDimensionRow(
                      context.l10n.dimStructureAlignment,
                      item.dimensions.structure,
                    ),
                    _buildDimensionRow(
                      context.l10n.dimSentenceStyle,
                      item.dimensions.sentenceStyle,
                    ),
                    _buildDimensionRow(
                      context.l10n.dimVoicePerson,
                      item.dimensions.voiceAndPerson,
                    ),
                    _buildDimensionRow(
                      context.l10n.dimEpistemicStyle,
                      item.dimensions.epistemicStyle,
                    ),
                    _buildDimensionRow(
                      context.l10n.dimRhetoricalMoves,
                      item.dimensions.rhetoricalMoves,
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Explanations: Strongest match & Differences
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.strongestDimension.isNotEmpty)
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.successSurface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.success.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle_outline_rounded,
                                color: AppColors.success,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      context.l10n.strongestAlignment,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.success,
                                      ),
                                    ),
                                    Text(
                                      _formatDimensionName(
                                        context,
                                        item.strongestDimension,
                                      ),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (item.strongestDimension.isNotEmpty &&
                        item.weakestDimension.isNotEmpty)
                      const SizedBox(width: 12),
                    if (item.weakestDimension.isNotEmpty)
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.warningSurface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.warning.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline_rounded,
                                color: AppColors.warning,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      context.l10n.keyDistinction,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.warning,
                                      ),
                                    ),
                                    Text(
                                      _formatDimensionName(
                                        context,
                                        item.weakestDimension,
                                      ),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),

                if (item.strongAlignments.isNotEmpty ||
                    item.notableDifferences.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSoft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...item.strongAlignments.map(
                          (align) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '✓ ',
                                  style: TextStyle(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    context.l10n.localizeAnalysisString(align),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textPrimary,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        ...item.notableDifferences.map(
                          (diff) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '• ',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    context.l10n.localizeAnalysisString(diff),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Action button
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: onViewComparison,
                    icon: const Icon(Icons.analytics_outlined, size: 18),
                    label: Text(context.l10n.viewFullStyleComparison),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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

  Widget _buildDimensionRow(String name, double dimScore) {
    final color = _getScoreColor(dimScore);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
                fontFamily: 'Manrope',
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4.5),
              child: Container(
                height: 9,
                color: const Color(0xFFF1F5F9),
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: (dimScore / 100).clamp(0.0, 1.0),
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
          const SizedBox(width: 14),
          SizedBox(
            width: 44,
            child: Text(
              '${dimScore.toStringAsFixed(0)}%',
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
    );
  }

  Widget _buildTag(String text, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color ?? AppColors.textSecondary,
        ),
      ),
    );
  }
}
