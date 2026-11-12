import '../../../../../core/localization/app_localizations.dart';

import 'package:material_ui/material_ui.dart';

import '../../../../../../app/theme/app_colors.dart';

class StyleDifferenceMatrix extends StatelessWidget {
  final List<Map<String, dynamic>> profiles;
  final List<Color> colors;

  const StyleDifferenceMatrix({
    super.key,
    required this.profiles,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    if (profiles.isEmpty) return const SizedBox.shrink();

    final rows = [
      {
        'title': context.l10n.sentenceLengthLabel,
        'key': 'mean_length',
        'unit': context.l10n.unitWords,
        'type': 'metric',
      },
      {
        'title': context.l10n.lexicalDensityLabel,
        'key': 'lexical_density',
        'unit': '%',
        'type': 'metric',
        'pct': true,
      },
      {
        'title': context.l10n.hedgingLabel,
        'key': 'hedges_per_1k',
        'unit': '/1k',
        'type': 'metric',
      },
      {
        'title': context.l10n.boostersLabel,
        'key': 'boosters_per_1k',
        'unit': '/1k',
        'type': 'metric',
      },
      {
        'title': context.l10n.neutralStanceLabel,
        'key': 'neutral',
        'unit': '%',
        'type': 'stance',
        'pct': true,
      },
      {
        'title': context.l10n.move1Title,
        'key': 'territory',
        'unit': '%',
        'type': 'cars',
        'pct': true,
      },
      {
        'title': context.l10n.move2Title,
        'key': 'niche',
        'unit': '%',
        'type': 'cars',
        'pct': true,
      },
      {
        'title': context.l10n.move3Title,
        'key': 'occupying',
        'unit': '%',
        'type': 'cars',
        'pct': true,
      },
    ];

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
                Icons.grid_on_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                context.l10n.styleMatrixTitle,
                style: const TextStyle(
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
            context.l10n.styleMatrixSubtitle,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
              fontFamily: 'Manrope',
            ),
          ),
          const SizedBox(height: 20),

          // Table Header
          Table(
            border: TableBorder.all(
              color: AppColors.borderSoft,
              borderRadius: BorderRadius.circular(8),
            ),
            columnWidths: {
              0: const FlexColumnWidth(2.2),
              for (int i = 0; i < profiles.length; i++)
                i + 1: const FlexColumnWidth(1.2),
            },
            children: [
              // Header row
              TableRow(
                decoration: const BoxDecoration(color: AppColors.surfaceSoft),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Text(
                      context.l10n.referenceMetric,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  ...profiles.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final p = entry.value;
                    final col = colors[idx % colors.length];
                    final name = p['journal_name'] ?? 'Tạp chí';

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
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
                          Flexible(
                            child: Text(
                              name,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: col,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),

              // Metric rows
              ...rows.map((row) {
                final key = row['key'] as String;
                final type = row['type'] as String;
                final isPct = (row['pct'] as bool?) ?? false;
                final unit = row['unit'] as String;

                // Extract all values for this row to compute relative intensity
                List<double> vals = profiles.map((p) {
                  if (type == 'stance') {
                    final s = p['stance'] as Map<String, dynamic>?;
                    return (s?[key] as num?)?.toDouble() ?? 0.0;
                  } else if (type == 'cars') {
                    final c = p['cars_moves'] as Map<String, dynamic>?;
                    return (c?[key] as num?)?.toDouble() ?? 0.0;
                  } else {
                    final m = p['sentence_metrics'] as Map<String, dynamic>?;
                    return (m?[key] as num?)?.toDouble() ?? 0.0;
                  }
                }).toList();

                double maxV = vals.reduce((a, b) => a > b ? a : b);
                if (maxV == 0) maxV = 1.0;

                return TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Text(
                        row['title'] as String,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    ...vals.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final val = entry.value;
                      final col = colors[idx % colors.length];

                      final intensity = isPct
                          ? val.clamp(0.0, 1.0)
                          : (val / maxV).clamp(0.1, 1.0);
                      final displayStr = isPct
                          ? '${(val * 100).toStringAsFixed(0)}%'
                          : '${val.toStringAsFixed(1)} $unit';

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                        color: col.withAlpha(
                          (intensity * 40).toInt() + 5,
                        ), // subtle tint
                        child: Center(
                          child: Text(
                            displayStr,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}
