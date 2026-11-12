import 'package:material_ui/material_ui.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/entities/warning_item.dart';

class MovePipelineStep {
  final String title;
  final String section;
  final bool isMissing;
  final bool isWeak;
  final String? warningMessage;

  const MovePipelineStep({
    required this.title,
    required this.section,
    required this.isMissing,
    required this.isWeak,
    this.warningMessage,
  });
}

class RhetoricalMoveCard extends StatelessWidget {
  final List<WarningItem> moveWarnings;
  final int totalSections;

  const RhetoricalMoveCard({
    super.key,
    required this.moveWarnings,
    required this.totalSections,
  });

  List<MovePipelineStep> _buildPipeline() {
    final hasGapWarning = moveWarnings.any((w) => w.isGapWarning);
    final hasContributionWarning = moveWarnings.any(
      (w) => w.title.toLowerCase().contains('contribution'),
    );
    final hasMethodWarning = moveWarnings.any(
      (w) => w.title.toLowerCase().contains('method'),
    );
    final hasResultsWarning = moveWarnings.any(
      (w) => w.title.toLowerCase().contains('result'),
    );
    final hasDiscussionWarning = moveWarnings.any(
      (w) =>
          w.title.toLowerCase().contains('implication') ||
          w.title.toLowerCase().contains('discussion'),
    );

    return [
      const MovePipelineStep(
        title: 'Problem Framing',
        section: 'INTRO',
        isMissing: false,
        isWeak: false,
      ),
      MovePipelineStep(
        title: 'Research Gap',
        section: 'INTRO',
        isMissing: hasGapWarning,
        isWeak: false,
        warningMessage: hasGapWarning
            ? 'Missing explicit research limitation or knowledge gap.'
            : null,
      ),
      MovePipelineStep(
        title: 'Contribution',
        section: 'INTRO',
        isMissing: hasContributionWarning,
        isWeak: false,
      ),
      MovePipelineStep(
        title: 'Methodology',
        section: 'METHODS',
        isMissing: hasMethodWarning,
        isWeak: false,
      ),
      MovePipelineStep(
        title: 'Results Positioning',
        section: 'RESULTS',
        isMissing: false,
        isWeak: hasResultsWarning,
      ),
      MovePipelineStep(
        title: 'Implications',
        section: 'DISC',
        isMissing: hasDiscussionWarning,
        isWeak: false,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final pipeline = _buildPipeline();
    final missingCount = pipeline.where((s) => s.isMissing).length;

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
                    Icons.account_tree_outlined,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  Text(
                    'Rhetorical Move Analysis',
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
                  color: missingCount == 0
                      ? AppColors.green50
                      : AppColors.red50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  missingCount == 0
                      ? 'All Moves Satisfied'
                      : '$missingCount Missing Move${missingCount > 1 ? "s" : ""}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: missingCount == 0
                        ? AppColors.green700
                        : AppColors.red700,
                    fontFamily: 'Manrope',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Horizontal Segmented Pipeline
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 600;

              if (isNarrow) {
                return Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: pipeline
                      .map((step) => _buildMoveChip(step))
                      .toList(),
                );
              }

              return Row(
                children: pipeline.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final step = entry.value;
                  final isLast = idx == pipeline.length - 1;

                  return Expanded(
                    child: Row(
                      children: [
                        Expanded(child: _buildPipelineNode(step)),
                        if (!isLast)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 2),
                            child: Icon(
                              Icons.chevron_right_rounded,
                              size: 14,
                              color: AppColors.textSubtle,
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),

          if (moveWarnings.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.red50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.red100),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 16,
                    color: AppColors.red700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      moveWarnings.first.message,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.red700,
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPipelineNode(MovePipelineStep step) {
    Color bg = AppColors.green50;
    Color border = AppColors.green100;
    Color fg = AppColors.green700;
    IconData icon = Icons.check_circle_rounded;

    if (step.isMissing) {
      bg = AppColors.red50;
      border = AppColors.red100;
      fg = AppColors.red700;
      icon = Icons.cancel_rounded;
    } else if (step.isWeak) {
      bg = const Color(0xFFFFFBEB);
      border = const Color(0xFFFDE68A);
      fg = const Color(0xFFD97706);
      icon = Icons.error_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(height: 4),
          Text(
            step.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: fg,
              fontFamily: 'Manrope',
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            step.section,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w800,
              color: fg.withValues(alpha: 0.7),
              fontFamily: 'Manrope',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoveChip(MovePipelineStep step) {
    Color bg = AppColors.green50;
    Color fg = AppColors.green700;
    IconData icon = Icons.check_circle_rounded;

    if (step.isMissing) {
      bg = AppColors.red50;
      fg = AppColors.red700;
      icon = Icons.cancel_rounded;
    } else if (step.isWeak) {
      bg = const Color(0xFFFFFBEB);
      fg = const Color(0xFFD97706);
      icon = Icons.error_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              step.title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: fg,
                fontFamily: 'Manrope',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
