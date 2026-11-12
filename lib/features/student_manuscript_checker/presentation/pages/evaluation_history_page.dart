import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_notification.dart';
import '../../../../core/widgets/search_input_box.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../data/repositories/student_manuscript_repository_impl.dart';
import '../../domain/entities/evaluation_history_item.dart';
import '../../domain/repositories/student_manuscript_repository.dart';
import '../cubit/evaluation_history_cubit.dart';
import '../cubit/evaluation_history_state.dart';
import 'evaluation_history_detail_page.dart';

class EvaluationHistoryPage extends StatefulWidget {
  final StudentManuscriptRepository? repository;
  final VoidCallback onNewCheckRequested;

  const EvaluationHistoryPage({
    super.key,
    this.repository,
    required this.onNewCheckRequested,
  });

  @override
  State<EvaluationHistoryPage> createState() => _EvaluationHistoryPageState();
}

class _EvaluationHistoryPageState extends State<EvaluationHistoryPage> {
  late final EvaluationHistoryCubit _cubit;
  late final StudentManuscriptRepository _repository;
  final TextEditingController _searchController = TextEditingController();
  String? _selectedEvaluationId;

  @override
  void initState() {
    super.initState();
    if (widget.repository != null) {
      _repository = widget.repository!;
    } else {
      AuthRepository? authRepo;
      try {
        authRepo = context.read<AuthRepository>();
      } catch (_) {}
      _repository = StudentManuscriptRepositoryImpl(authRepository: authRepo);
    }
    _cubit = EvaluationHistoryCubit(repository: _repository);
    _cubit.loadHistory(refreshStats: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedEvaluationId != null) {
      return EvaluationHistoryDetailPage(
        evaluationId: _selectedEvaluationId!,
        repository: _repository,
        onBack: () {
          setState(() {
            _selectedEvaluationId = null;
          });
          _cubit.loadHistory();
        },
        onRunNewEvaluation: () {
          setState(() {
            _selectedEvaluationId = null;
          });
          widget.onNewCheckRequested();
        },
      );
    }

    final l10n = AppLocalizations.of(context);

    return BlocProvider.value(
      value: _cubit,
      child: BlocConsumer<EvaluationHistoryCubit, EvaluationHistoryState>(
        listener: (context, state) {
          if (state.errorMessage != null &&
              state.status != EvaluationHistoryStatus.failure) {
            AppNotification.showError(context, state.errorMessage!);
          }
        },
        builder: (context, state) {
          if (state.status == EvaluationHistoryStatus.initial ||
              (state.status == EvaluationHistoryStatus.loading &&
                  state.items.isEmpty &&
                  !state.hasActiveFilters)) {
            return _buildLoadingView();
          }

          // If global empty state: no evaluations ever created
          if (state.status == EvaluationHistoryStatus.success &&
              state.items.isEmpty &&
              !state.hasActiveFilters &&
              state.stats.totalEvaluations == 0) {
            return _buildGlobalEmptyState(l10n);
          }

          // If failed on initial load
          if (state.status == EvaluationHistoryStatus.failure &&
              state.items.isEmpty) {
            return _buildErrorState(l10n, state.errorMessage);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. PAGE HEADER
                _buildHeader(l10n),

                const SizedBox(height: 16),

                // 2. COMPACT STATS SUMMARY
                _buildStatsRow(l10n, state),

                const SizedBox(height: 20),

                // 3. SEARCH & FILTERS CONTROLS
                _buildSearchAndFilters(context, l10n, state),

                const SizedBox(height: 16),

                // 4. CONTENT (TABLE / CARDS / FILTER EMPTY / SKELETON)
                if (state.status == EvaluationHistoryStatus.loading) ...[
                  _buildTableSkeleton(),
                ] else if (state.items.isEmpty) ...[
                  _buildFilterEmptyState(l10n),
                ] else ...[
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 700) {
                        return _buildMobileCardList(state.items);
                      }
                      return _buildHistoryTable(
                        state.items,
                        constraints.maxWidth,
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildPaginationControls(l10n, state),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.navEvaluationHistory,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontFamily: 'Manrope',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.evalHistorySubtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontFamily: 'Manrope',
                ),
              ),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: widget.onNewCheckRequested,
          icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
          label: Text(l10n.checkNewManuscript),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(AppLocalizations l10n, EvaluationHistoryState state) {
    final stats = state.stats;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 600;
          if (isNarrow) {
            return Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                _buildStatItem(
                  l10n.totalEvaluations,
                  stats.totalEvaluations.toString(),
                  Icons.analytics_outlined,
                  AppColors.primary,
                ),
                _buildStatItem(
                  l10n.strongMatches,
                  stats.strongMatches.toString(),
                  Icons.verified_rounded,
                  const Color(0xFF10B981),
                ),
                _buildStatItem(
                  l10n.needRevision,
                  stats.needRevision.toString(),
                  Icons.edit_note_rounded,
                  const Color(0xFFF59E0B),
                ),
                _buildStatItem(
                  l10n.averageCompatibility,
                  '${stats.averageCompatibility.toStringAsFixed(1)}%',
                  Icons.pie_chart_outline_rounded,
                  const Color(0xFF6366F1),
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  l10n.totalEvaluations,
                  stats.totalEvaluations.toString(),
                  Icons.analytics_outlined,
                  AppColors.primary,
                ),
              ),
              _buildDivider(),
              Expanded(
                child: _buildStatItem(
                  l10n.strongMatches,
                  stats.strongMatches.toString(),
                  Icons.verified_rounded,
                  const Color(0xFF10B981),
                ),
              ),
              _buildDivider(),
              Expanded(
                child: _buildStatItem(
                  l10n.needRevision,
                  stats.needRevision.toString(),
                  Icons.edit_note_rounded,
                  const Color(0xFFF59E0B),
                ),
              ),
              _buildDivider(),
              Expanded(
                child: _buildStatItem(
                  l10n.averageCompatibility,
                  '${stats.averageCompatibility.toStringAsFixed(1)}%',
                  Icons.pie_chart_outline_rounded,
                  const Color(0xFF6366F1),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 36,
      color: AppColors.border,
      margin: const EdgeInsets.symmetric(horizontal: 12),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
                fontFamily: 'Manrope',
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontFamily: 'Manrope',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters(
    BuildContext context,
    AppLocalizations l10n,
    EvaluationHistoryState state,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 720;

        final searchWidget = SearchInputBox(
          controller: _searchController,
          hintText: l10n.searchManuscriptPlaceholder,
          height: 38,
          onSubmitted: (value) => _cubit.setSearch(value),
          onChanged: (value) {
            if (value.isEmpty && state.search.isNotEmpty) {
              _cubit.setSearch('');
            }
          },
        );

        final compatibilityFilter = _buildFilterDropdown<String>(
          value: state.compatibility ?? 'ALL',
          items: [
            DropdownMenuItem(
              value: 'ALL',
              child: Text(l10n.filterAllCompatibilities),
            ),
            const DropdownMenuItem(
              value: 'STRONG_MATCH',
              child: Text('Strong Match'),
            ),
            const DropdownMenuItem(
              value: 'MODERATE_MATCH',
              child: Text('Moderate Match'),
            ),
            const DropdownMenuItem(
              value: 'WEAK_MATCH',
              child: Text('Weak Match'),
            ),
            const DropdownMenuItem(
              value: 'POOR_MATCH',
              child: Text('Poor Match'),
            ),
          ],
          onChanged: (val) => _cubit.setCompatibility(val),
        );

        final sortFilter = _buildFilterDropdown<String>(
          value: state.sort,
          items: [
            DropdownMenuItem(value: 'newest', child: Text(l10n.sortNewest)),
            DropdownMenuItem(value: 'oldest', child: Text(l10n.sortOldest)),
            DropdownMenuItem(
              value: 'score_desc',
              child: Text(l10n.sortScoreDesc),
            ),
            DropdownMenuItem(
              value: 'score_asc',
              child: Text(l10n.sortScoreAsc),
            ),
          ],
          onChanged: (val) {
            if (val != null) _cubit.setSort(val);
          },
        );

        final clearButton = state.hasActiveFilters
            ? TextButton.icon(
                onPressed: () {
                  _searchController.clear();
                  _cubit.clearFilters();
                },
                icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
                label: Text(
                  l10n.clearFilters,
                  style: const TextStyle(fontSize: 12),
                ),
              )
            : null;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: isWide
              ? Row(
                  children: [
                    Expanded(child: searchWidget),
                    const SizedBox(width: 12),
                    compatibilityFilter,
                    const SizedBox(width: 12),
                    sortFilter,
                    if (clearButton != null) ...[
                      const SizedBox(width: 12),
                      clearButton,
                    ],
                  ],
                )
              : Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(width: double.infinity, child: searchWidget),
                    compatibilityFilter,
                    sortFilter,
                    ?clearButton,
                  ],
                ),
        );
      },
    );
  }

  Widget _buildFilterDropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          focusColor: Colors.transparent,
          dropdownColor: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          elevation: 4,
          isDense: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: AppColors.textSecondary,
          ),
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF0F172A),
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w500,
          ),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildHistoryTable(
    List<EvaluationHistoryItem> items,
    double availableWidth,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: availableWidth > 900 ? availableWidth : 900,
            ),
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(2.8), // Manuscript (flexible)
                1: FlexColumnWidth(2.0), // Target Journal (flexible)
                2: FixedColumnWidth(130), // Compatibility
                3: FixedColumnWidth(90), // Score
                4: FixedColumnWidth(95), // Issues
                5: FixedColumnWidth(145), // Evaluated
                6: FixedColumnWidth(150), // Action
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                TableRow(
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceSoft,
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  children: [
                    _buildHeaderCell('Manuscript'),
                    _buildHeaderCell('Target Journal'),
                    _buildHeaderCell('Compatibility', align: TextAlign.center),
                    _buildHeaderCell('Score'),
                    _buildHeaderCell('Issues'),
                    _buildHeaderCell('Evaluated'),
                    _buildHeaderCell(
                      'Action',
                      align: TextAlign.end,
                      horizontalPadding: 16,
                    ),
                  ],
                ),
                for (final item in items)
                  TableRow(
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppColors.borderSoft),
                      ),
                    ),
                    children: [
                      // Manuscript
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.description_outlined,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item.fileName,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                  fontFamily: 'Manrope',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Target Journal
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Text(
                          item.journalName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            fontFamily: 'Manrope',
                          ),
                        ),
                      ),

                      // Compatibility
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Align(
                          alignment: Alignment.center,
                          child: _buildCompatibilityBadge(
                            item.compatibilityLevel,
                          ),
                        ),
                      ),

                      // Score with compact visual indicator
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: _buildScoreIndicator(item.overallScore),
                      ),

                      // Issues
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Text(
                          item.criticalMismatchCount > 0
                              ? '${item.criticalMismatchCount} issues'
                              : 'No issues',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: item.criticalMismatchCount > 0
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF10B981),
                            fontFamily: 'Manrope',
                          ),
                        ),
                      ),

                      // Evaluated date
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Text(
                          DateFormat('MMM d, yyyy HH:mm')
                              .format(item.createdAt.toLocal()),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                            fontFamily: 'Manrope',
                          ),
                        ),
                      ),

                      // Action
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 8,
                          right: 16,
                          top: 8,
                          bottom: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Material(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(6),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedEvaluationId = item.id;
                                  });
                                },
                                borderRadius: BorderRadius.circular(6),
                                hoverColor: AppColors.surfaceSoft,
                                child: Container(
                                  constraints: const BoxConstraints(
                                    minWidth: 56,
                                    minHeight: 30,
                                  ),
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: AppColors.border,
                                      width: 1,
                                    ),
                                  ),
                                  child: const Text(
                                    'View',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Manrope',
                                      color: AppColors.textPrimary,
                                      height: 1.2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                size: 18,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 30,
                                minHeight: 30,
                              ),
                              splashRadius: 16,
                              color: AppColors.textMuted,
                              tooltip: 'Delete',
                              onPressed: () => _showDeleteConfirmation(item),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCell(
    String label, {
    TextAlign align = TextAlign.start,
    double horizontalPadding = 14,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 12,
      ),
      child: Text(
        label,
        textAlign: align,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          fontFamily: 'Manrope',
        ),
      ),
    );
  }

  Widget _buildScoreIndicator(double score) {
    Color color;
    if (score >= 80) {
      color = const Color(0xFF10B981);
    } else if (score >= 65) {
      color = const Color(0xFFF59E0B);
    } else if (score >= 50) {
      color = const Color(0xFFF97316);
    } else {
      color = const Color(0xFFEF4444);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          score.toStringAsFixed(1),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
            fontFamily: 'Manrope',
          ),
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: Container(
            width: 50,
            height: 4,
            color: AppColors.surfaceSoft,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (score / 100.0).clamp(0.0, 1.0),
              child: Container(color: color),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompatibilityBadge(String level) {
    Color bg;
    Color fg;
    String label;

    switch (level.toUpperCase()) {
      case 'STRONG_MATCH':
        bg = const Color(0xFFECFDF5);
        fg = const Color(0xFF059669);
        label = 'Strong Match';
        break;
      case 'MODERATE_MATCH':
        bg = const Color(0xFFFFFBEB);
        fg = const Color(0xFFD97706);
        label = 'Moderate Match';
        break;
      case 'WEAK_MATCH':
        bg = const Color(0xFFFFF7ED);
        fg = const Color(0xFFEA580C);
        label = 'Weak Match';
        break;
      default:
        bg = const Color(0xFFFEF2F2);
        fg = const Color(0xFFDC2626);
        label = 'Poor Match';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withAlpha(40)),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
          fontFamily: 'Manrope',
          height: 1.2,
        ),
      ),
    );
  }

  Widget _buildMobileCardList(List<EvaluationHistoryItem> items) {
    return Column(
      children: items.map((item) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.description_outlined,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.fileName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            fontFamily: 'Manrope',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.journalName,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontFamily: 'Manrope',
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildCompatibilityBadge(item.compatibilityLevel),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildScoreIndicator(item.overallScore),
                  Text(
                    item.criticalMismatchCount > 0
                        ? '${item.criticalMismatchCount} issues'
                        : 'No issues',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: item.criticalMismatchCount > 0
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF10B981),
                    ),
                  ),
                  Text(
                    DateFormat('MMM d, yyyy').format(item.createdAt.toLocal()),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    color: AppColors.textMuted,
                    onPressed: () => _showDeleteConfirmation(item),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedEvaluationId = item.id;
                      });
                    },
                    icon: const Icon(Icons.visibility_outlined, size: 14),
                    label: const Text('View Result'),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPaginationControls(
    AppLocalizations l10n,
    EvaluationHistoryState state,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing page ${state.page} of ${state.totalPages > 0 ? state.totalPages : 1} (${state.total} total)',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontFamily: 'Manrope',
            ),
          ),
          Row(
            children: [
              _buildPaginationButton(
                icon: Icons.chevron_left_rounded,
                label: 'Previous',
                iconLeading: true,
                enabled: state.page > 1,
                onTap: () => _cubit.changePage(state.page - 1),
              ),
              const SizedBox(width: 8),
              _buildPaginationButton(
                icon: Icons.chevron_right_rounded,
                label: 'Next',
                iconLeading: false,
                enabled: state.page < state.totalPages,
                onTap: () => _cubit.changePage(state.page + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationButton({
    required IconData icon,
    required String label,
    required bool iconLeading,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return Material(
      color: enabled ? AppColors.surface : AppColors.surfaceSoft,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(4),
        hoverColor: enabled ? AppColors.primary.withAlpha(12) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: enabled ? AppColors.border : AppColors.borderSoft,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (iconLeading) ...[
                Icon(
                  icon,
                  size: 16,
                  color: enabled ? AppColors.textPrimary : AppColors.textSubtle,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Manrope',
                  color: enabled ? AppColors.textPrimary : AppColors.textSubtle,
                ),
              ),
              if (!iconLeading) ...[
                const SizedBox(width: 4),
                Icon(
                  icon,
                  size: 16,
                  color: enabled ? AppColors.textPrimary : AppColors.textSubtle,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableSkeleton() {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
    );
  }

  Widget _buildLoadingView() {
    return const Center(child: CircularProgressIndicator(strokeWidth: 2.5));
  }

  Widget _buildGlobalEmptyState(AppLocalizations l10n) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.sidebarBorder),
                ),
                child: const Center(
                  child: Icon(
                    Icons.history_rounded,
                    size: 32,
                    color: AppColors.sidebarIconInactive,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.evalHistoryTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Manrope',
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.evalHistoryDesc,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontFamily: 'Manrope',
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: widget.onNewCheckRequested,
                icon: const Icon(Icons.rate_review_rounded, size: 16),
                label: Text(l10n.checkManuscriptNow),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterEmptyState(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.filter_list_off_rounded,
              size: 40,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 14),
            Text(
              l10n.noFilterResults,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontFamily: 'Manrope',
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                _searchController.clear();
                _cubit.clearFilters();
              },
              icon: const Icon(Icons.clear_rounded, size: 16),
              label: Text(l10n.clearFilters),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(AppLocalizations l10n, String? message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 44,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.errorLoadingHistory,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _cubit.loadHistory(refreshStats: true),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(l10n.tryAgain),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(EvaluationHistoryItem item) {
    final l10n = AppLocalizations.of(context);
    bool isDeleting = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.border),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24),
          actionsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.errorSurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.error,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.deleteConfirmTitle,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFamily: 'Manrope',
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.deleteConfirmMessage,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontFamily: 'Manrope',
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.description_outlined,
                            size: 15,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.fileName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                                fontFamily: 'Manrope',
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.menu_book_outlined,
                            size: 15,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.journalName,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontFamily: 'Manrope',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: isDeleting
                  ? null
                  : () => Navigator.of(dialogCtx).pop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                side: const BorderSide(color: AppColors.border),
                foregroundColor: AppColors.textSecondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                l10n.cancelBtn,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.error.withValues(alpha: 0.7),
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: isDeleting
                  ? null
                  : () async {
                      setDialogState(() {
                        isDeleting = true;
                      });
                      final success = await _cubit.deleteEvaluation(item.id);
                      if (dialogCtx.mounted) {
                        Navigator.of(dialogCtx).pop();
                      }
                      if (success && mounted) {
                        AppNotification.showSuccess(
                          context,
                          l10n.evaluationDeletedSuccess,
                        );
                      }
                    },
              child: isDeleting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      l10n.deleteBtn,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
