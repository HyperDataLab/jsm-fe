import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/datasources/manuscript_file_picker.dart';
import '../cubit/evaluation_history_cubit.dart';
import '../cubit/evaluation_history_state.dart';
import '../cubit/journal_recommendations_cubit.dart';
import '../cubit/journal_recommendations_state.dart';

class RecommendationsInputCard extends StatefulWidget {
  final VoidCallback onAnalyze;

  const RecommendationsInputCard({super.key, required this.onAnalyze});

  @override
  State<RecommendationsInputCard> createState() =>
      _RecommendationsInputCardState();
}

class _RecommendationsInputCardState extends State<RecommendationsInputCard> {
  bool _isHoveringDropzone = false;

  @override
  void initState() {
    super.initState();
    context.read<EvaluationHistoryCubit>().loadHistory();
  }

  Future<void> _pickFile() async {
    try {
      final file = await ManuscriptFilePickerSeam.picker();
      if (file != null && mounted) {
        context.read<JournalRecommendationsCubit>().selectFile(
          filename: file.name,
          bytes: file.bytes,
        );
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<
      JournalRecommendationsCubit,
      JournalRecommendationsState
    >(
      builder: (context, state) {
        final hasSelectedData =
            state.fileName != null ||
            state.selectedEvaluationId != null ||
            (state.fileBytes != null && state.fileBytes!.isNotEmpty);

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.border),
          ),
          color: AppColors.surface,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildAvailableJournalsInfo(
                  context,
                  state.availableJournalsCount,
                ),
                const SizedBox(height: 24),
                Text(
                  context.l10n.chooseManuscriptSource,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Manrope',
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 1,
                      child: _buildUploadOption(context, state),
                    ),
                    const SizedBox(width: 24),
                    Padding(
                      padding: const EdgeInsets.only(top: 60),
                      child: Text(
                        context.l10n.orDivider,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 1,
                      child: _buildHistoryOption(context, state),
                    ),
                  ],
                ),
                if (state.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.errorSurface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.error),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: AppColors.error,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            state.errorMessage!,
                            style: const TextStyle(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: hasSelectedData && !state.isLoading
                        ? widget.onAnalyze
                        : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.border,
                      disabledForegroundColor: AppColors.textSecondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: state.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            context.l10n.findSuitableJournals,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Manrope',
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvailableJournalsInfo(BuildContext context, int count) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.collections_bookmark_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.availableJournalProfiles,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFamily: 'Manrope',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  count > 0
                      ? context.l10n.availableJournalsComparisonCount(count)
                      : context.l10n.loadingAvailableJournals,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadOption(
    BuildContext context,
    JournalRecommendationsState state,
  ) {
    final isSelected =
        state.fileBytes != null && state.selectedEvaluationId == null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: isSelected ? 2 : 1,
        ),
        color: isSelected ? AppColors.primarySoft : Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.upload_file_rounded,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                context.l10n.uploadManuscriptTab,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _pickFile,
            onHover: (v) => setState(() => _isHoveringDropzone = v),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: _isHoveringDropzone
                    ? AppColors.primarySoft.withValues(alpha: 0.5)
                    : AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isHoveringDropzone
                      ? AppColors.primary
                      : AppColors.border,
                  style: BorderStyle.solid,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isSelected
                          ? Icons.description_rounded
                          : Icons.add_rounded,
                      size: 32,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isSelected
                          ? state.fileName!
                          : context.l10n.clickToBrowseFiles,
                      style: TextStyle(
                        fontSize: 13,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryOption(
    BuildContext context,
    JournalRecommendationsState state,
  ) {
    final isSelected = state.selectedEvaluationId != null;

    return BlocBuilder<EvaluationHistoryCubit, EvaluationHistoryState>(
      builder: (context, historyState) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
            color: isSelected ? AppColors.primarySoft : Colors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.history_rounded,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    context.l10n.selectEvaluationHistoryTab,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                padding: const EdgeInsets.all(12),
                child: historyState.status == EvaluationHistoryStatus.loading
                    ? const Center(child: CircularProgressIndicator())
                    : (historyState.items.isEmpty)
                    ? Center(
                        child: Text(
                          context.l10n.noPreviousEvaluationsHint,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: historyState.items.length,
                        separatorBuilder: (ctx, idx) =>
                            const Divider(height: 8),
                        itemBuilder: (ctx, idx) {
                          final item = historyState.items[idx];
                          final isActive =
                              item.id == state.selectedEvaluationId;
                          return InkWell(
                            onTap: () {
                              context
                                  .read<JournalRecommendationsCubit>()
                                  .selectEvaluationId(item.id, item.fileName);
                            },
                            borderRadius: BorderRadius.circular(4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? AppColors.primary.withValues(alpha: 0.1)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.description_outlined,
                                    size: 16,
                                    color: isActive
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      item.fileName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isActive
                                            ? AppColors.primary
                                            : AppColors.textPrimary,
                                        fontWeight: isActive
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
