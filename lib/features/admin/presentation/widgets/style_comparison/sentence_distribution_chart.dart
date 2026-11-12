import '../../../../../core/localization/app_localizations.dart';

import 'package:material_ui/material_ui.dart';

import '../../../../../../app/theme/app_colors.dart';

import 'dart:math' as math;

class SentenceDistributionChart extends StatelessWidget {
  final List<Map<String, dynamic>> profiles;
  final List<Color> colors;

  const SentenceDistributionChart({
    super.key,
    required this.profiles,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    if (profiles.isEmpty) return const SizedBox.shrink();

    // Find overall max p90 to scale
    double maxP90 = 40.0;
    for (var p in profiles) {
      final m = p['sentence_metrics'] as Map<String, dynamic>?;
      final p90 = (m?['p90'] as num?)?.toDouble() ?? 30.0;
      if (p90 > maxP90) maxP90 = p90;
    }
    maxP90 = maxP90 * 1.15; // padding

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink900.withAlpha(4),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.horizontal_distribute_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              SizedBox(width: 8),
              Text(
                context.l10n.sentenceDistributionTitle,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontFamily: 'Manrope',
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.sentenceDistributionSubtitle,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
              fontFamily: 'Manrope',
            ),
          ),
          const SizedBox(height: 20),

          // Axis scale header
          Row(
            children: [
              const SizedBox(width: 140), // Journal name width
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '0 ${context.l10n.unitWords}',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textSubtle,
                      ),
                    ),
                    Text(
                      '${(maxP90 / 2).toInt()} ${context.l10n.unitWords}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSubtle,
                      ),
                    ),
                    Text(
                      '${maxP90.toInt()} ${context.l10n.unitWords}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSubtle,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Whisker rows
          ...profiles.asMap().entries.map((entry) {
            final idx = entry.key;
            final p = entry.value;
            final col = colors[idx % colors.length];
            final name = p['journal_name'] ?? 'Tạp chí';
            final metrics = p['sentence_metrics'] as Map<String, dynamic>?;

            final p10 = (metrics?['p10'] as num?)?.toDouble() ?? 10.0;
            final p50 = (metrics?['p50'] as num?)?.toDouble() ?? 20.0;
            final p90 = (metrics?['p90'] as num?)?.toDouble() ?? 32.0;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 140,
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: col,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SizedBox(
                      height: 32,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final w = constraints.maxWidth;
                          final x10 = (p10 / maxP90) * w;
                          final x50 = (p50 / maxP90) * w;
                          final x90 = (p90 / maxP90) * w;

                          return Stack(
                            alignment: Alignment.centerLeft,
                            children: [
                              // Background track
                              Container(
                                height: 4,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceSoft,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              // Range bar (P10 to P90)
                              Positioned(
                                left: x10,
                                width: math.max(2, x90 - x10),
                                child: Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: col.withAlpha(40),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: col.withAlpha(120),
                                    ),
                                  ),
                                ),
                              ),
                              // Left cap P10
                              Positioned(
                                left: x10 - 1,
                                child: Container(
                                  width: 2,
                                  height: 14,
                                  color: col,
                                ),
                              ),
                              // Right cap P90
                              Positioned(
                                left: x90 - 1,
                                child: Container(
                                  width: 2,
                                  height: 14,
                                  color: col,
                                ),
                              ),
                              // Median Dot P50
                              Positioned(
                                left: x50 - 5,
                                child: Tooltip(
                                  message:
                                      '$name: P10=$p10 | P50=$p50 | P90=$p90',
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: col,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 70,
                    child: Text(
                      '${p10.toInt()}-${p50.toInt()}-${p90.toInt()}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
