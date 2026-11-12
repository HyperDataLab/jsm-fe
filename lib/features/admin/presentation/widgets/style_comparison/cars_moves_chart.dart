import '../../../../../core/localization/app_localizations.dart';

import 'package:material_ui/material_ui.dart';

import '../../../../../../app/theme/app_colors.dart';

class CarsMovesChart extends StatelessWidget {
  final List<Map<String, dynamic>> profiles;
  final List<Color> colors;

  const CarsMovesChart({
    super.key,
    required this.profiles,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    if (profiles.isEmpty) return const SizedBox.shrink();

    final movesConfig = [
      {
        'title': context.l10n.move1Title,
        'sub': context.l10n.move1Sub,
        'key': 'territory',
      },
      {
        'title': context.l10n.move2Title,
        'sub': context.l10n.move2Sub,
        'key': 'niche',
      },
      {
        'title': context.l10n.move3Title,
        'sub': context.l10n.move3Sub,
        'key': 'occupying',
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
                Icons.account_tree_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              SizedBox(width: 8),
              Text(
                context.l10n.carsMovesChartTitle,
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
            context.l10n.carsMovesSubtitle,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
              fontFamily: 'Manrope',
            ),
          ),
          const SizedBox(height: 20),

          // Grouped Bars
          ...movesConfig.map((cfg) {
            final key = cfg['key'] as String;
            final title = cfg['title'] as String;
            final sub = cfg['sub'] as String;

            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
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
                        ),
                      ),
                      Text(
                        sub,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...profiles.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final p = entry.value;
                    final col = colors[idx % colors.length];
                    final name = p['journal_name'] ?? 'Tạp chí';
                    final moves = p['cars_moves'] as Map<String, dynamic>?;
                    final val = (moves?[key] as num?)?.toDouble() ?? 0.8;
                    final pct = (val * 100).toInt();

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
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
                                      fontSize: 11.5,
                                      color: AppColors.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: val.clamp(0.0, 1.0),
                                minHeight: 12,
                                backgroundColor: AppColors.surfaceSoft,
                                valueColor: AlwaysStoppedAnimation<Color>(col),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 40,
                            child: Text(
                              '$pct%',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: col,
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
          }),
        ],
      ),
    );
  }
}
