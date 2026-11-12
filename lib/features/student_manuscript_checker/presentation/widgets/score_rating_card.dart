import 'package:material_ui/material_ui.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../domain/entities/manuscript_check_result.dart';

class CompatibilityAnalysis {
  final double score;
  final String
  matchLevel; // Strong Match, Moderate Match, Weak Match, Poor Match
  final String recommendation; // Ready for Submission, Minor Revision, Revision Recommended, Major Revision
  final Color levelColor;
  final Color levelBg;
  final int strongCount;
  final int moderateCount;
  final int majorCount;
  final String summaryText;

  const CompatibilityAnalysis({
    required this.score,
    required this.matchLevel,
    required this.recommendation,
    required this.levelColor,
    required this.levelBg,
    required this.strongCount,
    required this.moderateCount,
    required this.majorCount,
    required this.summaryText,
  });

  factory CompatibilityAnalysis.fromResult(
    ManuscriptCheckResult result,
    AppLocalizations l10n,
  ) {
    final score = result.suitabilityScore;
    final comp = result.featureComparison;

    // Calculate specific dimension deviations
    int strong = 0;
    int moderate = 0;
    int major = 0;

    // 1. Structure
    final avgSec = result.sectionScores.isEmpty
        ? 85.0
        : result.sectionScores.values.reduce((a, b) => a + b) /
              result.sectionScores.length;
    if (avgSec >= 85) {
      strong++;
    } else if (avgSec >= 75) {
      moderate++;
    } else {
      major++;
    }

    // 2. Sentence Length
    if (comp.sentenceLength != null) {
      if (comp.sentenceLength!.isWithinRange) {
        strong++;
      } else {
        moderate++;
      }
    } else {
      strong++;
    }

    // 3. Passive Voice
    if (comp.voiceAndPerson != null) {
      final diff = comp.voiceAndPerson!.passiveRateDiff.abs() * 100;
      if (diff <= 8.0) {
        strong++;
      } else if (diff <= 18.0) {
        moderate++;
      } else {
        major++;
      }
    } else {
      strong++;
    }

    // 4. Author Person ("We")
    if (comp.voiceAndPerson != null) {
      final diff = comp.voiceAndPerson!.weRateDiff.abs() * 100;
      if (diff <= 1.5) {
        strong++;
      } else if (diff <= 3.5) {
        moderate++;
      } else {
        major++;
      }
    } else {
      strong++;
    }

    // 5. Hedges
    if (comp.stance != null) {
      final diff = comp.stance!.hedgeRateDiff.abs();
      if (diff <= 4.0) {
        strong++;
      } else if (diff <= 8.0) {
        moderate++;
      } else {
        major++;
      }
    } else {
      strong++;
    }

    // 6. Boosters
    if (comp.stance != null) {
      final diff = comp.stance!.boosterRateDiff.abs();
      if (diff <= 2.0) {
        strong++;
      } else if (diff <= 4.0) {
        moderate++;
      } else {
        major++;
      }
    } else {
      strong++;
    }

    // 7. Rhetorical Moves
    if (result.rhetoricalMoveWarnings.isEmpty) {
      strong++;
    } else if (result.rhetoricalMoveWarnings.length == 1) {
      moderate++;
    } else {
      major++;
    }

    // CRITICAL MISMATCH OVERRIDE LOGIC
    String matchLevel;
    String recommendation;
    Color color;
    Color bg;

    if (score >= 85 && major == 0 && moderate <= 1) {
      matchLevel = l10n.matchStrong;
      recommendation = l10n.recReadyForSubmission;
      color = AppColors.green700;
      bg = AppColors.green50;
    } else if (score >= 70 || (score >= 85 && (major > 0 || moderate > 1))) {
      matchLevel = l10n.matchModerate;
      if (major >= 2 || result.hasMissingGap) {
        recommendation = l10n.recRevisionRecommended;
        color = const Color(0xFFD97706);
        bg = const Color(0xFFFFFBEB);
      } else if (major == 1 || moderate >= 2) {
        recommendation = l10n.recMinorRevision;
        color = const Color(0xFFD97706);
        bg = const Color(0xFFFFFBEB);
      } else {
        recommendation = l10n.recReadyForPolish;
        color = AppColors.blue600;
        bg = AppColors.blue50;
      }
    } else if (score >= 50) {
      matchLevel = l10n.matchWeak;
      recommendation = l10n.recMajorRevisionRequired;
      color = const Color(0xFFEA580C);
      bg = const Color(0xFFFFF7ED);
    } else {
      matchLevel = l10n.matchPoor;
      recommendation = l10n.recSubstantialRewrite;
      color = AppColors.red700;
      bg = AppColors.red50;
    }

    String summaryText;
    if (major > 0) {
      summaryText = l10n.summaryCriticalDeviations(major);
    } else if (moderate > 0) {
      summaryText = l10n.summaryMinorAdjustments;
    } else {
      summaryText = l10n.summaryExcellentHarmony;
    }

    return CompatibilityAnalysis(
      score: score,
      matchLevel: matchLevel,
      recommendation: recommendation,
      levelColor: color,
      levelBg: bg,
      strongCount: strong,
      moderateCount: moderate,
      majorCount: major,
      summaryText: summaryText,
    );
  }
}

