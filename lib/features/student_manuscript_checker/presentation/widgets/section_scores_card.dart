import 'package:material_ui/material_ui.dart';

import '../../../../app/theme/app_colors.dart';

class SectionScoresCard extends StatelessWidget {
  final Map<String, double> sectionScores;

  const SectionScoresCard({super.key, required this.sectionScores});

  Color _getScoreColor(double score) {
    if (score >= 85) return AppColors.green700;
    if (score >= 75) return const Color(0xFFD97706);
    return AppColors.red700;
  }

  String _getScoreLabel(double score) {
    if (score >= 85) return 'Strong';
    if (score >= 75) return 'Acceptable';
    return 'Needs Attention';
  }

  @override
  Widget build(BuildContext context) {
    if (sectionScores.isEmpty) return const SizedBox.shrink();

    return Container(
      constraints: const BoxConstraints(minHeight: 255),
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
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              const Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Icon(
                    Icons.view_quilt_outlined,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  Text(
                    'Section Alignment Scores',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontFamily: 'Manrope',
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 2, height: 10, color: AppColors.textSubtle),
                  const SizedBox(width: 4),
                  const Text(
                    '85% Target Line',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSubtle,
                      fontFamily: 'Manrope',
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            children: sectionScores.entries.map((entry) {
              final sectionName = entry.key;
              final score = entry.value;
              final color = _getScoreColor(score);
              final label = _getScoreLabel(score);
              final progress = (score / 100.0).clamp(0.0, 1.0);
              final isWarning = score < 78.0;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 380;

                    if (isNarrow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                sectionName.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                  fontFamily: 'Manrope',
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    '${score.toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: color,
                                      fontFamily: 'Manrope',
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isWarning
                                          ? AppColors.red50
                                          : AppColors.surfaceSoft,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      label,
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: isWarning
                                            ? AppColors.red700
                                            : AppColors.textSecondary,
                                        fontFamily: 'Manrope',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Stack(
                            children: [
                              Container(
                                height: 10,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceSoft,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: progress,
                                child: Container(
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: constraints.maxWidth * 0.85,
                                top: 0,
                                bottom: 0,
                                child: Container(
                                  width: 1.5,
                                  color: Colors.black.withValues(alpha: 0.3),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        SizedBox(
                          width: 90,
                          child: Text(
                            sectionName.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              fontFamily: 'Manrope',
                            ),
                          ),
                        ),
                        Expanded(
                          child: Stack(
                            children: [
                              Container(
                                height: 12,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceSoft,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: progress,
                                child: Container(
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: constraints.maxWidth > 200
                                    ? (constraints.maxWidth - 200) * 0.85
                                    : 0,
                                top: 0,
                                bottom: 0,
                                child: Container(
                                  width: 1.5,
                                  color: Colors.black.withValues(alpha: 0.3),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 40,
                          child: Text(
                            '${score.toStringAsFixed(0)}%',
                            textAlign: TextAlign.end,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: color,
                              fontFamily: 'Manrope',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isWarning
                                ? AppColors.red50
                                : AppColors.surfaceSoft,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: isWarning
                                  ? AppColors.red700
                                  : AppColors.textSecondary,
                              fontFamily: 'Manrope',
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
