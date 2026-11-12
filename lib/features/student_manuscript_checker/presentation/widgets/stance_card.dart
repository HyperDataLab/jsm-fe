import 'package:material_ui/material_ui.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/entities/stance_comparison.dart';

class StanceCard extends StatelessWidget {
  final StanceComparison? comparison;

  const StanceCard({super.key, required this.comparison});

  @override
  Widget build(BuildContext context) {
    if (comparison == null) return const SizedBox.shrink();

    final comp = comparison!;
    final hedgeDiff = comp.hedgeRateDiff;
    final boosterDiff = comp.boosterRateDiff;

    return Container(
      constraints: const BoxConstraints(minHeight: 280),
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
          const Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(
                Icons.psychology_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              Text(
                'Stance & Epistemic Markers',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontFamily: 'Manrope',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 1. Hedges Paired Comparison (e.g. 0 - 30 /1k words)
          _buildStancePair(
            title: 'Epistemic Hedges',
            subtitle: 'E.g., "suggests", "may indicate", "likely"',
            userRate: comp.userHedgeRate,
            journalRate: comp.journalHedgeRate,
            diff: hedgeDiff,
            maxScale: 30.0,
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.borderSoft),
          const SizedBox(height: 16),

          // 2. Boosters Paired Comparison (e.g. 0 - 15 /1k words)
          _buildStancePair(
            title: 'Epistemic Boosters',
            subtitle: 'E.g., "clearly shows", "definitely", "proves"',
            userRate: comp.userBoosterRate,
            journalRate: comp.journalBoosterRate,
            diff: boosterDiff,
            maxScale: 15.0,
          ),
        ],
      ),
    );
  }

  Widget _buildStancePair({
    required String title,
    required String subtitle,
    required double userRate,
    required double journalRate,
    required double diff,
    required double maxScale,
  }) {
    final absDiff = diff.abs();
    final isMajor = (userRate == 0 && journalRate > 2.0) || absDiff > 4.0;
    final isModerate = absDiff > 2.0 && !isMajor;

    Color statusColor = AppColors.green700;
    Color statusBg = AppColors.green50;
    String statusBadge = '✓ Match';

    if (isMajor) {
      statusColor = AppColors.red700;
      statusBg = AppColors.red50;
      statusBadge = '!! Major mismatch';
    } else if (isModerate) {
      statusColor = const Color(0xFFD97706);
      statusBg = const Color(0xFFFFFBEB);
      statusBadge = '! Moderate deviation';
    }

    final userFraction = (userRate / maxScale).clamp(0.0, 1.0);
    final journalFraction = (journalRate / maxScale).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
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
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSubtle,
                    fontFamily: 'Manrope',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '${diff >= 0 ? "+" : ""}${diff.toStringAsFixed(1)} /1k',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                    fontFamily: 'Manrope',
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    statusBadge,
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
          ],
        ),
        const SizedBox(height: 8),

        // Manuscript Bar
        Row(
          children: [
            const SizedBox(
              width: 90,
              child: Text(
                'Manuscript',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  fontFamily: 'Manrope',
                ),
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: Container(
                  height: 10,
                  color: AppColors.surfaceSoft,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: userFraction,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isMajor ? AppColors.red700 : AppColors.primary,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 55,
              child: Text(
                '${userRate.toStringAsFixed(1)} /1k',
                textAlign: TextAlign.end,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  fontFamily: 'Manrope',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),

        // Journal Profile Bar
        Row(
          children: [
            const SizedBox(
              width: 90,
              child: Text(
                'Journal Median',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSubtle,
                  fontFamily: 'Manrope',
                ),
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: Container(
                  height: 10,
                  color: AppColors.surfaceSoft,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: journalFraction,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.slate400,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 55,
              child: Text(
                '${journalRate.toStringAsFixed(1)} /1k',
                textAlign: TextAlign.end,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                  fontFamily: 'Manrope',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
