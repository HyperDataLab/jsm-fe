import 'package:material_ui/material_ui.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../domain/entities/warning_item.dart';

class WarningsListCard extends StatefulWidget {
  final List<WarningItem> warnings;

  const WarningsListCard({super.key, required this.warnings});

  @override
  State<WarningsListCard> createState() => _WarningsListCardState();
}

class _WarningsListCardState extends State<WarningsListCard> {
  final Set<String> _expandedIds = {};

  Color _severityColor(String severity) {
    switch (severity.toUpperCase()) {
      case 'CRITICAL':
        return AppColors.red700;
      case 'HIGH':
        return const Color(0xFFEA580C);
      case 'MEDIUM':
        return const Color(0xFFD97706);
      case 'LOW':
        return AppColors.blue600;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _severityBg(String severity) {
    switch (severity.toUpperCase()) {
      case 'CRITICAL':
        return AppColors.red50;
      case 'HIGH':
        return const Color(0xFFFFF7ED);
      case 'MEDIUM':
        return const Color(0xFFFFFBEB);
      case 'LOW':
        return AppColors.blue50;
      default:
        return AppColors.surfaceSoft;
    }
  }

  @override
  Widget build(BuildContext context) {
    final warnings = widget.warnings;

    if (warnings.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.all(20),
        child: const Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              color: AppColors.green700,
              size: 18,
            ),
            SizedBox(width: 8),
            Text(
              'No style or rhetorical warnings detected.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.green700,
                fontFamily: 'Manrope',
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              const Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Icon(
                    Icons.rule_folder_outlined,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  Text(
                    'Diagnostics & Validated Evidence',
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
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${warnings.length} items',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    fontFamily: 'Manrope',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Click an issue to inspect contextual explanations, benchmarks, and corpus exemplars.',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSubtle,
              fontFamily: 'Manrope',
            ),
          ),
          const SizedBox(height: 14),

          // List of Expandable Cards
          Column(
            children: warnings.map((warning) {
              final isExpanded = _expandedIds.contains(warning.id);
              final sevColor = _severityColor(warning.severity);
              final sevBg = _severityBg(warning.severity);
              final hasExemplar = warning.exemplar != null;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isExpanded ? AppColors.surfaceSoft : AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isExpanded
                        ? AppColors.primary.withValues(alpha: 0.3)
                        : AppColors.borderSoft,
                  ),
                ),
                child: Column(
                  children: [
                    // Header Bar (always visible)
                    InkWell(
                      onTap: () {
                        setState(() {
                          if (isExpanded) {
                            _expandedIds.remove(warning.id);
                          } else {
                            _expandedIds.add(warning.id);
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: sevBg,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                warning.severity,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: sevColor,
                                  fontFamily: 'Manrope',
                                ),
                              ),
                            ),
                            if (warning.section.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: AppColors.borderSoft,
                                  ),
                                ),
                                child: Text(
                                  warning.section,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSecondary,
                                    fontFamily: 'Manrope',
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                context.l10n.localizeAnalysisString(
                                  warning.title,
                                ),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                  fontFamily: 'Manrope',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(
                              isExpanded
                                  ? Icons.expand_less_rounded
                                  : Icons.expand_more_rounded,
                              size: 18,
                              color: AppColors.textSubtle,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Expanded Drawer Content
                    if (isExpanded) ...[
                      const Divider(height: 1, color: AppColors.borderSoft),
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.localizeAnalysisString(
                                warning.message,
                              ),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textPrimary,
                                fontFamily: 'Manrope',
                                height: 1.4,
                              ),
                            ),
                            if (hasExemplar) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.borderSoft,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(
                                          Icons.format_quote_rounded,
                                          size: 14,
                                          color: AppColors.primary,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Validated Journal Exemplar',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primary,
                                            fontFamily: 'Manrope',
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '“${warning.exemplar!.text}”',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontStyle: FontStyle.italic,
                                        color: AppColors.textPrimary,
                                        fontFamily: 'Manrope',
                                        height: 1.35,
                                      ),
                                    ),
                                    if (warning.exemplar!.articleTitle !=
                                            null ||
                                        warning.exemplar!.doi != null) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        [
                                          if (warning.exemplar!.articleTitle !=
                                              null)
                                            warning.exemplar!.articleTitle!,
                                          if (warning.exemplar!.doi != null)
                                            'DOI: ${warning.exemplar!.doi!}',
                                        ].join(' • '),
                                        style: const TextStyle(
                                          fontSize: 9,
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
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
