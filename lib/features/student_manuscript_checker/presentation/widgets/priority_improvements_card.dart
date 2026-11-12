import 'package:material_ui/material_ui.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../domain/entities/manuscript_check_result.dart';
import '../../domain/entities/warning_item.dart';

class PriorityIssue {
  final String title;
  final String priority; // HIGH, MEDIUM, LOW
  final String description;
  final String manuscriptValue;
  final String journalValue;
  final String deviation;
  final String? section;

  const PriorityIssue({
    required this.title,
    required this.priority,
    required this.description,
    required this.manuscriptValue,
    required this.journalValue,
    required this.deviation,
    this.section,
  });
}

class PriorityImprovementsCard extends StatelessWidget {
  final ManuscriptCheckResult result;
  final Function(WarningItem)? onSelectWarning;

  const PriorityImprovementsCard({
    super.key,
    required this.result,
    this.onSelectWarning,
  });

  List<PriorityIssue> _extractPriorityIssues(AppLocalizations l10n) {
    final issues = <PriorityIssue>[];
    final comp = result.featureComparison;

    // 1. Author Voice check
    if (comp.voiceAndPerson != null) {
      final vp = comp.voiceAndPerson!;
      if (vp.weRateDiff.abs() >= 2.9 ||
          (vp.userWeRate == 0 && vp.journalWeRate > 2.0)) {
        issues.add(
          PriorityIssue(
            title: l10n.issueAuthorVoice,
            priority: 'HIGH',
            description: l10n.issueAuthorVoiceDesc,
            manuscriptValue: '${vp.userWeRate.toStringAsFixed(1)}%',
            journalValue: '${vp.journalWeRate.toStringAsFixed(1)}%',
            deviation: '${vp.weRateDiff.toStringAsFixed(1)} pp',
          ),
        );
      }
    }

    // 2. Boosters check
    if (comp.stance != null) {
      final st = comp.stance!;
      if (st.boosterRateDiff.abs() > 2.0 ||
          (st.userBoosterRate == 0 && st.journalBoosterRate > 3.0)) {
        issues.add(
          PriorityIssue(
            title: l10n.issueBoosters,
            priority: 'HIGH',
            description: l10n.issueBoostersDesc,
            manuscriptValue: '${st.userBoosterRate.toStringAsFixed(1)} /1k',
            journalValue: '${st.journalBoosterRate.toStringAsFixed(1)} /1k',
            deviation: '${st.boosterRateDiff.toStringAsFixed(1)} /1k',
          ),
        );
      }
    }

    // 3. Missing Gap
    if (result.hasMissingGap) {
      issues.add(
        PriorityIssue(
          title: l10n.issueResearchGap,
          priority: 'HIGH',
          description: l10n.issueResearchGapDesc,
          manuscriptValue: l10n.valMissing,
          journalValue: l10n.valRequired,
          deviation: l10n.valCriticalMove,
          section: 'INTRO',
        ),
      );
    }

    // 4. Section scores < 80%
    result.sectionScores.forEach((sec, score) {
      if (score < 80.0) {
        issues.add(
          PriorityIssue(
            title: l10n.issueSectionStyle(sec.toUpperCase()),
            priority: score < 75 ? 'HIGH' : 'MEDIUM',
            description: l10n.issueSectionStyleDesc,
            manuscriptValue: '${score.toStringAsFixed(0)}%',
            journalValue: '>= 85%',
            deviation: '${(score - 85).toStringAsFixed(0)} pp',
            section: sec,
          ),
        );
      }
    });

    // 5. Warnings with HIGH/CRITICAL severity
    for (final w in result.warnings) {
      if (issues.length >= 4) break;
      if (w.severity == 'CRITICAL' || w.severity == 'HIGH') {
        if (!issues.any(
          (i) => i.title.contains(w.title) || w.title.contains(i.title),
        )) {
          issues.add(
            PriorityIssue(
              title: l10n.localizeAnalysisString(w.title),
              priority: w.severity,
              description: l10n.localizeAnalysisString(w.message),
              manuscriptValue: l10n.valDivergent,
              journalValue: l10n.valExpected,
              deviation: l10n.valReviewNeeded,
              section: w.section,
            ),
          );
        }
      }
    }

    // If still empty, add default message
    return issues.take(4).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final issues = _extractPriorityIssues(l10n);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Icon(
                    Icons.flag_outlined,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  Text(
                    l10n.priorityImprovementsTitle,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontFamily: 'Manrope',
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: issues.isEmpty
                      ? AppColors.green50
                      : const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  issues.isEmpty
                      ? l10n.priorityNoneRequired
                      : l10n.priorityIssuesCount(issues.length),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: issues.isEmpty
                        ? AppColors.green700
                        : const Color(0xFFB45309),
                    fontFamily: 'Manrope',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (issues.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.green50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: AppColors.green700,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.priorityNoMismatch,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.green700,
                        fontFamily: 'Manrope',
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: issues.asMap().entries.map((entry) {
                final idx = entry.key + 1;
                final issue = entry.value;
                final priorityUpper = issue.priority.toUpperCase();
                final isHigh =
                    priorityUpper == 'HIGH' || priorityUpper == 'CRITICAL';
                final isMedium = priorityUpper == 'MEDIUM';

                // Soft semantic color hierarchy:
                // High: subtle warm red background, neutral border, semantic red accent bar & badges
                // Medium: subtle warm amber background, neutral border, muted amber accent bar & badges
                // Low: neutral slate background, light border, muted slate accent bar & badges
                final Color cardBg;
                final Color cardBorder;
                final Color accentColor;
                final Color badgeBg;
                final Color badgeText;
                final Color circleBg;
                final Color circleText;
                final Color devColor;

                if (isHigh) {
                  cardBg = const Color(0xFFFFF8F7);
                  cardBorder = const Color(0xFFE8EDEF);
                  accentColor = const Color(0xFFDC4C3E);
                  badgeBg = const Color(0xFFFFECEB);
                  badgeText = const Color(0xFFDC4C3E);
                  circleBg = const Color(0xFFFFECEB);
                  circleText = const Color(0xFFDC4C3E);
                  devColor = const Color(0xFFDC4C3E);
                } else if (isMedium) {
                  cardBg = const Color(0xFFFFFBF3);
                  cardBorder = const Color(0xFFE8EDEF);
                  accentColor = const Color(0xFFD97706);
                  badgeBg = const Color(0xFFFEF3C7);
                  badgeText = const Color(0xFFD97706);
                  circleBg = const Color(0xFFFEF3C7);
                  circleText = const Color(0xFFD97706);
                  devColor = const Color(0xFFD97706);
                } else {
                  cardBg = const Color(0xFFF7FAFC);
                  cardBorder = const Color(0xFFE5EAF0);
                  accentColor = const Color(0xFF64748B);
                  badgeBg = const Color(0xFFF1F5F9);
                  badgeText = const Color(0xFF475569);
                  circleBg = const Color(0xFFE2E8F0);
                  circleText = const Color(0xFF475569);
                  devColor = const Color(0xFF64748B);
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: cardBorder),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(width: 3.5, color: accentColor),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: circleBg,
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        '$idx',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: circleText,
                                          fontFamily: 'Manrope',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Wrap(
                                        alignment: WrapAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        spacing: 8,
                                        runSpacing: 4,
                                        children: [
                                          Wrap(
                                            spacing: 6,
                                            crossAxisAlignment:
                                                WrapCrossAlignment.center,
                                            children: [
                                              Text(
                                                issue.title,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.textPrimary,
                                                  fontFamily: 'Manrope',
                                                ),
                                              ),
                                              if (issue.section != null)
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 5,
                                                        vertical: 1.5,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                    border: Border.all(
                                                      color: const Color(
                                                        0xFFE2E8F0,
                                                      ),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    issue.section!,
                                                    style: const TextStyle(
                                                      fontSize: 9,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: AppColors
                                                          .textSecondary,
                                                      fontFamily: 'Manrope',
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: badgeBg,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              l10n.priorityBadge(
                                                issue.priority,
                                              ),
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w800,
                                                color: badgeText,
                                                fontFamily: 'Manrope',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  issue.description,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                    fontFamily: 'Manrope',
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  alignment: WrapAlignment.spaceBetween,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: [
                                        _buildMetricChip(
                                          l10n.manuscriptMetricPrefix(
                                            issue.manuscriptValue,
                                          ),
                                          isJournal: false,
                                        ),
                                        _buildMetricChip(
                                          l10n.journalMetricPrefix(
                                            issue.journalValue,
                                          ),
                                          isJournal: true,
                                        ),
                                      ],
                                    ),
                                    Text(
                                      issue.deviation,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: devColor,
                                        fontFamily: 'Manrope',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildMetricChip(String text, {required bool isJournal}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isJournal ? const Color(0xFFF1F5F9) : Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: isJournal ? FontWeight.w500 : FontWeight.w700,
          color: isJournal ? const Color(0xFF475569) : AppColors.textPrimary,
          fontFamily: 'Manrope',
        ),
      ),
    );
  }
}
