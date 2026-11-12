import 'package:material_ui/material_ui.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/search_input_box.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/datasources/admin_api_client.dart';

class SnapshotsView extends StatefulWidget {
  final Function(int, {String? journalId}) onNavigateToTab;

  const SnapshotsView({super.key, required this.onNavigateToTab});

  @override
  State<SnapshotsView> createState() => _SnapshotsViewState();
}

class _SnapshotsViewState extends State<SnapshotsView> {
  final AdminApiClient _apiClient = AdminApiClient();
  String _searchQuery = '';
  List<Map<String, dynamic>> _snapshots = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSnapshots();
  }

  Future<void> _loadSnapshots() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final list = await _apiClient.getSnapshots();
      if (!mounted) return;
      setState(() {
        _snapshots = list;
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

  String _formatHash(dynamic hash) {
    if (hash == null) return 'N/A';
    final s = hash.toString();
    if (s.length > 20) {
      return '${s.substring(0, 8)}...${s.substring(s.length - 8)}';
    }
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _snapshots.where((s) {
      final journal = (s['journal'] ?? '').toString().toLowerCase();
      final id = (s['id'] ?? '').toString().toLowerCase();
      final issn = (s['issn'] ?? '').toString().toLowerCase();
      final q = _searchQuery.toLowerCase();
      return journal.contains(q) || id.contains(q) || issn.contains(q);
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.snapshotsTitle,
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
                      context.l10n.snapshotsSubtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textMuted,
                        fontFamily: 'Manrope',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: _loadSnapshots,
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: context.l10n.reloadSnapshots,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => widget.onNavigateToTab(3),
                    icon: const Icon(Icons.bolt_rounded, size: 18),
                    label: Text(context.l10n.viewSnapshotProgress),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Search Toolbar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: SearchInputBox(
              hintText: context.l10n.searchSnapshotHint,
              height: 38,
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          const SizedBox(height: 20),

          // Snapshots Table
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: LayoutBuilder(
              builder: (context, tableConstraints) {
                final tableWidth = tableConstraints.maxWidth > 880
                    ? tableConstraints.maxWidth
                    : 880.0;
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: SizedBox(
                    width: tableWidth,
                    child: Column(
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          decoration: const BoxDecoration(
                            color: AppColors.surfaceSoft,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  context.l10n.colJournalSnapshot,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSubtle,
                                    fontFamily: 'Manrope',
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  context.l10n.colYearRange,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSubtle,
                                    fontFamily: 'Manrope',
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  context.l10n.colArticleCount,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSubtle,
                                    fontFamily: 'Manrope',
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  context.l10n.colHash,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSubtle,
                                    fontFamily: 'Manrope',
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  context.l10n.colFrozenDate,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSubtle,
                                    fontFamily: 'Manrope',
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 120,
                                child: Text(
                                  context.l10n.colActions,
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSubtle,
                                    fontFamily: 'Manrope',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Table state
                        if (_isLoading)
                          const Padding(
                            padding: EdgeInsets.all(48),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (_error != null)
                          Padding(
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
                                    onPressed: _loadSnapshots,
                                    icon: const Icon(
                                      Icons.refresh_rounded,
                                      size: 16,
                                    ),
                                    label: Text(context.l10n.retry),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else if (filtered.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(48),
                            child: Center(
                              child: Text(
                                context.l10n.noData,
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontFamily: 'Manrope',
                                ),
                              ),
                            ),
                          )
                        else
                          for (int i = 0; i < filtered.length; i++) ...[
                            _buildSnapshotRow(filtered[i]),
                            if (i < filtered.length - 1)
                              const Divider(
                                height: 1,
                                color: AppColors.borderSoft,
                              ),
                          ],
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
  }

  Widget _buildSnapshotRow(Map<String, dynamic> s) {
    final journal = s['journal'] ?? context.l10n.unknown;
    final id = s['id'] ?? 'N/A';
    final journalId = s['journal_id']?.toString();
    final yearRange = s['yearRange'] ?? '2021 - 2024';
    final paperCount = s['paperCount'] ?? 0;
    final createdAt = s['createdAt'] ?? '24/09/2026';
    final hash = s['hash'] ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  journal,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFamily: 'Manrope',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  id,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    fontFamily: 'Manrope',
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              yearRange,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontFamily: 'Manrope',
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              context.l10n.articlesCountLabel(paperCount),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontFamily: 'Manrope',
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Tooltip(
              message: hash,
              child: Row(
                children: [
                  const Icon(
                    Icons.fingerprint_rounded,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatHash(hash),
                    style: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              createdAt,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
                fontFamily: 'Manrope',
              ),
            ),
          ),
          SizedBox(
            width: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () =>
                      widget.onNavigateToTab(5, journalId: journalId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    minimumSize: const Size(100, 36),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    context.l10n.viewProfile,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Manrope',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
