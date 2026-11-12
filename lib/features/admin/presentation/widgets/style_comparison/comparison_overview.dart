import '../../../../../core/localization/app_localizations.dart';

import 'package:material_ui/material_ui.dart';

import '../../../../../../app/theme/app_colors.dart';

import 'dart:math' as math;

class ComparisonOverview extends StatelessWidget {
  final List<Map<String, dynamic>> profiles;
  final List<Color> colors;

  const ComparisonOverview({
    super.key,
    required this.profiles,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    if (profiles.isEmpty) return const SizedBox.shrink();

    // Key Metrics to display
    final metrics = [
      _buildMetricConfig(
        context.l10n.metricSentenceLength,
        'mean_length',
        context.l10n.unitWordsPerSentence,
        true,
      ),
      _buildMetricConfig(
        context.l10n.metricLexicalDensity,
        'lexical_density',
        '%',
        false,
        isPercent: true,
      ),
      _buildMetricConfig(
        context.l10n.metricHedges,
        'hedges_per_1k',
        context.l10n.unitPer1kWords,
        true,
      ),
      _buildMetricConfig(
        context.l10n.metricBoosters,
        'boosters_per_1k',
        context.l10n.unitPer1kWords,
        true,
      ),
      _buildMetricConfig(
        context.l10n.metricNeutralStance,
        'neutral',
        '%',
        false,
        isStance: true,
        isPercent: true,
      ),
      _buildMetricConfig(
        context.l10n.metricCarsCoverage,
        'cars',
        '%',
        false,
        isCars: true,
        isPercent: true,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.comparisonOverviewTitle,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontFamily: 'Manrope',
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth < 600
                ? 1
                : constraints.maxWidth < 900
                ? 2
                : 3;
            final width =
                (constraints.maxWidth - (crossAxisCount - 1) * 16) /
                crossAxisCount;

            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: metrics.map((config) {
                return SizedBox(width: width, child: _buildMetricCard(config));
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Map<String, dynamic> _buildMetricConfig(
    String title,
    String key,
    String unit,
    bool lowerIsBetter, {
    bool isPercent = false,
    bool isStance = false,
    bool isCars = false,
  }) {
    return {
      'title': title,
      'key': key,
      'unit': unit,
      'isPercent': isPercent,
      'isStance': isStance,
      'isCars': isCars,
    };
  }

  Widget _buildMetricCard(Map<String, dynamic> config) {
    final title = config['title'] as String;
    final key = config['key'] as String;
    final unit = config['unit'] as String;
    final isPercent = config['isPercent'] as bool;
    final isStance = config['isStance'] as bool;
    final isCars = config['isCars'] as bool;

    List<double> values = profiles.map((p) {
      if (isStance) {
        final stance = p['stance'] as Map<String, dynamic>?;
        return (stance?[key] as num?)?.toDouble() ?? 0.0;
      } else if (isCars) {
        final moves = p['cars_moves'] as Map<String, dynamic>?;
        final m1 = (moves?['territory'] as num?)?.toDouble() ?? 0.0;
        final m2 = (moves?['niche'] as num?)?.toDouble() ?? 0.0;
        final m3 = (moves?['occupying'] as num?)?.toDouble() ?? 0.0;
        return (m1 + m2 + m3) / 3.0;
      } else {
        final m = p['sentence_metrics'] as Map<String, dynamic>?;
        return (m?[key] as num?)?.toDouble() ?? 0.0;
      }
    }).toList();

    double maxVal = values.reduce(math.max);
    double minVal = values.reduce(math.min);

    // Fallback for visual scale max to avoid dividing by zero or filling 100% when shouldn't
    double scaleMax = maxVal == 0 ? 1 : maxVal * 1.2;
    if (isPercent) scaleMax = 1.0; // percentages max is 1 (100%)

    String formatVal(double v) {
      if (isPercent) return (v * 100).toStringAsFixed(0);
      return v.toStringAsFixed(1);
    }

    String diffText = '';
    Color diffColor = AppColors.textMuted;

    if (profiles.length == 2) {
      double diff = values[1] - values[0];
      String sign = diff > 0 ? '+' : '';
      if (isPercent) {
        diffText = 'Δ $sign${(diff * 100).toStringAsFixed(1)}%';
      } else {
        diffText = 'Δ $sign${diff.toStringAsFixed(1)} $unit';
      }
      diffColor = diff.abs() > (isPercent ? 0.05 : maxVal * 0.1)
          ? AppColors.primary
          : AppColors.textMuted; // highlight if diff > 10%
    } else if (profiles.length == 3) {
      double maxDiff = maxVal - minVal;
      if (isPercent) {
        diffText = 'Max Δ ${(maxDiff * 100).toStringAsFixed(1)}%';
      } else {
        diffText = 'Max Δ ${maxDiff.toStringAsFixed(1)} $unit';
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink900.withAlpha(4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontFamily: 'Manrope',
                ),
              ),
              if (profiles.length > 1)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: diffColor.withAlpha(15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    diffText,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: diffColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Mini visual
          Column(
            children: List.generate(profiles.length, (index) {
              final val = values[index];
              final wFactor = scaleMax == 0
                  ? 0.0
                  : (val / scaleMax).clamp(0.0, 1.0);
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 12,
                      child: Text(
                        'J${index + 1}',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: colors[index],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, c) {
                          return Stack(
                            children: [
                              Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceSoft,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              Container(
                                height: 6,
                                width: c.maxWidth * wFactor,
                                decoration: BoxDecoration(
                                  color: colors[index],
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 40,
                      child: Text(
                        '${formatVal(val)}${isPercent ? '%' : ''}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
