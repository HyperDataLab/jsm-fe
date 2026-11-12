import '../../../../core/localization/app_localizations.dart';

import 'package:material_ui/material_ui.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_notification.dart';
import '../../data/datasources/admin_api_client.dart';

class ConfigurationsView extends StatefulWidget {
  final Function(int) onNavigateToTab;
  final VoidCallback? onTriggerNewAnalysis;

  const ConfigurationsView({
    super.key,
    required this.onNavigateToTab,
    this.onTriggerNewAnalysis,
  });

  @override
  State<ConfigurationsView> createState() => _ConfigurationsViewState();
}

class _ConfigurationsViewState extends State<ConfigurationsView> {
  final AdminApiClient _apiClient = AdminApiClient();
  List<Map<String, dynamic>> _configs = [];
  List<Map<String, dynamic>> _journals = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _apiClient.getConfigurations(),
        _apiClient.getJournals(),
      ]);
      if (!mounted) return;
      setState(() {
        _configs = results[0];
        _journals = results[1];
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

  String _getDomainForJournal(String journalId) {
    // 1. Check if journal has field in its object (from OpenAlex or DB)
    final j = _journals.firstWhere(
      (j) => j['id']?.toString() == journalId,
      orElse: () => {},
    );
    if (j.isNotEmpty && (j['field'] ?? '').toString().trim().isNotEmpty) {
      return j['field'].toString();
    }

    // 2. Check if journal already has a configuration with a domain
    final cfg = _configs.firstWhere(
      (c) =>
          c['journal_id']?.toString() == journalId ||
          c['journal']?['id']?.toString() == journalId,
      orElse: () => {},
    );
    if (cfg.isNotEmpty && (cfg['domain'] ?? '').toString().trim().isNotEmpty) {
      return cfg['domain'].toString();
    }

    // 3. Fallback based on keywords in journal title
    if (j.isNotEmpty) {
      final title = (j['title'] ?? '').toString().toLowerCase();
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
    }

    return context.l10n.defaultDomainCs;
  }

  void _showConfigDialog(BuildContext context) {
    if (_journals.isEmpty) {
      AppNotification.showWarning(
        context,
        context.l10n.needAtLeastOneJournalConfig,
      );
      return;
    }

    String selectedJournalId = _journals.first['id'].toString();
    int yearStart = 2021;
    int yearEnd = 2024;
    double targetPapers = 200;
    final domainController = TextEditingController(
      text: _getDomainForJournal(selectedJournalId),
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
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                context.l10n.newMiningConfigTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Manrope',
                  color: AppColors.textPrimary,
                ),
              ),
              content: SizedBox(
                width: 480,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.newMiningConfigDesc,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                        fontFamily: 'Manrope',
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      context.l10n.applicableJournalRequired,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        fontFamily: 'Manrope',
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selectedJournalId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                      items: _journals.map((j) {
                        return DropdownMenuItem<String>(
                          value: j['id'].toString(),
                          child: Text(
                            '${j['title']} (${j['issn_l'] ?? 'No ISSN'})',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                              fontFamily: 'Manrope',
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() {
                            selectedJournalId = val;
                            domainController.text = _getDomainForJournal(val);
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.l10n.researchDomainRequired,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        fontFamily: 'Manrope',
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: domainController,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        fontFamily: 'Manrope',
                      ),
                      decoration: InputDecoration(
                        hintText: context.l10n.domainPlaceholder,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.l10n.domainSyncNote,
                      style: const TextStyle(
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
                              Text(
                                context.l10n.fromYearLabel,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Manrope',
                                ),
                              ),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<int>(
                                initialValue: yearStart,
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                ),
                                items: [2018, 2019, 2020, 2021, 2022, 2023].map(
                                  (y) {
                                    return DropdownMenuItem(
                                      value: y,
                                      child: Text(
                                        '$y',
                                        style: const TextStyle(
                                          fontFamily: 'Manrope',
                                        ),
                                      ),
                                    );
                                  },
                                ).toList(),
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
                              Text(
                                context.l10n.toYearLabel,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Manrope',
                                ),
                              ),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<int>(
                                initialValue: yearEnd,
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                ),
                                items: [2022, 2023, 2024, 2025, 2026].map((y) {
                                  return DropdownMenuItem(
                                    value: y,
                                    child: Text(
                                      '$y',
                                      style: const TextStyle(
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
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.l10n.targetPapersLabel,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Manrope',
                          ),
                        ),
                        Text(
                          context.l10n.papersCountLabel(targetPapers.toInt()),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            fontFamily: 'Manrope',
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: targetPapers,
                      min: 20,
                      max: 500,
                      divisions: 48,
                      activeColor: AppColors.primary,
                      onChanged: (val) {
                        setModalState(() => targetPapers = val);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.of(ctx).pop(),
                  child: Text(context.l10n.cancel),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final domain = domainController.text.trim();
                          if (domain.isEmpty) {
                            AppNotification.showWarning(
                              context,
                              context.l10n.enterDomainWarning,
                            );
                            return;
                          }

                          setModalState(() => isSaving = true);
                          try {
                            await _apiClient.createConfiguration(
                              journalId: selectedJournalId,
                              domain: domain,
                              yearFrom: yearStart,
                              yearTo: yearEnd,
                              targetArticles: targetPapers.toInt(),
                              referenceCorpusName: 'Academic Core Corpus',
                            );
                            if (ctx.mounted) Navigator.of(ctx).pop();
                            if (context.mounted) {
                              AppNotification.showSuccess(
                                context,
                                context.l10n.configCreatedSuccess,
                                title: 'Tạo cấu hình thành công',
                              );
                            }
                            _loadData();
                          } catch (err) {
                            setModalState(() => isSaving = false);
                            if (context.mounted) {
                              AppNotification.showError(
                                context,
                                'Lỗi: $err',
                                title: 'Tạo cấu hình thất bại',
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
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Lưu cấu hình'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _triggerAnalysis(String configId, String journalName) async {
    try {
      await _apiClient.triggerAnalysis(configId);
      if (mounted) {
        AppNotification.showSuccess(
          context,
          'Đã kích hoạt chu trình phân tích cho: $journalName',
          title: 'Kích hoạt thành công',
          icon: Icons.bolt_rounded,
        );
        widget.onNavigateToTab(3); // Navigate to Job Monitor
      }
    } catch (e) {
      if (mounted) {
        AppNotification.showError(
          context,
          'Lỗi kích hoạt: $e',
          title: 'Kích hoạt thất bại',
        );
      }
    }
  }

  Future<void> _deleteConfig(String configId) async {
    try {
      await _apiClient.deleteConfiguration(configId);
      if (mounted) {
        AppNotification.showSuccess(
          context,
          'Đã xóa cấu hình khai phá.',
          title: 'Thao tác thành công',
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        AppNotification.showError(
          context,
          'Lỗi: $e',
          title: context.l10n.jobDeleteFailedTitle,
        );
      }
    }
  }

  Future<void> _updateYearFrom(Map<String, dynamic> config, int newYear) async {
    final configId = config['id'].toString();
    final oldYear = config['year_from'] ?? 2021;
    final yearTo = (config['year_to'] ?? 2024) as int;

    if (newYear > yearTo) {
      AppNotification.showWarning(
        context,
        context.l10n.startYearGreaterThanEndYear,
      );
      return;
    }

    setState(() {
      config['year_from'] = newYear;
    });

    try {
      await _apiClient.updateConfiguration(configId, yearFrom: newYear);
      if (!mounted) return;
      AppNotification.showSuccess(
        context,
        'Đã cập nhật năm bắt đầu: $newYear',
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        config['year_from'] = oldYear;
      });
      AppNotification.showError(
        context,
        'Lỗi cập nhật: $e',
        title: 'Cập nhật thất bại',
      );
    }
  }

  Future<void> _updateYearTo(Map<String, dynamic> config, int newYear) async {
    final configId = config['id'].toString();
    final oldYear = config['year_to'] ?? 2024;
    final yearFrom = (config['year_from'] ?? 2021) as int;

    if (newYear < yearFrom) {
      AppNotification.showWarning(
        context,
        'Năm kết thúc không được nhỏ hơn năm bắt đầu.',
      );
      return;
    }

    setState(() {
      config['year_to'] = newYear;
    });

    try {
      await _apiClient.updateConfiguration(configId, yearTo: newYear);
      if (!mounted) return;
      AppNotification.showSuccess(
        context,
        'Đã cập nhật năm kết thúc: $newYear',
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        config['year_to'] = oldYear;
      });
      AppNotification.showError(
        context,
        'Lỗi cập nhật: $e',
        title: 'Cập nhật thất bại',
      );
    }
  }

  void _showEditTargetArticlesDialog(Map<String, dynamic> config) {
    final configId = config['id'].toString();
    final currentTarget = (config['target_articles'] ?? 200) as int;
    final controller = TextEditingController(text: currentTarget.toString());
    int selectedValue = currentTarget;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  const Icon(
                    Icons.tune_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    context.l10n.targetPapersLabel,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Manrope',
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 380,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.targetPapersHelp,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                        fontFamily: 'Manrope',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Manrope',
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        labelText: context.l10n.targetPapersCount,
                        suffixText: context.l10n.papersUnit,
                        suffixStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                        fillColor: AppColors.surfaceSoft,
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onChanged: (val) {
                        final parsed = int.tryParse(val);
                        if (parsed != null) {
                          setDialogState(() => selectedValue = parsed);
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Chọn nhanh:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSubtle,
                        fontFamily: 'Manrope',
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [30, 50, 100, 200, 300, 500].map((preset) {
                        final isSelected = selectedValue == preset;
                        return InkWell(
                          onTap: () {
                            setDialogState(() {
                              selectedValue = preset;
                              controller.text = preset.toString();
                            });
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.surfaceSoft,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
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
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(context.l10n.cancel),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final count =
                        int.tryParse(controller.text.trim()) ?? selectedValue;
                    if (count < 5 || count > 5000) {
                      AppNotification.showWarning(
                        context,
                        'Vui lòng nhập số lượng từ 5 đến 5000 bài.',
                      );
                      return;
                    }

                    Navigator.of(ctx).pop();

                    final oldCount = config['target_articles'];
                    setState(() {
                      config['target_articles'] = count;
                    });

                    try {
                      await _apiClient.updateConfiguration(
                        configId,
                        targetArticles: count,
                      );
                      if (context.mounted) {
                        AppNotification.showSuccess(
                          context,
                          context.l10n.updatedTargetPapers(count),
                          duration: const Duration(seconds: 2),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        setState(() {
                          config['target_articles'] = oldCount;
                        });
                        AppNotification.showError(
                          context,
                          'Lỗi: $e',
                          title: 'Cập nhật thất bại',
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
                  child: const Text('Lưu thay đổi'),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.configSystemParams,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontFamily: 'Manrope',
                      letterSpacing: -0.4,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    context.l10n.configSectionDesc,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textMuted,
                      fontFamily: 'Manrope',
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: _loadData,
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: context.l10n.reloadList,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showConfigDialog(context),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Thiết lập cấu hình mới'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
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
              ),
            ],
          ),
          const SizedBox(height: 24),

          // State Handling
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(64),
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
                      onPressed: _loadData,
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            )
          else if (_configs.isEmpty)
            Padding(
              padding: const EdgeInsets.all(48),
              child: Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.tune_rounded,
                      size: 48,
                      color: AppColors.slate300,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Chưa có cấu hình khai phá nào được tạo.',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontFamily: 'Manrope',
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _showConfigDialog(context),
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Tạo cấu hình đầu tiên'),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: [
                for (int i = 0; i < _configs.length; i++) ...[
                  _buildConfigCard(_configs[i]),
                  if (i < _configs.length - 1) const SizedBox(height: 16),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildConfigCard(Map<String, dynamic> config) {
    final journal = config['journal'] as Map<String, dynamic>?;
    final journalTitle = journal?['title'] ?? 'Tạp chí áp dụng';
    final domain = config['domain'] ?? 'Khoa học tổng hợp';
    final yearFrom = config['year_from'] ?? 2021;
    final yearTo = config['year_to'] ?? 2024;
    final targetArticles = config['target_articles'] ?? 200;
    final isActive = config['is_active'] ?? true;
    final configId = config['id'].toString();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? AppColors.primary.withAlpha(80) : AppColors.border,
          width: isActive ? 1.5 : 1,
        ),
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
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.blue50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            domain,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              fontFamily: 'Manrope',
                            ),
                          ),
                          if (isActive) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.blue50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Active Profile',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                  fontFamily: 'Manrope',
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Áp dụng cho: $journalTitle',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          fontFamily: 'Manrope',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _deleteConfig(configId),
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 16,
                      color: AppColors.error,
                    ),
                    label: const Text(
                      'Xóa',
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: 12,
                        fontFamily: 'Manrope',
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () => _triggerAnalysis(configId, journalTitle),
                    icon: const Icon(Icons.bolt_rounded, size: 16),
                    label: const Text('Khai phá ngay'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
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
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: AppColors.borderSoft),
          const SizedBox(height: 14),

          // Interactive specs row
          Row(
            children: [
              // 1. Interactive Year Range Picker (No box, black text)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 12,
                          color: AppColors.textSubtle,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'KHOẢNG NĂM KHẢO SÁT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSubtle,
                            fontFamily: 'Manrope',
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildYearPickerButton(
                          currentYear: yearFrom,
                          years: const [
                            2016,
                            2017,
                            2018,
                            2019,
                            2020,
                            2021,
                            2022,
                            2023,
                            2024,
                          ],
                          tooltip: 'Bấm chọn năm bắt đầu',
                          onSelected: (y) => _updateYearFrom(config, y),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            '–',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        _buildYearPickerButton(
                          currentYear: yearTo,
                          years: const [
                            2020,
                            2021,
                            2022,
                            2023,
                            2024,
                            2025,
                            2026,
                            2027,
                          ],
                          tooltip: 'Bấm chọn năm kết thúc',
                          onSelected: (y) => _updateYearTo(config, y),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 2. Interactive Target Articles (Opens edit dialog, text đen, no box, no pencil icon)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.description_outlined,
                          size: 12,
                          color: AppColors.textSubtle,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'MỤC TIÊU BÀI BÁO',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSubtle,
                            fontFamily: 'Manrope',
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Tooltip(
                      message: context.l10n.clickToChangeTarget,
                      child: InkWell(
                        onTap: () => _showEditTargetArticlesDialog(config),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              context.l10n.articlesCountLabel(targetArticles),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                fontFamily: 'Manrope',
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.edit_outlined,
                              size: 14,
                              color: AppColors.textPrimary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Grobid Parser Mode
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.code_rounded,
                          size: 12,
                          color: AppColors.textSubtle,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'CHẾ ĐỘ GROBID PARSER',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSubtle,
                            fontFamily: 'Manrope',
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Toàn văn TEI XML (Sections, Moves)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        fontFamily: 'Manrope',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildYearPickerButton({
    required int currentYear,
    required List<int> years,
    required String tooltip,
    required Function(int) onSelected,
  }) {
    return PopupMenuButton<int>(
      tooltip: tooltip,
      initialValue: currentYear,
      onSelected: onSelected,
      position: PopupMenuPosition.under,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      itemBuilder: (ctx) {
        return years.map((y) {
          final isCurrent = y == currentYear;
          return PopupMenuItem<int>(
            value: y,
            height: 36,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$y',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                    color: isCurrent
                        ? AppColors.primary
                        : AppColors.textPrimary,
                    fontFamily: 'Manrope',
                  ),
                ),
                if (isCurrent)
                  const Icon(
                    Icons.check_rounded,
                    size: 14,
                    color: AppColors.primary,
                  ),
              ],
            ),
          );
        }).toList();
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$currentYear',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontFamily: 'Manrope',
            ),
          ),
          const SizedBox(width: 2),
          const Icon(
            Icons.arrow_drop_down_rounded,
            size: 18,
            color: AppColors.textPrimary,
          ),
        ],
      ),
    );
  }
}
