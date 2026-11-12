import '../../../../../core/localization/app_localizations.dart';

import 'package:material_ui/material_ui.dart';

import '../../../../../../app/theme/app_colors.dart';

import 'dart:math' as math;

class MetricDifferencesDumbbellChart extends StatefulWidget {
  final List<Map<String, dynamic>> profiles;
  final List<Color> colors;

  const MetricDifferencesDumbbellChart({
    super.key,
    required this.profiles,
    required this.colors,
  });

  @override
  State<MetricDifferencesDumbbellChart> createState() =>
      _MetricDifferencesDumbbellChartState();
}

class _MetricDifferencesDumbbellChartState
    extends State<MetricDifferencesDumbbellChart> {
  bool _sortByDifference = true;

  @override
  Widget build(BuildContext context) {
    if (widget.profiles.length < 2) {
      return const SizedBox.shrink(); // Dumbbell chart requires at least 2 profiles to compare
    }

    final configs = [
      _buildConfig(
        context.l10n.sentenceLengthLabel,
        'mean_length',
        context.l10n.unitWordsPerSentence,
        false,
      ),
      _buildConfig(
        context.l10n.lexicalDensityLabel,
        'lexical_density',
        '%',
        true,
      ),
      _buildConfig(
        context.l10n.hedgingLabel,
        'hedges_per_1k',
        context.l10n.unitPer1kWords,
        false,
      ),
      _buildConfig(
        context.l10n.boostersLabel,
        'boosters_per_1k',
        context.l10n.unitPer1kWords,
        false,
      ),
      _buildConfig(
        context.l10n.neutralStanceLabel,
        'neutral',
        '%',
        true,
        isStance: true,
      ),
    ];

    // Compute values
    final rows = configs.map((config) {
      final key = config['key'] as String;
      final isStance = config['isStance'] as bool;

      List<double> values = widget.profiles.map((p) {
        if (isStance) {
          final stance = p['stance'] as Map<String, dynamic>?;
          return (stance?[key] as num?)?.toDouble() ?? 0.0;
        } else {
          final m = p['sentence_metrics'] as Map<String, dynamic>?;
          return (m?[key] as num?)?.toDouble() ?? 0.0;
        }
      }).toList();

      final maxVal = values.reduce(math.max);
      final minVal = values.reduce(math.min);
      final diff = maxVal - minVal;

      return {
        'config': config,
        'values': values,
        'diff': diff,
        'maxVal': maxVal,
        'minVal': minVal,
      };
    }).toList();

    if (_sortByDifference) {
      // Normalize difference to sort logically: we can sort by raw diff for percentages and proportional diff for counts
      rows.sort((a, b) {
        final confA = a['config'] as Map<String, dynamic>;
        final confB = b['config'] as Map<String, dynamic>;

        final diffA = a['diff'] as double;
        final maxA = (a['maxVal'] as double) == 0
            ? 1.0
            : (a['maxVal'] as double);
        final scoreA = confA['isPercent'] ? diffA : (diffA / maxA);

        final diffB = b['diff'] as double;
        final maxB = (b['maxVal'] as double) == 0
            ? 1.0
            : (b['maxVal'] as double);
        final scoreB = confB['isPercent'] ? diffB : (diffB / maxB);

        return scoreB.compareTo(scoreA); // descending
      });
    }

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.compare_arrows_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 8),
                  Text(
                    context.l10n.metricDifferencesTitle,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontFamily: 'Manrope',
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    context.l10n.sortLabel,
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  const SizedBox(width: 8),
                  SegmentedButton<bool>(
                    segments: [
                      ButtonSegment(
                        value: true,
                        label: Text(context.l10n.largestSort),
                      ),
                      ButtonSegment(
                        value: false,
                        label: Text(context.l10n.defaultSort),
                      ),
                    ],
                    selected: {_sortByDifference},
                    onSelectionChanged: (set) {
                      setState(() {
                        _sortByDifference = set.first;
                      });
                    },
                    style: SegmentedButton.styleFrom(
                      textStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Manrope',
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...rows.map((row) => _buildDumbbellRow(row)),
        ],
      ),
    );
  }

  Map<String, dynamic> _buildConfig(
    String title,
    String key,
    String unit,
    bool isPercent, {
    bool isStance = false,
  }) {
    return {
      'title': title,
      'key': key,
      'unit': unit,
      'isPercent': isPercent,
      'isStance': isStance,
    };
  }

  Widget _buildDumbbellRow(Map<String, dynamic> rowData) {
    final config = rowData['config'] as Map<String, dynamic>;
    final values = rowData['values'] as List<double>;

    final title = config['title'] as String;
    final isPercent = config['isPercent'] as bool;

    final minVal = rowData['minVal'] as double;
    final maxVal = rowData['maxVal'] as double;

    // Scale computation
    final globalMax = maxVal == 0 ? 1.0 : maxVal * 1.2;
    final globalMin = minVal == 0 ? 0.0 : minVal * 0.8;

    String formatVal(double v) =>
        isPercent ? '${(v * 100).toStringAsFixed(0)}%' : v.toStringAsFixed(1);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
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
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Δ ${formatVal(maxVal - minVal)}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 24,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;

                // Helper to get X coordinate
                double getX(double v) {
                  if (globalMax == globalMin) return width / 2;
                  if (isPercent) {
                    return width * v; // 0 to 100% scale for percentages
                  }
                  return width * ((v - globalMin) / (globalMax - globalMin));
                }

                // Collect points
                List<Map<String, dynamic>> points = [];
                for (int i = 0; i < values.length; i++) {
                  points.add({
                    'val': values[i],
                    'color': widget.colors[i],
                    'index': i,
                  });
                }

                points.sort(
                  (a, b) => (a['val'] as double).compareTo(b['val'] as double),
                );

                final lineStart = getX(points.first['val']);
                final lineEnd = getX(points.last['val']);

                return Stack(
                  alignment: Alignment.centerLeft,
                  clipBehavior: Clip.none,
                  children: [
                    // Background grid line
                    Positioned(
                      left: 0,
                      right: 0,
                      child: Container(height: 1, color: AppColors.borderSoft),
                    ),

                    // Connecting Line
                    if (points.length > 1)
                      Positioned(
                        left: lineStart,
                        width: lineEnd - lineStart,
                        child: Container(
                          height: 2,
                          color: AppColors.textSubtle.withAlpha(80),
                        ),
                      ),

                    // Dots
                    ...points.map((pt) {
                      final val = pt['val'] as double;
                      final col = pt['color'] as Color;
                      final x = getX(val);

                      return Positioned(
                        left: x - 6, // center dot
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: col,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.surface,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: col.withAlpha(100),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                    // Labels for Min and Max (prevent overlapping)
                    if (points.isNotEmpty) ...[
                      Positioned(
                        left: lineStart,
                        bottom: -18,
                        child: Transform.translate(
                          offset: const Offset(-10, 0),
                          child: Text(
                            formatVal(points.first['val']),
                            style: TextStyle(
                              fontSize: 10,
                              color: points.first['color'],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      if (points.length > 1)
                        Positioned(
                          left: lineEnd,
                          bottom: -18,
                          child: Transform.translate(
                            offset: const Offset(-10, 0),
                            child: Text(
                              formatVal(points.last['val']),
                              style: TextStyle(
                                fontSize: 10,
                                color: points.last['color'],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
