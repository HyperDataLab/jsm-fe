import 'package:material_ui/material_ui.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/entities/analysis_pipeline_models.dart';
import '../cubit/student_manuscript_checker_state.dart';

class ManuscriptAnalysisLoadingView extends StatefulWidget {
  final StudentManuscriptCheckerLoading state;
  final VoidCallback? onRetry;

  const ManuscriptAnalysisLoadingView({
    super.key,
    required this.state,
    this.onRetry,
  });

  @override
  State<ManuscriptAnalysisLoadingView> createState() =>
      _ManuscriptAnalysisLoadingViewState();
}

class _ManuscriptAnalysisLoadingViewState
    extends State<ManuscriptAnalysisLoadingView>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.state.pipelineProgress;
    final journalTitle =
        widget.state.targetJournalTitle ?? 'Target Academic Journal';
    final fileName = widget.state.manuscriptFileName ?? 'Manuscript Draft';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Main Card
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Header & Title Block
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Analyzing Manuscript',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                fontFamily: 'Manrope',
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Comparing your manuscript against the target journal’s writing style and structural profile.',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                fontFamily: 'Manrope',
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: progress.isCompleted
                                ? AppColors.green50
                                : AppColors.blue50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: progress.isCompleted
                                  ? AppColors.green700.withValues(alpha: 0.3)
                                  : AppColors.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${progress.overallProgress}%',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: progress.isCompleted
                                      ? AppColors.green700
                                      : AppColors.primary,
                                  fontFamily: 'Manrope',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // 2. Metadata Chips (File + Target Journal)
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSoft,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.description_outlined,
                                size: 14,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 6),
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 240,
                                ),
                                child: Text(
                                  fileName,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                    fontFamily: 'Manrope',
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSoft,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.auto_stories_outlined,
                                size: 14,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 320,
                                ),
                                child: Text(
                                  'Target: $journalTitle',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                    fontFamily: 'Manrope',
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // 3. Overall Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        height: 8,
                        color: AppColors.surfaceSoft,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: (progress.overallProgress / 100.0)
                                .clamp(0.02, 1.0),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutCubic,
                              decoration: BoxDecoration(
                                color: progress.isCompleted
                                    ? AppColors.green700
                                    : AppColors.primary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // 4. Progress Subtitle & Step Counter
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            progress.isCompleted
                                ? 'Analysis complete · Preparing result dashboard...'
                                : 'Step ${progress.currentStepIndex} of ${progress.totalSteps} · ${progress.currentMessage}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: progress.isCompleted
                                  ? AppColors.green700
                                  : AppColors.primary,
                              fontFamily: 'Manrope',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Overall Progress',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSubtle,
                            fontFamily: 'Manrope',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    const Divider(height: 1, color: AppColors.borderSoft),
                    const SizedBox(height: 20),

                    // 5. Vertical Pipeline Timeline
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: progress.steps.length,
                      itemBuilder: (context, index) {
                        final step = progress.steps[index];
                        final isLast = index == progress.steps.length - 1;
                        return _buildTimelineStep(step, isLast: isLast);
                      },
                    ),

                    // 6. Completion Banner
                    if (progress.isCompleted) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.green50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.green700.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 18,
                              color: AppColors.green700,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Your manuscript has been compared with $journalTitle. Loading results...',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.green700,
                                  fontFamily: 'Manrope',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // 7. Failure Banner & Retry
                    if (progress.isFailed) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.red50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.red700.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  size: 18,
                                  color: AppColors.red700,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Analysis Failed: ${progress.failedStepTitle ?? "Error"}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.red700,
                                    fontFamily: 'Manrope',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              progress.failureMessage ??
                                  'Unable to complete manuscript verification.',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textPrimary,
                                fontFamily: 'Manrope',
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (widget.onRetry != null)
                              ElevatedButton.icon(
                                onPressed: widget.onRetry,
                                icon: const Icon(
                                  Icons.refresh_rounded,
                                  size: 14,
                                ),
                                label: const Text('Retry Analysis'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.red700,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Bottom Advisory Note
              Center(
                child: Text(
                  'Analysis usually takes a few moments. You can keep this page open while we finish the comparison.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    fontFamily: 'Manrope',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineStep(PipelineStepState step, {required bool isLast}) {
    final isCompleted = step.status == PipelineStepStatus.completed;
    final isProcessing = step.status == PipelineStepStatus.processing;
    final isFailed = step.status == PipelineStepStatus.failed;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Indicator Icon + Connecting Line
          Column(
            children: [
              _buildStepIcon(step),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: isCompleted
                        ? AppColors.green700.withValues(alpha: 0.35)
                        : AppColors.borderSoft,
                  ),
                ),
            ],
          ),

          const SizedBox(width: 14),

          // Right: Content / Panel
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step Title & Status Badge
                  Row(
                    children: [
                      Text(
                        step.title,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: isProcessing || isCompleted
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: isProcessing
                              ? AppColors.primary
                              : isCompleted
                              ? AppColors.textPrimary
                              : isFailed
                              ? AppColors.red700
                              : AppColors.textSubtle,
                          fontFamily: 'Manrope',
                        ),
                      ),
                      if (isProcessing) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.blue50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'ANALYZING NOW',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              fontFamily: 'Manrope',
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Completed details
                  if (isCompleted && step.completionDetail != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      step.completionDetail!,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                        fontFamily: 'Manrope',
                      ),
                    ),
                  ],

                  // Active Processing Panel
                  if (isProcessing) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.blue50.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (step.activeMessage != null)
                            Text(
                              step.activeMessage!,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textSecondary,
                                fontFamily: 'Manrope',
                              ),
                            ),
                          if (step.subtasks.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 12,
                              runSpacing: 6,
                              children: step.subtasks.map((st) {
                                return _buildSubTaskItem(st);
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  // Pending hint
                  if (!isCompleted && !isProcessing && !isFailed) ...[
                    const SizedBox(height: 2),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIcon(PipelineStepState step) {
    switch (step.status) {
      case PipelineStepStatus.completed:
        return const Icon(
          Icons.check_circle_rounded,
          size: 20,
          color: AppColors.green700,
        );
      case PipelineStepStatus.processing:
        return SizedBox(
          width: 20,
          height: 20,
          child: Stack(
            alignment: Alignment.center,
            children: [
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
              ),
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ],
          ),
        );
      case PipelineStepStatus.failed:
        return const Icon(
          Icons.cancel_rounded,
          size: 20,
          color: AppColors.red700,
        );
      case PipelineStepStatus.pending:
        return Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.slate300, width: 1.5),
          ),
        );
    }
  }

  Widget _buildSubTaskItem(PipelineSubTask st) {
    Color iconColor;
    Widget icon;

    switch (st.status) {
      case PipelineStepStatus.completed:
        iconColor = AppColors.green700;
        icon = const Icon(
          Icons.check_rounded,
          size: 13,
          color: AppColors.green700,
        );
        break;
      case PipelineStepStatus.processing:
        iconColor = AppColors.primary;
        icon = const SizedBox(
          width: 10,
          height: 10,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        );
        break;
      case PipelineStepStatus.failed:
        iconColor = AppColors.red700;
        icon = const Icon(
          Icons.close_rounded,
          size: 13,
          color: AppColors.red700,
        );
        break;
      case PipelineStepStatus.pending:
        iconColor = AppColors.textSubtle;
        icon = Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.slate400, width: 1),
          ),
        );
        break;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(width: 5),
        Text(
          st.name,
          style: TextStyle(
            fontSize: 11,
            fontWeight: st.status == PipelineStepStatus.processing
                ? FontWeight.w700
                : FontWeight.w500,
            color: iconColor,
            fontFamily: 'Manrope',
          ),
        ),
      ],
    );
  }
}
