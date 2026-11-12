import 'package:material_ui/material_ui.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/entities/warning_item.dart';
import '../../../../core/localization/app_localizations.dart';

class MissingGapWarningCard extends StatelessWidget {
  final List<WarningItem> gapWarnings;

  const MissingGapWarningCard({super.key, required this.gapWarnings});

  @override
  Widget build(BuildContext context) {
    if (gapWarnings.isEmpty) return const SizedBox.shrink();

    final primaryGap = gapWarnings.first;
    final exemplar = primaryGap.exemplar;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.red50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.red100, width: 1.5),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.red700.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.assignment_late_rounded,
                  color: AppColors.red700,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          primaryGap.title.isNotEmpty
                              ? primaryGap.title
                              : context.l10n.missingResearchGapTitle,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.red700,
                            fontFamily: 'Manrope',
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.red700,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'CRITICAL MOVE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.5,
                              fontFamily: 'Manrope',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      primaryGap.message,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        fontFamily: 'Manrope',
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Actionable Advice: State clearly why existing works or methods are insufficient and how your study fills this limitation before presenting results.',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textSecondary,
                        fontFamily: 'Manrope',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Exemplar demonstration box
          if (exemplar != null) ...[
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.red100),
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.format_quote_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          context.l10n.publishedExemplar,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            fontFamily: 'Manrope',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (exemplar.doi != null && exemplar.doi!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'DOI: ${exemplar.doi}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                              fontFamily: 'Manrope',
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '“${exemplar.text}”',
                    style: const TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textPrimary,
                      fontFamily: 'Manrope',
                      height: 1.4,
                    ),
                  ),
                  if (exemplar.articleTitle != null &&
                      exemplar.articleTitle!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Source: ${exemplar.articleTitle}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSubtle,
                        fontFamily: 'Manrope',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
