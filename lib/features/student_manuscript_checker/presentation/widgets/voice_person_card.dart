import 'package:material_ui/material_ui.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/entities/voice_person_comparison.dart';

class VoicePersonCard extends StatelessWidget {
  final VoicePersonComparison? comparison;

  const VoicePersonCard({super.key, required this.comparison});

  @override
  Widget build(BuildContext context) {
    if (comparison == null) return const SizedBox.shrink();

    final comp = comparison!;
    final passiveDiff = comp.userPassiveRate - comp.journalPassiveRate;
    final weDiff = comp.userWeRate - comp.journalWeRate;

    return Container(
      width: double.infinity,
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
                Icons.record_voice_over_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              Text(
                'Voice & Person Comparison',
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

          // 1. Passive Voice Comparison Bar
          _buildPairedComparison(
            title: 'Passive Voice Rate',
            subtitle: 'E.g., "was evaluated", "were observed", "is analyzed"',
            userRate: comp.userPassiveRate,
            journalRate: comp.journalPassiveRate,
            diffPp: passiveDiff,
            maxScale: 50.0, // 50% max scale
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.borderSoft),
          const SizedBox(height: 16),

          // 2. Author Person ("We") Comparison Bar
          _buildPairedComparison(
            title: 'Author Person ("We / Our")',
            subtitle: 'E.g., "we propose", "in our study", "we demonstrate"',
            userRate: comp.userWeRate,
            journalRate: comp.journalWeRate,
            diffPp: weDiff,
            maxScale: 15.0, // 15% max scale
          ),
        ],
      ),
    );
  }

  Widget _buildPairedComparison({
    required String title,
    required String subtitle,
    required double userRate,
    required double journalRate,
    required double diffPp,
    required double maxScale,
  }) {
    final absDiff = diffPp.abs();
    final isAuthor = title.contains('Author');
    final isMajor = isAuthor ? absDiff > 3.0 : absDiff > 15.0;
    final isModerate = (isAuthor ? absDiff > 1.5 : absDiff > 8.0) && !isMajor;

    Color statusColor = AppColors.green700;
    Color statusBg = AppColors.green50;
    String statusLabel = 'Aligned with journal';

    if (isMajor) {
      statusColor = AppColors.red700;
      statusBg = AppColors.red50;
      statusLabel = 'Major mismatch';
    } else if (isModerate) {
      statusColor = const Color(0xFFD97706);
      statusBg = const Color(0xFFFFFBEB);
      statusLabel = 'Moderate deviation';
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
                  '${diffPp >= 0 ? "+" : ""}${diffPp.toStringAsFixed(1)} pp',
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
                    statusLabel,
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
              width: 44,
              child: Text(
                '${userRate.toStringAsFixed(1)}%',
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
              width: 44,
              child: Text(
                '${journalRate.toStringAsFixed(1)}%',
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
