import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_notification.dart';
import '../../../../core/widgets/search_input_box.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/datasources/admin_api_client.dart';
import '../widgets/journal_command_center_panel.dart';

class JournalsView extends StatefulWidget {
  final Function(int) onNavigateToTab;
  final VoidCallback? onTriggerNewAnalysis;

  const JournalsView({
    super.key,
    required this.onNavigateToTab,
    this.onTriggerNewAnalysis,
  });

  @override
  State<JournalsView> createState() => _JournalsViewState();
}

class _JournalsViewState extends State<JournalsView> {
  final AdminApiClient _apiClient = AdminApiClient();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String? _selectedDomain;
  String _filterStatus = 'all'; // 'all' | 'configured' | 'unconfigured'
  int _currentPage = 1;
  static const int _pageSize = 6;

  List<Map<String, dynamic>> _journals = [];
  List<Map<String, dynamic>> _configs = [];
  Map<String, dynamic>? _selectedJournal;
  bool _isLoading = true;
  String? _error;

  // OpenAlex live fallback search state
  List<Map<String, dynamic>> _openAlexResults = [];
  bool _isSearchingOpenAlex = false;
  String? _openAlexSearchError;
  String? _lastSearchedOpenAlexQuery;
  final Set<String> _importingIds = {};
  final Set<String> _triggeringConfigIds = {};

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _apiClient.getJournals(),
        _apiClient.getConfigurations(),
      ]);
      if (!mounted) return;
      setState(() {
        _journals = results[0];
        _configs = results[1];
        _isLoading = false;

        // Keep _selectedJournal synced with fresh data if already chosen
        if (_selectedJournal != null) {
          final sId = _selectedJournal!['id']?.toString();
          final updated = _journals
              .where((j) => j['id']?.toString() == sId)
              .toList();
          if (updated.isNotEmpty) {
            _selectedJournal = updated.first;
          }
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic>? _getConfigForJournal(String journalId) {
    for (final c in _configs) {
      final jId =
          c['journal_id']?.toString() ?? c['journal']?['id']?.toString();
      if (jId == journalId) {
        return c;
      }
    }
    return null;
  }

  String _getDomainForJournal(Map<String, dynamic> journal) {
    if ((journal['field'] ?? '').toString().trim().isNotEmpty) {
      return journal['field'].toString();
    }

    final journalId = journal['id']?.toString() ?? '';
    final cfg = _getConfigForJournal(journalId);
    if (cfg != null && (cfg['domain'] ?? '').toString().trim().isNotEmpty) {
      return cfg['domain'].toString();
    }

    final title = (journal['title'] ?? '').toString().toLowerCase();
    if (title.contains('bioinformatics') ||
        title.contains('computational biology')) {
      return 'Bioinformatics & Computational Biology';
    }
    if (title.contains('software engineering') ||
        title.contains('programming')) {
      return 'Software Engineering';
    }
    if (title.contains('artificial intelligence') ||
        title.contains('machine learning') ||
        title.contains('ai')) {
      return 'Artificial Intelligence & Machine Learning';
    }
    if (title.contains('big data') || title.contains('data science')) {
      return 'Big Data & Data Science';
    }
    if (title.contains('genetics') || title.contains('genomics')) {
      return 'Genetics & Genomics';
    }
    if (title.contains('biomedical') ||
        title.contains('medicine') ||
        title.contains('life')) {
      return 'Biomedical & Life Sciences';
    }
    if (title.contains('computer science')) {
      return 'Computer Science';
    }

    return context.l10n.defaultDomainCs;
  }

  Future<void> _searchOpenAlex([String? query]) async {
    final q = (query ?? _searchQuery).trim();
    if (q.isEmpty) return;

    setState(() {
      _isSearchingOpenAlex = true;
      _openAlexSearchError = null;
      _lastSearchedOpenAlexQuery = q;
      _openAlexResults = [];
    });

    try {
      final results = await _apiClient.searchOpenAlexJournals(q);
      if (!mounted) return;
      setState(() {
        _openAlexResults = results;
        _isSearchingOpenAlex = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _openAlexSearchError = e.toString();
        _isSearchingOpenAlex = false;
      });
    }
  }

  Future<void> _importOpenAlexJournal(Map<String, dynamic> journal) async {
    final openalexId = journal['openalex_id']?.toString() ?? '';
    final title = journal['title']?.toString() ?? '';
    final issnL = journal['issn_l']?.toString();
    final issns = (journal['issns'] is List)
        ? (journal['issns'] as List).map((e) => e.toString()).toList()
        : (issnL != null ? [issnL] : <String>[]);
    final publisher = journal['publisher']?.toString();
    final homepage = journal['homepage_url']?.toString();
    final worksCount = journal['works_count'] is int
        ? journal['works_count'] as int
        : int.tryParse(journal['works_count']?.toString() ?? '0') ?? 0;
    final citedByCount = journal['cited_by_count'] is int
        ? journal['cited_by_count'] as int
        : int.tryParse(journal['cited_by_count']?.toString() ?? '0') ?? 0;
    final field = journal['field']?.toString();

    setState(() {
      _importingIds.add(openalexId);
    });

    try {
      await _apiClient.importJournal(
        openalexId: openalexId,
        title: title,
        issnL: issnL,
        issns: issns,
        publisher: publisher,
        homepageUrl: homepage,
        worksCount: worksCount,
        citedByCount: citedByCount,
        field: field,
      );

      if (!mounted) return;
      AppNotification.showSuccess(
        context,
        'Đã nạp "$title" vào cơ sở dữ liệu thành công.',
        title: context.l10n.success,
      );

      setState(() {
        journal['is_imported'] = true;
        _importingIds.remove(openalexId);
      });

      await _loadAllData();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _importingIds.remove(openalexId);
      });
      AppNotification.showError(
        context,
        'Lỗi khi nạp tạp chí: $e',
        title: context.l10n.error,
      );
    }
  }

  Future<void> _triggerAnalysis(String configId, String journalName) async {
    setState(() {
      _triggeringConfigIds.add(configId);
    });

    try {
      await _apiClient.triggerAnalysis(configId);
      if (!mounted) return;
      setState(() {
        _triggeringConfigIds.remove(configId);
      });
      AppNotification.showSuccess(
        context,
        'Đã kích hoạt chu trình phân tích cho: $journalName',
        title: context.l10n.success,
        icon: Icons.bolt_rounded,
      );
      widget.onNavigateToTab(2); // Chuyển sang Tab 2 (Hệ thống & Giám sát)
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _triggeringConfigIds.remove(configId);
      });
      AppNotification.showError(
        context,
        'Lỗi kích hoạt khai phá: $e',
        title: context.l10n.error,
      );
    }
  }

  void _showAddJournalDialog(BuildContext context) {
    final titleController = TextEditingController();
    final issnController = TextEditingController();
    final publisherController = TextEditingController();
    final openalexController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.manualJournalEntryTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Manrope',
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.manualJournalEntryDesc,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Manrope',
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.fullJournalTitleRequired,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        fontFamily: 'Manrope',
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        hintText: context.l10n.journalTitlePlaceholder,
                        hintStyle: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSubtle,
                        ),
                        fillColor: AppColors.surfaceSoft,
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Mã chuẩn quốc tế ISSN / ISSN-L *',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        fontFamily: 'Manrope',
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: issnController,
                      decoration: InputDecoration(
                        hintText: 'Ví dụ: 0098-5589',
                        hintStyle: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSubtle,
                        ),
                        fillColor: AppColors.surfaceSoft,
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Nhà xuất bản (Publisher)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        fontFamily: 'Manrope',
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: publisherController,
                      decoration: InputDecoration(
                        hintText:
                            'Ví dụ: IEEE Computer Society / Springer / ACM',
                        hintStyle: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSubtle,
                        ),
                        fillColor: AppColors.surfaceSoft,
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'OpenAlex Source URI (Tùy chọn)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        fontFamily: 'Manrope',
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: openalexController,
                      decoration: InputDecoration(
                        hintText: 'Ví dụ: https://openalex.org/S8351582',
                        hintStyle: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSubtle,
                        ),
                        fillColor: AppColors.surfaceSoft,
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(ctx).pop(),
                  child: const Text(
                    'Hủy',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final title = titleController.text.trim();
                          final issn = issnController.text.trim();
                          if (title.isEmpty || issn.isEmpty) {
                            AppNotification.showWarning(
                              context,
                              'Vui lòng nhập tên tạp chí và mã ISSN',
                            );
                            return;
                          }

                          setModalState(() => isSubmitting = true);
                          try {
                            final openalexId =
                                openalexController.text.trim().isNotEmpty
                                ? openalexController.text.trim()
                                : 'https://openalex.org/S_${issn.replaceAll('-', '')}';

                            await _apiClient.importJournal(
                              openalexId: openalexId,
                              title: title,
                              issnL: issn,
                              issns: [issn],
                              publisher:
                                  publisherController.text.trim().isNotEmpty
                                  ? publisherController.text.trim()
                                  : 'Academic Publisher',
                              worksCount: 0, // Fallback if manually typed
                              citedByCount: 0,
                            );

                            if (ctx.mounted) Navigator.of(ctx).pop();
                            if (context.mounted) {
                              AppNotification.showSuccess(
                                context,
                                'Đã đăng ký tạp chí thành công vào cơ sở dữ liệu.',
                                title: 'Đăng ký thành công',
                              );
                            }
                            _loadAllData();
                          } catch (err) {
                            setModalState(() => isSubmitting = false);
                            if (context.mounted) {
                              AppNotification.showError(
                                context,
                                'Lỗi: $err',
                                title: 'Thao tác thất bại',
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Lưu tạp chí'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showQuickConfigDialog(
    BuildContext context,
    Map<String, dynamic> journal,
  ) {
    final journalId = journal['id'].toString();
    final journalTitle = journal['title']?.toString() ?? 'Tạp chí';
    final existingConfig = _getConfigForJournal(journalId);

    final domainController = TextEditingController(
      text: existingConfig != null
          ? (existingConfig['domain']?.toString() ??
                _getDomainForJournal(journal))
          : _getDomainForJournal(journal),
    );

    int yearStart = existingConfig != null
        ? (existingConfig['year_from'] ?? 2021)
        : 2021;
    int yearEnd = existingConfig != null
        ? (existingConfig['year_to'] ?? 2024)
        : 2024;
    int targetPapers = existingConfig != null
        ? (existingConfig['target_articles'] ?? 200)
        : 200;
    final targetController = TextEditingController(
      text: targetPapers.toString(),
    );

    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSoft,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      size: 20,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          existingConfig != null
                              ? 'Cập nhật cấu hình khai phá'
                              : 'Thiết lập cấu hình khai phá',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Manrope',
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          journalTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textMuted,
                            fontFamily: 'Manrope',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 520,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Lĩnh vực nghiên cứu (Domain) *',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        fontFamily: 'Manrope',
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: domainController,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        fontFamily: 'Manrope',
                      ),
                      decoration: InputDecoration(
                        hintText:
                            'Ví dụ: Bioinformatics & Computational Biology',
                        fillColor: AppColors.surfaceSoft,
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tự động xác định từ dữ liệu học thuật. Bạn có thể chỉnh sửa nếu cần.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        fontFamily: 'Manrope',
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Từ năm xuất bản',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Manrope',
                                ),
                              ),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<int>(
                                initialValue: yearStart,
                                decoration: InputDecoration(
                                  fillColor: AppColors.surfaceSoft,
                                  filled: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: AppColors.border,
                                    ),
                                  ),
                                ),
                                items:
                                    [
                                      2016,
                                      2017,
                                      2018,
                                      2019,
                                      2020,
                                      2021,
                                      2022,
                                      2023,
                                    ].map((y) {
                                      return DropdownMenuItem(
                                        value: y,
                                        child: Text(
                                          '$y',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontFamily: 'Manrope',
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setModalState(() => yearStart = val);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Đến năm xuất bản',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Manrope',
                                ),
                              ),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<int>(
                                initialValue: yearEnd,
                                decoration: InputDecoration(
                                  fillColor: AppColors.surfaceSoft,
                                  filled: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: AppColors.border,
                                    ),
                                  ),
                                ),
                                items:
                                    [
                                      2020,
                                      2021,
                                      2022,
                                      2023,
                                      2024,
                                      2025,
                                      2026,
                                      2027,
                                    ].map((y) {
                                      return DropdownMenuItem(
                                        value: y,
                                        child: Text(
                                          '$y',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontFamily: 'Manrope',
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setModalState(() => yearEnd = val);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.l10n.targetPapersLabel,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Manrope',
                          ),
                        ),
                        Text(
                          context.l10n.papersCountLabel(targetPapers.toInt()),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            fontFamily: 'Manrope',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: targetController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Manrope',
                      ),
                      decoration: InputDecoration(
                        suffixText: context.l10n.papersUnit,
                        fillColor: AppColors.surfaceSoft,
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                      onChanged: (val) {
                        final parsed = int.tryParse(val);
                        if (parsed != null && parsed > 0) {
                          setModalState(() => targetPapers = parsed);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [30, 50, 100, 200, 300, 500].map((preset) {
                        final isSelected = targetPapers == preset;
                        return InkWell(
                          onTap: () {
                            setModalState(() {
                              targetPapers = preset;
                              targetController.text = preset.toString();
                            });
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.textPrimary
                                  : AppColors.surfaceSoft,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.textPrimary
                                    : AppColors.border,
                              ),
                            ),
                            child: Text(
                              context.l10n.papersCountLabel(preset),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                                fontFamily: 'Manrope',
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.code_rounded,
                            size: 16,
                            color: AppColors.textPrimary,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Cấu trúc đầu ra: Toàn văn TEI XML',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                    fontFamily: 'Manrope',
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Động cơ Grobid tự động bóc tách Abstract, Sections, References & Sentences.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                    fontFamily: 'Manrope',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                if (existingConfig != null)
                  TextButton.icon(
                    onPressed: isSaving
                        ? null
                        : () async {
                            final configId = existingConfig['id'].toString();
                            setModalState(() => isSaving = true);
                            try {
                              await _apiClient.deleteConfiguration(configId);
                              if (ctx.mounted) Navigator.of(ctx).pop();
                              if (context.mounted) {
                                AppNotification.showSuccess(
                                  context,
                                  'Đã xóa cấu hình khai phá.',
                                  title: 'Thao tác thành công',
                                );
                              }
                              _loadAllData();
                            } catch (e) {
                              setModalState(() => isSaving = false);
                              if (context.mounted) {
                                AppNotification.showError(
                                  context,
                                  'Lỗi: $e',
                                  title: 'Xóa thất bại',
                                );
                              }
                            }
                          },
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 16,
                      color: AppColors.error,
                    ),
                    label: const Text(
                      'Xóa cấu hình',
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: 12,
                        fontFamily: 'Manrope',
                      ),
                    ),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.of(ctx).pop(),
                  child: const Text(
                    'Đóng',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontFamily: 'Manrope',
                    ),
                  ),
                ),
                OutlinedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final domain = domainController.text.trim();
                          if (domain.isEmpty) {
                            AppNotification.showWarning(
                              context,
                              'Vui lòng nhập tên lĩnh vực nghiên cứu.',
                            );
                            return;
                          }
                          if (yearStart > yearEnd) {
                            AppNotification.showWarning(
                              context,
                              'Năm bắt đầu không được lớn hơn năm kết thúc.',
                            );
                            return;
                          }

                          setModalState(() => isSaving = true);
                          try {
                            if (existingConfig != null) {
                              final configId = existingConfig['id'].toString();
                              await _apiClient.updateConfiguration(
                                configId,
                                domain: domain,
                                yearFrom: yearStart,
                                yearTo: yearEnd,
                                targetArticles: targetPapers,
                              );
                            } else {
                              await _apiClient.createConfiguration(
                                journalId: journalId,
                                domain: domain,
                                yearFrom: yearStart,
                                yearTo: yearEnd,
                                targetArticles: targetPapers,
                                referenceCorpusName: 'Academic Core Corpus',
                              );
                            }

                            if (ctx.mounted) Navigator.of(ctx).pop();
                            if (context.mounted) {
                              AppNotification.showSuccess(
                                context,
                                'Đã lưu cấu hình cho "$journalTitle" thành công.',
                                title: 'Lưu cấu hình thành công',
                              );
                            }
                            _loadAllData();
                          } catch (err) {
                            setModalState(() => isSaving = false);
                            if (context.mounted) {
                              AppNotification.showError(
                                context,
                                'Lỗi: $err',
                                title: 'Lưu cấu hình thất bại',
                              );
                            }
                          }
                        },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Lưu cấu hình',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Manrope',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final domain = domainController.text.trim();
                          if (domain.isEmpty) {
                            AppNotification.showWarning(
                              context,
                              'Vui lòng nhập tên lĩnh vực nghiên cứu.',
                            );
                            return;
                          }
                          if (yearStart > yearEnd) {
                            AppNotification.showWarning(
                              context,
                              'Năm bắt đầu không được lớn hơn năm kết thúc.',
                            );
                            return;
                          }

                          setModalState(() => isSaving = true);
                          try {
                            String activeConfigId;
                            if (existingConfig != null) {
                              activeConfigId = existingConfig['id'].toString();
                              await _apiClient.updateConfiguration(
                                activeConfigId,
                                domain: domain,
                                yearFrom: yearStart,
                                yearTo: yearEnd,
                                targetArticles: targetPapers,
                              );
                            } else {
                              final created = await _apiClient
                                  .createConfiguration(
                                    journalId: journalId,
                                    domain: domain,
                                    yearFrom: yearStart,
                                    yearTo: yearEnd,
                                    targetArticles: targetPapers,
                                    referenceCorpusName: 'Academic Core Corpus',
                                  );
                              activeConfigId = created['id']?.toString() ?? '';
                            }

                            if (ctx.mounted) Navigator.of(ctx).pop();
                            await _loadAllData();

                            if (activeConfigId.isNotEmpty) {
                              await _triggerAnalysis(
                                activeConfigId,
                                journalTitle,
                              );
                            }
                          } catch (err) {
                            setModalState(() => isSaving = false);
                            if (context.mounted) {
                              AppNotification.showError(
                                context,
                                'Lỗi: $err',
                                title: 'Khởi chạy thất bại',
                              );
                            }
                          }
                        },
                  icon: isSaving
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.bolt_rounded, size: 16),
                  label: const Text(
                    'Lưu & Khởi chạy ngay',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Manrope',
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final configuredCount = _journals
        .where((j) => _getConfigForJournal(j['id'].toString()) != null)
        .length;
    final unconfiguredCount = _journals.length - configuredCount;

    final domains =
        _journals
            .map((j) => _getDomainForJournal(j))
            .where((d) => d.trim().isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    final filteredJournals = _journals.where((j) {
      final title = (j['title'] ?? '').toString().toLowerCase();
      final issn = (j['issn_l'] ?? '').toString().toLowerCase();
      final publisher = (j['publisher'] ?? '').toString().toLowerCase();
      final domain = _getDomainForJournal(j).toLowerCase();
      final q = _searchQuery.toLowerCase();

      final matchesSearch =
          title.contains(q) ||
          issn.contains(q) ||
          publisher.contains(q) ||
          domain.contains(q);
      final matchesDomain =
          _selectedDomain == null || _getDomainForJournal(j) == _selectedDomain;

      final hasConfig = _getConfigForJournal(j['id'].toString()) != null;
      bool matchesStatus = true;
      if (_filterStatus == 'configured') {
        matchesStatus = hasConfig;
      } else if (_filterStatus == 'unconfigured') {
        matchesStatus = !hasConfig;
      }

      return matchesSearch && matchesDomain && matchesStatus;
    }).toList();

    // Auto-select first journal if available and none selected yet for zero-friction
    if (_selectedJournal == null && filteredJournals.isNotEmpty) {
      _selectedJournal = filteredJournals.first;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1150;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header
              _buildTopHeader(context),
              const SizedBox(height: 20),

              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column: Catalog (flex 5)
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSearchAndFilterToolbar(
                            domains,
                            configuredCount,
                            unconfiguredCount,
                          ),
                          const SizedBox(height: 16),
                          _buildJournalCatalogList(filteredJournals),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Right Column: Command Center (flex 6)
                    Expanded(
                      flex: 6,
                      child: _selectedJournal != null
                          ? JournalCommandCenterPanel(
                              key: ValueKey(_selectedJournal!['id']),
                              journal: _selectedJournal!,
                              initialConfig: _getConfigForJournal(
                                _selectedJournal!['id'].toString(),
                              ),
                              onNavigateToTab: widget.onNavigateToTab,
                              onRefreshParent: _loadAllData,
                            )
                          : _buildEmptyCommandCenterPlaceholder(),
                    ),
                  ],
                )
              else
                // Mobile/Tablet: Stacked view
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_selectedJournal != null) ...[
                      JournalCommandCenterPanel(
                        key: ValueKey(_selectedJournal!['id']),
                        journal: _selectedJournal!,
                        initialConfig: _getConfigForJournal(
                          _selectedJournal!['id'].toString(),
                        ),
                        onNavigateToTab: widget.onNavigateToTab,
                        onRefreshParent: _loadAllData,
                      ),
                      const SizedBox(height: 24),
                    ],
                    _buildSearchAndFilterToolbar(
                      domains,
                      configuredCount,
                      unconfiguredCount,
                    ),
                    const SizedBox(height: 16),
                    _buildJournalCatalogList(filteredJournals),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.journalsCatalogTitle,
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
                context.l10n.journalsCatalogSubtitle,
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
              onPressed: _loadAllData,
              icon: const Icon(Icons.refresh_rounded),
              tooltip: context.l10n.reloadList,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () => _showAddJournalDialog(context),
              icon: const Icon(Icons.post_add_rounded, size: 18),
              label: Text(
                context.l10n.addJournalManual,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Manrope',
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.border),
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
    );
  }

  Widget _buildSearchAndFilterToolbar(
    List<String> domains,
    int configuredCount,
    int unconfiguredCount,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SearchInputBox(
                  controller: _searchController,
                  height: 38,
                  hintText: context.l10n.searchJournalPlaceholder,
                  onChanged: (val) => setState(() {
                    _searchQuery = val;
                    _currentPage = 1;
                  }),
                  onSubmitted: (val) => _searchOpenAlex(val),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: _searchQuery.trim().isEmpty || _isSearchingOpenAlex
                    ? null
                    : () => _searchOpenAlex(_searchQuery),
                icon: _isSearchingOpenAlex
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.travel_explore_rounded, size: 16),
                label: const Text(
                  'OpenAlex',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Manrope',
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.textPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _buildStatusFilterChip(
                  'all',
                  '${context.l10n.filterAll} (${_journals.length})',
                ),
                _buildStatusFilterChip(
                  'configured',
                  '${context.l10n.filterConfigured} ($configuredCount)',
                ),
                _buildStatusFilterChip(
                  'unconfigured',
                  '${context.l10n.filterUnconfigured} ($unconfiguredCount)',
                ),
                if (domains.isNotEmpty) ...[_buildDomainFilterMenu(domains)],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilterChip(String status, String label) {
    final isSelected = _filterStatus == status;
    return InkWell(
      onTap: () => setState(() {
        _filterStatus = status;
        _currentPage = 1;
      }),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.textPrimary : AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.textPrimary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontFamily: 'Manrope',
          ),
        ),
      ),
    );
  }

  Widget _buildDomainFilterMenu(List<String> domains) {
    final bool isFiltered = _selectedDomain != null;

    return Theme(
      data: Theme.of(context).copyWith(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
      ),
      child: PopupMenuButton<String>(
        tooltip: context.l10n.filterByDomain,
        position: PopupMenuPosition.under,
        offset: const Offset(0, 6),
        elevation: 8,
        shadowColor: Colors.black.withAlpha(46),
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
        onSelected: (val) {
          setState(() {
            _selectedDomain = val.isEmpty ? null : val;
            _currentPage = 1;
          });
        },
        itemBuilder: (context) {
          final items = <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: '',
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: _selectedDomain == null
                      ? AppColors.sidebarActive
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _selectedDomain == null
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      size: 15,
                      color: _selectedDomain == null
                          ? AppColors.primary
                          : AppColors.textSubtle.withAlpha(102),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.l10n.filterAll,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: _selectedDomain == null
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: _selectedDomain == null
                              ? AppColors.primary
                              : AppColors.textPrimary,
                          fontFamily: 'Manrope',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ];

          for (final d in domains) {
            final isCurrent = d == _selectedDomain;
            items.add(
              PopupMenuItem<String>(
                value: d,
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? AppColors.sidebarActive
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isCurrent
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        size: 15,
                        color: isCurrent
                            ? AppColors.primary
                            : AppColors.textSubtle.withAlpha(102),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          d,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isCurrent
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isCurrent
                                ? AppColors.primary
                                : AppColors.textPrimary,
                            fontFamily: 'Manrope',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          return items;
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isFiltered ? AppColors.sidebarActive : AppColors.surfaceSoft,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isFiltered ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.category_outlined,
                size: 13,
                color: isFiltered ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 5),
              Text(
                _selectedDomain ?? context.l10n.domainLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isFiltered
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  fontFamily: 'Manrope',
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 15,
                color: isFiltered ? AppColors.primary : AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJournalCatalogList(List<Map<String, dynamic>> filteredJournals) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
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
                onPressed: _loadAllData,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text(context.l10n.retry),
              ),
            ],
          ),
        ),
      );
    }

    if (filteredJournals.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: _buildEmptyOrOpenAlexFallback(),
      );
    }

    final totalCount = filteredJournals.length;
    final totalPages = (totalCount / _pageSize).ceil();
    final safeTotalPages = totalPages > 0 ? totalPages : 1;
    if (_currentPage > safeTotalPages) {
      _currentPage = safeTotalPages;
    }
    final startIndex = (_currentPage - 1) * _pageSize;
    final paginatedJournals = filteredJournals
        .skip(startIndex)
        .take(_pageSize)
        .toList();

    return Column(
      children: [
        for (final journal in paginatedJournals) _buildJournalCard(journal),
        if (totalCount > _pageSize) ...[
          const SizedBox(height: 12),
          _buildPaginationBar(totalCount, safeTotalPages),
        ],
        if (_openAlexResults.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _buildOpenAlexHeaderBanner(),
                for (int i = 0; i < _openAlexResults.length; i++) ...[
                  _buildOpenAlexJournalRow(_openAlexResults[i]),
                  if (i < _openAlexResults.length - 1)
                    const Divider(height: 1, color: AppColors.borderSoft),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPaginationBar(int totalCount, int totalPages) {
    if (totalCount <= _pageSize) return const SizedBox.shrink();

    final startIndex = (_currentPage - 1) * _pageSize + 1;
    final endIndex = math.min(_currentPage * _pageSize, totalCount);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            context.l10n.showingJournalsRange(startIndex, endIndex, totalCount),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
              fontFamily: 'Manrope',
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                color: _currentPage > 1
                    ? AppColors.primary
                    : AppColors.slate300,
                onPressed: _currentPage > 1
                    ? () => setState(() => _currentPage--)
                    : null,
                tooltip: context.l10n.prevPageTooltip,
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.borderSoft),
                ),
                child: Text(
                  context.l10n.pageCountLabel(_currentPage, totalPages),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFamily: 'Manrope',
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                color: _currentPage < totalPages
                    ? AppColors.primary
                    : AppColors.slate300,
                onPressed: _currentPage < totalPages
                    ? () => setState(() => _currentPage++)
                    : null,
                tooltip: context.l10n.nextPageTooltip,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJournalCard(Map<String, dynamic> journal) {
    final journalId = journal['id'].toString();
    final title = journal['title'] ?? context.l10n.unknown;
    final publisher = journal['publisher'] ?? context.l10n.unknownPublisher;
    final issn =
        journal['issn_l'] ??
        ((journal['issns'] is List && (journal['issns'] as List).isNotEmpty)
            ? journal['issns'][0].toString()
            : 'N/A');
    final worksCount = journal['works_count'] ?? 0;
    final domain = _getDomainForJournal(journal);

    final config = _getConfigForJournal(journalId);
    final isConfigured = config != null;
    final isSelected =
        _selectedJournal != null &&
        _selectedJournal!['id'].toString() == journalId;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.blue50 : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: isSelected ? 1.8 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppColors.primary.withAlpha(25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedJournal = journal;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Radio/Check indicator
                Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.only(top: 2, right: 10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.surfaceSoft,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 13, color: Colors.white)
                      : null,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                                fontFamily: 'Manrope',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isConfigured)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.green100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                context.l10n.configured,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.green700,
                                  fontFamily: 'Manrope',
                                ),
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceSoft,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Text(
                                context.l10n.notConfigured,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textMuted,
                                  fontFamily: 'Manrope',
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        publisher,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                          fontFamily: 'Manrope',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSoft,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(
                              domain,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                                fontFamily: 'Manrope',
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'ISSN: $issn',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              fontFamily: 'Manrope',
                            ),
                          ),
                          const Spacer(),
                          Text(
                            context.l10n.papersCountLabel(worksCount),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted,
                              fontFamily: 'Manrope',
                            ),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            onPressed: () =>
                                _showQuickConfigDialog(context, journal),
                            icon: const Icon(Icons.tune_rounded, size: 14),
                            tooltip: context.l10n.configDetailsTooltip,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            color: AppColors.textMuted,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCommandCenterPlaceholder() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.auto_stories_rounded,
                size: 28,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              context.l10n.miningCenterTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                fontFamily: 'Manrope',
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Text(
                context.l10n.miningCenterDesc,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                  fontFamily: 'Manrope',
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 22),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildFeatureBadge(
                  Icons.bolt_rounded,
                  context.l10n.badge1Touch,
                ),
                _buildFeatureBadge(
                  Icons.account_tree_rounded,
                  context.l10n.badgeTeiXml,
                ),
                _buildFeatureBadge(
                  Icons.psychology_rounded,
                  context.l10n.badgeNlpStyle,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              fontFamily: 'Manrope',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyOrOpenAlexFallback() {
    if (_isSearchingOpenAlex) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Center(
          child: Column(
            children: [
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n.openAlexSearchingGlobal(_searchQuery),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontFamily: 'Manrope',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                context.l10n.openAlexConnectingDesc,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  fontFamily: 'Manrope',
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_openAlexSearchError != null) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 40,
                color: AppColors.error,
              ),
              const SizedBox(height: 12),
              Text(
                'Lỗi kết nối OpenAlex: $_openAlexSearchError',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.error,
                  fontFamily: 'Manrope',
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _searchOpenAlex(_searchQuery),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text(context.l10n.retry),
              ),
            ],
          ),
        ),
      );
    }

    if (_openAlexResults.isNotEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            _buildOpenAlexHeaderBanner(),
            for (int i = 0; i < _openAlexResults.length; i++) ...[
              _buildOpenAlexJournalRow(_openAlexResults[i]),
              if (i < _openAlexResults.length - 1)
                const Divider(height: 1, color: AppColors.borderSoft),
            ],
          ],
        ),
      );
    }

    if (_lastSearchedOpenAlexQuery != null &&
        _lastSearchedOpenAlexQuery == _searchQuery.trim() &&
        _openAlexResults.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            children: [
              const Icon(
                Icons.search_off_rounded,
                size: 40,
                color: AppColors.textSubtle,
              ),
              const SizedBox(height: 12),
              Text(
                context.l10n.noJournalFoundOpenAlex,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontFamily: 'Manrope',
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.l10n.tryAnotherKeywords,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  fontFamily: 'Manrope',
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_searchQuery.trim().isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 580),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.textPrimary.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.travel_explore_rounded,
                    color: AppColors.textPrimary,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  context.l10n.notFoundInLocalDb(_searchQuery),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFamily: 'Manrope',
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.l10n.notStoredInSystemDesc,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontFamily: 'Manrope',
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: () => _searchOpenAlex(_searchQuery),
                  icon: const Icon(Icons.travel_explore_rounded, size: 16),
                  label: Text(context.l10n.lookupOnOpenAlexBtn(_searchQuery)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.textPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_journals.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(48),
        child: Center(
          child: Column(
            children: [
              const Icon(
                Icons.filter_list_off_rounded,
                size: 40,
                color: AppColors.textSubtle,
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.noJournalsMatchedFilter,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontFamily: 'Manrope',
                ),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () => setState(() {
                  _filterStatus = 'all';
                  _selectedDomain = null;
                  _currentPage = 1;
                }),
                icon: const Icon(Icons.clear_all_rounded, size: 16),
                label: Text(
                  context.l10n.clearFilter,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Manrope',
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(48),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.menu_book_outlined,
              size: 40,
              color: AppColors.textSubtle,
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.noJournalsInDb,
              style: TextStyle(
                color: AppColors.textMuted,
                fontFamily: 'Manrope',
              ),
            ),
            const SizedBox(height: 6),
            Text(
              context.l10n.searchOrManualHint,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSubtle,
                fontFamily: 'Manrope',
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () => _showAddJournalDialog(context),
              icon: const Icon(Icons.post_add_rounded, size: 16),
              label: Text(
                context.l10n.manualEntryBtn,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Manrope',
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOpenAlexHeaderBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surfaceSoft,
        border: Border(bottom: BorderSide(color: AppColors.borderSoft)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.travel_explore_rounded,
            size: 18,
            color: AppColors.textPrimary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.l10n.openAlexResultsCount(_openAlexResults.length),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontFamily: 'Manrope',
              ),
            ),
          ),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _openAlexResults = [];
                _lastSearchedOpenAlexQuery = null;
              });
            },
            icon: const Icon(Icons.close_rounded, size: 14),
            label: Text(
              context.l10n.hideOpenAlexResults,
              style: TextStyle(fontSize: 11),
            ),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpenAlexJournalRow(Map<String, dynamic> journal) {
    final title = journal['title'] ?? context.l10n.unknown;
    final publisher = journal['publisher'] ?? context.l10n.unknownPublisher;
    final issn =
        journal['issn_l'] ??
        ((journal['issns'] is List && (journal['issns'] as List).isNotEmpty)
            ? journal['issns'][0].toString()
            : 'N/A');
    final worksCount = journal['works_count'] ?? 0;
    final citedCount = journal['cited_by_count'] ?? 0;
    final openalexId = journal['openalex_id']?.toString() ?? '';
    final isImported = journal['is_imported'] == true;
    final isImporting = _importingIds.contains(openalexId);

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Title, OpenAlex badge & Action button
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              fontFamily: 'Manrope',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(20),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'OpenAlex',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                              fontFamily: 'Manrope',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      publisher,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        fontFamily: 'Manrope',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Action Button / Status
              if (isImported)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.green50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.green100),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 16,
                        color: AppColors.green700,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        context.l10n.importedToDb,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.green700,
                          fontFamily: 'Manrope',
                        ),
                      ),
                    ],
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: isImporting
                      ? null
                      : () => _importOpenAlexJournal(journal),
                  icon: isImporting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.add_rounded, size: 16),
                  label: Text(
                    isImporting
                        ? context.l10n.importingToDb
                        : context.l10n.importToDbBtn,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Manrope',
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Bottom Row: Metadata tags
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // ISSN Tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.tag_rounded,
                      size: 12,
                      color: AppColors.textSubtle,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'ISSN: $issn',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        fontFamily: 'Manrope',
                      ),
                    ),
                  ],
                ),
              ),

              // Works & Citations Tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.menu_book_rounded,
                      size: 12,
                      color: AppColors.textSubtle,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      context.l10n.worksAndCitations(worksCount, citedCount),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontFamily: 'Manrope',
                      ),
                    ),
                  ],
                ),
              ),

              // Status Tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isImported
                      ? AppColors.green100
                      : AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isImported
                      ? context.l10n.savedInSystem
                      : context.l10n.notImportedToDb,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isImported
                        ? AppColors.green700
                        : AppColors.textMuted,
                    fontFamily: 'Manrope',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
