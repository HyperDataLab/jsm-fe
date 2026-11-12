import '../../../../../core/localization/app_localizations.dart';

import 'package:material_ui/material_ui.dart';

import '../../../../../../app/theme/app_colors.dart';

class StanceDistributionChart extends StatelessWidget {
  final List<Map<String, dynamic>> profiles;
  final List<Color> colors;

  const StanceDistributionChart({
    super.key,
    required this.profiles,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    if (profiles.isEmpty) return const SizedBox.shrink();

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
                    Icons.balance_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 8),
                  Text(
                    context.l10n.stanceDistributionTitle,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontFamily: 'Manrope',
                    ),
                  ),
                ],
              ),
              // Legend
              Row(
                children: [
                  _buildLegendItem(
                    context.l10n.stanceNeutral,
                    AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  _buildLegendItem(
                    context.l10n.stanceSupport,
                    AppColors.green700,
                  ),
                  const SizedBox(width: 12),
                  _buildLegendItem(context.l10n.stanceRefute, AppColors.red700),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.stanceDistributionSubtitle,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
              fontFamily: 'Manrope',
            ),
          ),
          const SizedBox(height: 20),

          // Stacked Bars per profile
          ...profiles.map((p) {
            final name = p['journal_name'] ?? 'Tạp chí';
            final stance = p['stance'] as Map<String, dynamic>?;

            final neutral = (stance?['neutral'] as num?)?.toDouble() ?? 0.70;
            final support = (stance?['support'] as num?)?.toDouble() ?? 0.20;
            final contradict =
                (stance?['contradict'] as num?)?.toDouble() ?? 0.10;

            final neuPct = (neutral * 100).round();
            final supPct = (support * 100).round();
            final conPct = (contradict * 100).round();

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 140,
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
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: SizedBox(
                        height: 20,
                        child: Row(
                          children: [
                            if (neuPct > 0)
                              Expanded(
                                flex: neuPct,
                                child: Tooltip(
                                  message:
                                      '$name: ${context.l10n.stanceNeutral} $neuPct%',
                                  child: Container(
                                    color: AppColors.primary,
                                    alignment: Alignment.center,
                                    child: neuPct >= 15
                                        ? Text(
                                            '$neuPct%',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                            if (supPct > 0)
                              Expanded(
                                flex: supPct,
                                child: Tooltip(
                                  message:
                                      '$name: ${context.l10n.stanceSupport} $supPct%',
                                  child: Container(
                                    color: AppColors.green700,
                                    alignment: Alignment.center,
                                    child: supPct >= 15
                                        ? Text(
                                            '$supPct%',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                            if (conPct > 0)
                              Expanded(
                                flex: conPct,
                                child: Tooltip(
                                  message:
                                      '$name: ${context.l10n.stanceRefute} $conPct%',
                                  child: Container(
                                    color: AppColors.red700,
                                    alignment: Alignment.center,
                                    child: conPct >= 15
                                        ? Text(
                                            '$conPct%',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                          ],
                        ),
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

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
