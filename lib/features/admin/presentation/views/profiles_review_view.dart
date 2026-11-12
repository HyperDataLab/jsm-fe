import 'package:material_ui/material_ui.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_notification.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/datasources/admin_api_client.dart';
import '../widgets/style_comparison/comparison_overview.dart';
import '../widgets/style_comparison/style_fingerprint_card.dart';
import '../widgets/style_comparison/key_differences_panel.dart';
import '../widgets/style_comparison/metric_differences_dumbbell_chart.dart';
import '../widgets/style_comparison/sentence_distribution_chart.dart';
import '../widgets/style_comparison/stance_distribution_chart.dart';
import '../widgets/style_comparison/cars_moves_chart.dart';
import '../widgets/style_comparison/style_difference_matrix.dart';
import '../widgets/style_comparison/writing_examples_section.dart';

class ProfilesReviewView extends StatefulWidget {
  final Function(int) onNavigateToTab;
  final String? selectedJournalId;

  const ProfilesReviewView({
    super.key,
    required this.onNavigateToTab,
    this.selectedJournalId,
  });

  @override
  State<ProfilesReviewView> createState() => _ProfilesReviewViewState();
}

class _ProfilesReviewViewState extends State<ProfilesReviewView> {
  final AdminApiClient _apiClient = AdminApiClient();
  List<Map<String, dynamic>> _profiles = [];
  bool _isLoading = true;
  String? _error;

