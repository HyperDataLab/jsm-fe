import 'package:material_ui/material_ui.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/entities/sentence_length_comparison.dart';

class SentenceLengthCard extends StatelessWidget {
  final SentenceLengthComparison? comparison;

  const SentenceLengthCard({super.key, required this.comparison});

  @override
  Widget build(BuildContext context) {
    if (comparison == null) return const SizedBox.shrink();

    final comp = comparison!;
    final userVal = comp.userMedian;
    final journalMed = comp.journalMedian;
    final p10 = comp.journalP10 > 0 ? comp.journalP10 : 12.0;
    final p90 = comp.journalP90 > 0 ? comp.journalP90 : 34.0;
    final maxScale = (p90 + 10).clamp(35.0, 60.0);

    final isWithin = comp.isWithinRange;
    final statusColor = isWithin
        ? AppColors.green700
        : comp.isTooShort
        ? const Color(0xFFD97706)
        : AppColors.red700;
    final statusBg = isWithin
        ? AppColors.green50
        : comp.isTooShort
        ? const Color(0xFFFFFBEB)
        : AppColors.red50;

    String qualitativeStatus;
    if (userVal >= p10 && userVal <= p90) {
      if ((userVal - journalMed).abs() <= 3.0) {
        qualitativeStatus = 'Closely matches journal median sentence pacing.';
      } else if (userVal < journalMed) {
        qualitativeStatus = 'Within expected range, but shorter than typical journal sentences.';
      } else {
        qualitativeStatus =
            'Within expected range, with slightly longer syntactic periods.';
      }
    } else if (userVal < p10) {
      qualitativeStatus =
          'Significantly shorter sentences than journal standard (P10: ${p10.toStringAsFixed(0)} words).';
    } else {
      qualitativeStatus =
          'Excessively long sentences exceeding journal P90 threshold (${p90.toStringAsFixed(0)} words).';
    }

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
                    Icons.straighten_outlined,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  Text(
                    'Sentence Length Analysis',
                    style: TextStyle(
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
                  color: statusBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  comp.statusDisplayLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                    fontFamily: 'Manrope',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Bullet Range Chart
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final p10X = (p10 / maxScale) * width;
              final p90X = (p90 / maxScale) * width;
              final userX = ((userVal / maxScale) * width).clamp(
                6.0,
                width - 6.0,
              );
              final journalX = ((journalMed / maxScale) * width).clamp(
                6.0,
                width - 6.0,
              );

              return Column(
                children: [
                  SizedBox(
                    height: 48,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.centerLeft,
                      children: [
                        // Base ruler track
                        Positioned(
                          left: 0,
                          right: 0,
                          top: 20,
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSoft,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                        // Journal Expected P10-P90 Range Band
                        Positioned(
                          left: p10X,
                          width: (p90X - p10X).clamp(10.0, width),
                          top: 17,
                          child: Container(
                            height: 12,
                            decoration: BoxDecoration(
                              color: AppColors.blue100.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                        ),
                        // Journal Median Diamond Indicator
                        Positioned(
                          left: journalX - 5,
                          top: 18,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: AppColors.slate600,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            transform: Matrix4.rotationZ(
                              0.785398,
                            ), // 45 deg diamond
                          ),
                        ),
                        // Manuscript Dot Indicator
                        Positioned(
                          left: userX - 7,
                          top: 16,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Axis Ticks
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '0',
                        style: TextStyle(
                          fontSize: 9,
                          color: AppColors.textSubtle,
                          fontFamily: 'Manrope',
                        ),
                      ),
                      Text(
                        width < 320
                            ? p10.toStringAsFixed(0)
                            : 'P10 (${p10.toStringAsFixed(0)})',
                        style: const TextStyle(
                          fontSize: 9,
                          color: AppColors.textSubtle,
                          fontFamily: 'Manrope',
                        ),
                      ),
                      Text(
                        width < 320
                            ? 'Med ${journalMed.toStringAsFixed(0)}'
                            : 'Median (${journalMed.toStringAsFixed(1)})',
                        style: const TextStyle(
                          fontSize: 9,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Manrope',
                        ),
                      ),
                      Text(
                        width < 320
                            ? p90.toStringAsFixed(0)
                            : 'P90 (${p90.toStringAsFixed(0)})',
                        style: const TextStyle(
                          fontSize: 9,
                          color: AppColors.textSubtle,
                          fontFamily: 'Manrope',
                        ),
                      ),
                      Text(
                        width < 320
                            ? maxScale.toStringAsFixed(0)
                            : '${maxScale.toStringAsFixed(0)} w',
                        style: const TextStyle(
                          fontSize: 9,
                          color: AppColors.textSubtle,
                          fontFamily: 'Manrope',
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 14),

          // Value strip and contextual interpretation
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Wrap(
              spacing: 14,
              runSpacing: 8,
              children: [
                _buildMetricSnippet(
                  'Manuscript',
                  '${userVal.toStringAsFixed(1)} words',
                  AppColors.primary,
                ),
                _buildMetricSnippet(
                  'Journal Median',
                  '${journalMed.toStringAsFixed(1)} words',
                  AppColors.slate600,
                ),
                _buildMetricSnippet(
                  'Band',
                  '${p10.toStringAsFixed(0)}–${p90.toStringAsFixed(0)} words',
                  AppColors.textSecondary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            qualitativeStatus,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
              fontFamily: 'Manrope',
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricSnippet(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: AppColors.textSubtle,
            fontFamily: 'Manrope',
          ),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: color,
            fontFamily: 'Manrope',
          ),
        ),
      ],
    );
  }
}