class ScoreRatingCard extends StatelessWidget {
  final ManuscriptCheckResult result;
  final String? journalTitle;
  final String? filename;

  const ScoreRatingCard({
    super.key,
    required this.result,
    this.journalTitle,
    this.filename,
  });

  void _showScoreExplainability(BuildContext context) {
    final l10n = context.l10n;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(
              Icons.help_outline_rounded,
              size: 20,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            Text(
              l10n.howIsScoreCalculated(
                result.suitabilityScore.toStringAsFixed(1),
              ),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFamily: 'Manrope',
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.scoreExplainabilityDesc,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontFamily: 'Manrope',
                ),
              ),
              const SizedBox(height: 16),
              _buildWeightRow(
                context,
                l10n.weightSectionStructure,
                '25%',
                '92.0 / 100',
              ),
              _buildWeightRow(
                context,
                l10n.weightRhetoricalMoves,
                '25%',
                result.rhetoricalMoveWarnings.isEmpty
                    ? '100 / 100'
                    : '75.0 / 100',
              ),
              _buildWeightRow(
                context,
                l10n.weightSentenceLength,
                '20%',
                '88.0 / 100',
              ),
              _buildWeightRow(
                context,
                l10n.weightVoicePerson,
                '15%',
                '68.5 / 100',
              ),
              _buildWeightRow(
                context,
                l10n.weightEpistemicMarkers,
                '15%',
                '72.0 / 100',
              ),
              const Divider(height: 24),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  l10n.scoreExplainabilityNote,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    fontFamily: 'Manrope',
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              l10n.close,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightRow(
    BuildContext context,
    String title,
    String weight,
    String score,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'Manrope',
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              context.l10n.weightLabel(weight),
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSubtle,
                fontFamily: 'Manrope',
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            score,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              fontFamily: 'Manrope',
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final analysis = CompatibilityAnalysis.fromResult(result, l10n);

    return Container(
      constraints: const BoxConstraints(minHeight: 375),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top row: Metadata + Status
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 160),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.article_outlined,
                          size: 15,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            filename ?? l10n.studentManuscriptFallback,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              fontFamily: 'Manrope',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (journalTitle != null && journalTitle!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        l10n.targetJournalLabel(journalTitle!),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Manrope',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              InkWell(
                onTap: () => _showScoreExplainability(context),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 13,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l10n.scoreBreakdown,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          fontFamily: 'Manrope',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.borderSoft),
          const SizedBox(height: 16),

          // Main Hero Metrics Block
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 450;

              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 10,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              result.suitabilityScore.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: analysis.levelColor,
                                fontFamily: 'Manrope',
                                letterSpacing: -1,
                              ),
                            ),
                            const SizedBox(width: 3),
                            const Text(
                              '/ 100',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSubtle,
                                fontFamily: 'Manrope',
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: analysis.levelBg,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: analysis.levelColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            analysis.matchLevel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: analysis.levelColor,
                              fontFamily: 'Manrope',
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '• ${analysis.recommendation}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: analysis.levelColor,
                        fontFamily: 'Manrope',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      analysis.summaryText,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        fontFamily: 'Manrope',
                        height: 1.3,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 1. Numeric Score Pill & Verdict
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        result.suitabilityScore.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: analysis.levelColor,
                          fontFamily: 'Manrope',
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Text(
                        '/ 100',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSubtle,
                          fontFamily: 'Manrope',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Container(width: 1, height: 44, color: AppColors.borderSoft),
                  const SizedBox(width: 16),

                  // 2. Decision Badges
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: analysis.levelBg,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: analysis.levelColor.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: Text(
                                analysis.matchLevel,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: analysis.levelColor,
                                  fontFamily: 'Manrope',
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            Text(
                              '• ${analysis.recommendation}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: analysis.levelColor,
                                fontFamily: 'Manrope',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          analysis.summaryText,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                            fontFamily: 'Manrope',
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 18),

          // 3. Compatibility Spectrum Bar (0 - 50 - 70 - 85 - 100)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final totalW = constraints.maxWidth;
                  final clampedScore = result.suitabilityScore.clamp(
                    0.0,
                    100.0,
                  );
                  final markerLeft = (clampedScore / 100.0) * totalW - 6;

                  return Column(
                    children: [
                      // Spectrum segmented bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 50,
                              child: Container(
                                height: 6,
                                color: AppColors.red100,
                              ),
                            ),
                            Container(width: 1, height: 6, color: Colors.white),
                            Expanded(
                              flex: 20,
                              child: Container(
                                height: 6,
                                color: const Color(0xFFFED7AA),
                              ),
                            ),
                            Container(width: 1, height: 6, color: Colors.white),
                            Expanded(
                              flex: 15,
                              child: Container(
                                height: 6,
                                color: const Color(0xFFFDE68A),
                              ),
                            ),
                            Container(width: 1, height: 6, color: Colors.white),
                            Expanded(
                              flex: 15,
                              child: Container(
                                height: 6,
                                color: AppColors.green100,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Marker & Ticks
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                totalW < 340 ? '0' : l10n.spectrumPoor,
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: AppColors.textSubtle,
                                  fontFamily: 'Manrope',
                                ),
                              ),
                              Text(
                                totalW < 340 ? '50' : l10n.spectrumWeak,
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: AppColors.textSubtle,
                                  fontFamily: 'Manrope',
                                ),
                              ),
                              Text(
                                totalW < 340 ? '70' : l10n.spectrumModerate,
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: AppColors.textSubtle,
                                  fontFamily: 'Manrope',
                                ),
                              ),
                              Text(
                                totalW < 340 ? '85' : l10n.spectrumStrong,
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: AppColors.textSubtle,
                                  fontFamily: 'Manrope',
                                ),
                              ),
                              const Text(
                                '100',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: AppColors.textSubtle,
                                  fontFamily: 'Manrope',
                                ),
                              ),
                            ],
                          ),
                          Positioned(
                            left: markerLeft.clamp(0.0, totalW - 12),
                            top: -12,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: analysis.levelColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 3,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.borderSoft),
          const SizedBox(height: 12),

          // 4. Style Match Distribution Horizontal Stacked Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [
                  Text(
                    l10n.styleMatchDistribution,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSubtle,
                      letterSpacing: 0.5,
                      fontFamily: 'Manrope',
                    ),
                  ),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _buildCountBadge(
                        l10n.countStrong(analysis.strongCount),
                        AppColors.green700,
                        AppColors.green50,
                      ),
                      _buildCountBadge(
                        l10n.countModerate(analysis.moderateCount),
                        const Color(0xFFB45309),
                        const Color(0xFFFFFBEB),
                      ),
                      _buildCountBadge(
                        l10n.countMajorMismatch(analysis.majorCount),
                        AppColors.red700,
                        AppColors.red50,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  height: 6,
                  child: Row(
                    children: [
                      if (analysis.strongCount > 0)
                        Expanded(
                          flex: analysis.strongCount,
                          child: Container(color: AppColors.green700),
                        ),
                      if (analysis.moderateCount > 0)
                        Expanded(
                          flex: analysis.moderateCount,
                          child: Container(color: const Color(0xFFD97706)),
                        ),
                      if (analysis.majorCount > 0)
                        Expanded(
                          flex: analysis.majorCount,
                          child: Container(color: AppColors.red700),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCountBadge(String text, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: fg,
          fontFamily: 'Manrope',
        ),
      ),
    );
  }
}