  // Selected Journal IDs for comparison (1 to 3 items)
  List<String> _selectedCompareIds = [];
  static const List<Color> _compareColors = [
    Color(0xFF0071BC), // Primary Brand Blue
    Color(0xFF7C3AED), // Iris Purple
    Color(0xFFD97706), // Amber Orange
  ];

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  @override
  void didUpdateWidget(covariant ProfilesReviewView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedJournalId != null &&
        widget.selectedJournalId != oldWidget.selectedJournalId &&
        _profiles.any(
          (p) => p['journal_id']?.toString() == widget.selectedJournalId,
        )) {
      final jId = widget.selectedJournalId!;
      if (!_selectedCompareIds.contains(jId)) {
        setState(() {
          if (_selectedCompareIds.length >= 3) {
            _selectedCompareIds[0] = jId;
          } else {
            _selectedCompareIds.add(jId);
          }
        });
      }
    }
  }

  Future<void> _loadProfiles() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final list = await _apiClient.getStyleProfiles();
      if (!mounted) return;
      setState(() {
        _profiles = list;

        // Initialize compare selection (up to 2 by default, or widget selected)
        if (_selectedCompareIds.isEmpty && list.isNotEmpty) {
          if (widget.selectedJournalId != null &&
              list.any(
                (p) => p['journal_id']?.toString() == widget.selectedJournalId,
              )) {
            final other = list.firstWhere(
              (p) => p['journal_id']?.toString() != widget.selectedJournalId,
              orElse: () => list.first,
            );
            _selectedCompareIds = [
              widget.selectedJournalId!,
              if (other['journal_id']?.toString() != widget.selectedJournalId)
                other['journal_id']?.toString() ?? '',
            ].where((id) => id.isNotEmpty).toList();
          } else {
            _selectedCompareIds = list
                .take(2)
                .map((p) => p['journal_id']?.toString() ?? '')
                .where((id) => id.isNotEmpty)
                .toList();
          }
        }

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _addJournalSlot() {
    if (_selectedCompareIds.length >= 3) {
      AppNotification.showWarning(context, context.l10n.compareMaxLimit);
      return;
    }

    String? nextId;
    for (final p in _profiles) {
      final pid = p['journal_id']?.toString();
      if (pid != null && !_selectedCompareIds.contains(pid)) {
        nextId = pid;
        break;
      }
    }
    nextId ??= _profiles.first['journal_id']?.toString();

    if (nextId != null) {
      setState(() {
        _selectedCompareIds.add(nextId!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          _buildHeader(),
          const SizedBox(height: 24),

          // State Handling
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(64),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            _buildErrorState()
          else if (_profiles.isEmpty)
            _buildEmptyState()
          else
            _buildComparisonView(),
        ],
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────
  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 900;

        final titleCol = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.profilesReviewTitle,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontFamily: 'Manrope',
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              context.l10n.profilesReviewSubtitle,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
                fontFamily: 'Manrope',
              ),
            ),
          ],
        );

        final controlsWrap = Wrap(
          spacing: 10,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            IconButton(
              onPressed: _loadProfiles,
              icon: const Icon(Icons.refresh_rounded),
              tooltip: context.l10n.reloadProfiles,
              color: AppColors.primary,
            ),
            ElevatedButton.icon(
              onPressed: () {
                AppNotification.showSuccess(
                  context,
                  context.l10n.publishSuccess,
                  title: context.l10n.publishSuccessTitle,
                );
              },
              icon: const Icon(Icons.verified_rounded, size: 18),
              label: Text(context.l10n.publishStandard),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        );

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [titleCol, const SizedBox(height: 12), controlsWrap],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: titleCol),
            const SizedBox(width: 16),
            controlsWrap,
          ],
        );
      },
    );
  }

  // ── Unified Style & Comparison View ──────────────────────────────
  Widget _buildComparisonView() {
    final selectedProfiles = _selectedCompareIds.map((id) {
      return _profiles.firstWhere(
        (p) => p['journal_id']?.toString() == id,
        orElse: () => _profiles.first,
      );
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 1100;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SECTION 1: Journal Comparison Selector
            _buildCompareSelectorBar(),
            const SizedBox(height: 24),

            // SECTION 2: Comparison Overview (4-6 mini metrics with Δ & mini visual)
            if (selectedProfiles.length >= 2) ...[
              ComparisonOverview(
                profiles: selectedProfiles,
                colors: _compareColors,
              ),
              const SizedBox(height: 28),
            ],

            // SECTION 3: Style Fingerprint (Radar / Parallel Coordinates) + Key Differences
            if (isCompact) ...[
              StyleFingerprintCard(
                profiles: selectedProfiles,
                colors: _compareColors,
              ),
              const SizedBox(height: 20),
              KeyDifferencesPanel(
                profiles: selectedProfiles,
                colors: _compareColors,
              ),
            ] else ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 6,
                    child: StyleFingerprintCard(
                      profiles: selectedProfiles,
                      colors: _compareColors,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 4,
                    child: KeyDifferencesPanel(
                      profiles: selectedProfiles,
                      colors: _compareColors,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 28),

            // SECTION 4: Metric Differences – Dumbbell Chart
            if (selectedProfiles.length >= 2) ...[
              MetricDifferencesDumbbellChart(
                profiles: selectedProfiles,
                colors: _compareColors,
              ),
              const SizedBox(height: 28),
            ],

            // SECTION 5: Sentence Length Distribution + Stance Distribution
            if (isCompact) ...[
              SentenceDistributionChart(
                profiles: selectedProfiles,
                colors: _compareColors,
              ),
              const SizedBox(height: 20),
              StanceDistributionChart(
                profiles: selectedProfiles,
                colors: _compareColors,
              ),
            ] else ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SentenceDistributionChart(
                      profiles: selectedProfiles,
                      colors: _compareColors,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: StanceDistributionChart(
                      profiles: selectedProfiles,
                      colors: _compareColors,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 28),

            // SECTION 6: Rhetorical Structure — CARS Moves Comparison
            CarsMovesChart(profiles: selectedProfiles, colors: _compareColors),
            const SizedBox(height: 28),

            // SECTION 7: Style Difference Matrix (Heatmap)
            StyleDifferenceMatrix(
              profiles: selectedProfiles,
              colors: _compareColors,
            ),
            const SizedBox(height: 28),

            // SECTION 8: Writing Examples (Intro Exemplars)
            WritingExamplesSection(
              profiles: selectedProfiles,
              colors: _compareColors,
            ),
          ],
        );
      },
    );
  }

  // ── Dropdown Selectors Bar with (+) Button ────────────────────────
  Widget _buildCompareSelectorBar() {
    return Container(
      padding: const EdgeInsets.all(20),
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
                    Icons.tune_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    context.l10n.comparisonJournalsCount(
                      _selectedCompareIds.length,
                    ),
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontFamily: 'Manrope',
                    ),
                  ),
                ],
              ),
              Text(
                _selectedCompareIds.length == 1
                    ? context.l10n.singleViewHint
                    : context.l10n.comparingJournalsParallel(
                        _selectedCompareIds.length,
                      ),
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.textSubtle,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              for (int i = 0; i < _selectedCompareIds.length; i++) ...[
                if (i > 0) const SizedBox(width: 14),
                Expanded(
                  child: _buildDropdownSlot(
                    i,
                    _selectedCompareIds[i],
                    _profiles,
                  ),
                ),
              ],
              if (_selectedCompareIds.length < 3) ...[
                const SizedBox(width: 14),
                _buildAddJournalButton(),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddJournalButton() {
    return Tooltip(
      message: context.l10n.addComparisonJournalTooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _addJournalSlot,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.blue50,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withAlpha(160),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withAlpha(20),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.add_rounded,
              size: 24,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownSlot(
    int index,
    String currentId,
    List<Map<String, dynamic>> profiles,
  ) {
    final color = _compareColors[index % _compareColors.length];
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(160), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(10),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                context.l10n.journalIndex(index + 1),
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: color,
                  fontFamily: 'Manrope',
                ),
              ),
              const Spacer(),
              if (_selectedCompareIds.length > 1)
                InkWell(
                  onTap: () {
                    setState(() {
                      _selectedCompareIds.removeAt(index);
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: AppColors.textSubtle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value:
                  profiles.any((p) => p['journal_id']?.toString() == currentId)
                  ? currentId
                  : (profiles.isNotEmpty
                        ? profiles.first['journal_id']?.toString()
                        : null),
              isExpanded: true,
              isDense: true,
              dropdownColor: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              focusColor: Colors.transparent,
              elevation: 4,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: color,
                size: 20,
              ),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontFamily: 'Manrope',
              ),
              items: profiles.map((p) {
                final id = p['journal_id']?.toString() ?? '';
                final name = p['journal_name'] ?? context.l10n.journal;
                final issn = p['issn'] ?? 'N/A';
                return DropdownMenuItem<String>(
                  value: id,
                  child: Text(
                    '$name (ISSN: $issn)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (newVal) {
                if (newVal != null) {
                  setState(() {
                    _selectedCompareIds[index] = newVal;
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Common Sub-widgets ───────────────────────────────────────────
  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 36,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontFamily: 'Manrope',
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _loadProfiles,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(context.l10n.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Center(
        child: Text(
          context.l10n.noProfilesExtracted,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontFamily: 'Manrope',
          ),
        ),
      ),
    );
  }
}
