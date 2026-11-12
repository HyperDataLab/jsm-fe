import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_notification.dart';
import '../../data/datasources/manuscript_file_picker.dart';
import '../../domain/entities/target_journal.dart';
import '../cubit/student_manuscript_checker_cubit.dart';
import '../cubit/student_manuscript_checker_state.dart';
import '../../../../core/localization/app_localizations.dart';

class ManuscriptInputCard extends StatefulWidget {
  final StudentManuscriptCheckerInitial initialState;

  const ManuscriptInputCard({super.key, required this.initialState});

  @override
  State<ManuscriptInputCard> createState() => _ManuscriptInputCardState();
}

class _ManuscriptInputCardState extends State<ManuscriptInputCard>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final TextEditingController _textController;
  late final TextEditingController _journalIdController;

  String? _selectedJournalId;
  String? _selectedJournalTitle;
  bool _includeExemplars = true;
  String? _pickedFileName;
  List<int>? _pickedFileBytes;
  bool _isManualJournal = false;

  static const String _sampleManuscript = '''Introduction
Recent deep learning architectures have achieved impressive benchmarks in academic text analysis. However, prior approaches remain limited in their ability to detect subtle stylistic deviations in student research drafts. To address this critical gap, this paper introduces a profile-anchored manuscript verification pipeline.

Methods
We evaluated our feature extractor across three domain corpora using 10-fold cross validation. The network was trained using the AdamW optimizer with a learning rate of 0.001 and weight decay of 0.01. Sentences were parsed through a dependency tree to determine passive voice proportion and syntactic complexity.

Results
Our empirical experiments demonstrate that stylometric alignment scores correlate strongly with peer review acceptance rates.

Discussion
These findings highlight the necessity of providing immediate linguistic feedback to novice researchers before formal journal submission.''';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _textController = TextEditingController(
      text: widget.initialState.draftText ?? '',
    );
    _journalIdController = TextEditingController(
      text: widget.initialState.selectedJournalId ?? '',
    );
    _selectedJournalId = widget.initialState.selectedJournalId;
    _selectedJournalTitle = widget.initialState.selectedJournalTitle;
    _includeExemplars = widget.initialState.includeExemplars;
    _pickedFileName = widget.initialState.fileName;
    _pickedFileBytes = widget.initialState.fileBytes;

    if (widget.initialState.availableJournals.isNotEmpty &&
        _selectedJournalId == null) {
      final first = widget.initialState.availableJournals.first;
      _selectedJournalId = first.id;
      _selectedJournalTitle = first.title;
      _journalIdController.text = first.id;
    }
  }

  @override
  void didUpdateWidget(ManuscriptInputCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((_selectedJournalId == null || _selectedJournalId!.isEmpty) &&
        widget.initialState.availableJournals.isNotEmpty) {
      final first = widget.initialState.availableJournals.first;
      _selectedJournalId = first.id;
      _selectedJournalTitle = first.title;
      _journalIdController.text = first.id;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    _journalIdController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final file = await ManuscriptFilePickerSeam.picker();
    if (file != null) {
      setState(() {
        _pickedFileName = file.name;
        _pickedFileBytes = file.bytes;
      });
      if (mounted) {
        context.read<StudentManuscriptCheckerCubit>().setPickedFile(
          file.name,
          file.bytes,
        );
      }
    }
  }

  void _loadSampleText() {
    setState(() {
      _textController.text = _sampleManuscript;
    });
    context.read<StudentManuscriptCheckerCubit>().updateDraftText(
      _sampleManuscript,
    );
  }

  void _handleSubmit() {
    final available = widget.initialState.availableJournals;
    var journalId = _isManualJournal
        ? _journalIdController.text.trim()
        : (_selectedJournalId ?? _journalIdController.text.trim());

    if (journalId.isEmpty && available.isNotEmpty) {
      journalId = available.first.id;
      _selectedJournalTitle = available.first.title;
    }

    if (_tabController.index == 0) {
      // Text mode
      final text = _textController.text.trim();
      if (text.isEmpty) {
        AppNotification.showWarning(
          context,
          'Please enter or paste manuscript text.',
        );
        return;
      }
      context.read<StudentManuscriptCheckerCubit>().submit(
        fileBytes: utf8.encode(text),
        filename: 'manuscript.txt',
        targetJournalId: journalId,
        includeExemplars: _includeExemplars,
        journalTitle: _selectedJournalTitle,
      );
    } else {
      // File mode
      if (_pickedFileBytes == null || _pickedFileBytes!.isEmpty) {
        AppNotification.showWarning(context, context.l10n.pleaseChooseFile);
        return;
      }
      context.read<StudentManuscriptCheckerCubit>().submit(
        fileBytes: _pickedFileBytes!,
        filename: _pickedFileName ?? 'manuscript.pdf',
        targetJournalId: journalId,
        includeExemplars: _includeExemplars,
        journalTitle: _selectedJournalTitle,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final journals = widget.initialState.availableJournals;
    final int wordCount = _textController.text
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .length;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.sidebarBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink900.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Badge & Title
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.blue50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.blue100),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.auto_stories_rounded,
                  size: 14,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  context.l10n.studentCheckerSubtitle,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Manrope',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            context.l10n.checkManuscriptAlignment,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              fontFamily: 'Manrope',
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.checkManuscriptDesc,
            style: const TextStyle(
              fontSize: 13.5,
              color: AppColors.textSecondary,
              fontFamily: 'Manrope',
              height: 1.5,
            ),
          ),

          const SizedBox(height: 20),
          const Divider(color: AppColors.borderSoft, height: 1),
          const SizedBox(height: 20),

          // ── Section 1: Target Journal Selection ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        '1',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          fontFamily: 'Manrope',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    context.l10n.targetJournalProfile,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontFamily: 'Manrope',
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  setState(() {
                    _isManualJournal = !_isManualJournal;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isManualJournal
                            ? Icons.list_alt_rounded
                            : Icons.edit_outlined,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isManualJournal
                            ? context.l10n.selectFromCatalog
                            : context.l10n.enterCustomJournalId,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                          fontFamily: 'Manrope',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (!_isManualJournal && journals.isNotEmpty) ...[
            SearchableJournalDropdown(
              journals: journals,
              selectedJournalId: _selectedJournalId,
              selectedJournalTitle: _selectedJournalTitle,
              onSelected: (found) {
                setState(() {
                  _selectedJournalId = found.id;
                  _selectedJournalTitle = found.title;
                  _journalIdController.text = found.id;
                });
                context.read<StudentManuscriptCheckerCubit>().selectJournal(
                  found.id,
                  found.title,
                );
              },
            ),
          ] else ...[
            TextField(
              controller: _journalIdController,
              decoration: InputDecoration(
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 12, right: 8),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.blue50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.vpn_key_outlined,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 44,
                  minHeight: 32,
                ),
                hintText: context.l10n.targetJournalIdHint,
                hintStyle: const TextStyle(
                  fontSize: 13.5,
                  color: AppColors.textSubtle,
                  fontFamily: 'Manrope',
                ),
                filled: true,
                fillColor: AppColors.surfaceSoft,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
              ),
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontFamily: 'Manrope',
              ),
              onChanged: (val) {
                _selectedJournalId = val;
                context.read<StudentManuscriptCheckerCubit>().selectJournal(
                  val,
                  'Target Journal',
                );
              },
            ),
          ],

          const SizedBox(height: 20),

          // ── Section 2: Manuscript Input Tabs ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderSoft),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              splashBorderRadius: BorderRadius.circular(8),
              overlayColor: WidgetStateProperty.resolveWith<Color?>((
                Set<WidgetState> states,
              ) {
                if (states.contains(WidgetState.hovered)) {
                  return AppColors.primary.withValues(alpha: 0.04);
                }
                if (states.contains(WidgetState.pressed)) {
                  return AppColors.primary.withValues(alpha: 0.08);
                }
                return null;
              }),
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1.5),
                  ),
                ],
              ),
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.slate600,
              labelStyle: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                fontFamily: 'Manrope',
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                fontFamily: 'Manrope',
              ),
              tabs: [
                Tab(
                  height: 38,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.edit_note_rounded, size: 16),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          context.l10n.directTextDraft,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Tab(
                  height: 38,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.upload_file_rounded, size: 16),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          context.l10n.uploadManuscriptFile,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Tab views
          SizedBox(
            height: 240,
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Text Field
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontFamily: 'Manrope',
                            height: 1.6,
                            color: AppColors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: context.l10n.pasteDraftHere,
                            hintStyle: const TextStyle(
                              fontSize: 13.5,
                              color: AppColors.textSubtle,
                              fontFamily: 'Manrope',
                              height: 1.5,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          onChanged: (val) {
                            setState(() {}); // Update word count
                            context
                                .read<StudentManuscriptCheckerCubit>()
                                .updateDraftText(val);
                          },
                        ),
                      ),
                      // Editor Bottom Toolbar
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: const BoxDecoration(
                          color: AppColors.paper50,
                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(13),
                          ),
                          border: Border(
                            top: BorderSide(color: AppColors.borderSoft),
                          ),
                        ),
                        child: Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Wrap(
                              spacing: 12,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                InkWell(
                                  onTap: _loadSampleText,
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.blue50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppColors.blue100,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.auto_stories_outlined,
                                          size: 14,
                                          color: AppColors.primary,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          context.l10n.loadSample,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primary,
                                            fontFamily: 'Manrope',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (_textController.text.isNotEmpty)
                                  InkWell(
                                    onTap: () {
                                      _textController.clear();
                                      setState(() {});
                                      context
                                          .read<StudentManuscriptCheckerCubit>()
                                          .updateDraftText('');
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 6,
                                      ),
                                      child: Text(
                                        context.l10n.clear,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textMuted,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Manrope',
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: wordCount > 0
                                    ? AppColors.green50
                                    : AppColors.surfaceSoft,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: wordCount > 0
                                      ? AppColors.green100
                                      : AppColors.borderSoft,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: wordCount > 0
                                          ? AppColors.green700
                                          : AppColors.textSubtle,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '$wordCount ${context.l10n.words}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: wordCount > 0
                                          ? AppColors.green700
                                          : AppColors.textSubtle,
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

                // Tab 2: File Upload
                Container(
                  decoration: BoxDecoration(
                    color: _pickedFileName != null
                        ? AppColors.blue50.withValues(alpha: 0.3)
                        : AppColors.surfaceSoft.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _pickedFileName != null
                          ? AppColors.primary
                          : const Color(0xFFCBD5E1),
                      width: _pickedFileName != null ? 1.5 : 1,
                    ),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: _pickedFileName != null
                                ? AppColors.blue50
                                : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _pickedFileName != null
                                  ? AppColors.blue100
                                  : AppColors.border,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              _pickedFileName != null
                                  ? Icons.description_rounded
                                  : Icons.cloud_upload_outlined,
                              size: 26,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (_pickedFileName != null) ...[
                          Text(
                            _pickedFileName!,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              fontFamily: 'Manrope',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.green50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.green100),
                            ),
                            child: Text(
                              '${((_pickedFileBytes?.length ?? 0) / 1024).toStringAsFixed(1)} KB ready for check',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.green700,
                                fontFamily: 'Manrope',
                              ),
                            ),
                          ),
                        ] else ...[
                          Text(
                            context.l10n.uploadTitle,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              fontFamily: 'Manrope',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context.l10n.uploadDesc,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textMuted,
                              fontFamily: 'Manrope',
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        ElevatedButton.icon(
                          onPressed: _pickFile,
                          icon: Icon(
                            _pickedFileName != null
                                ? Icons.sync_rounded
                                : Icons.folder_open_rounded,
                            size: 16,
                          ),
                          label: Text(
                            _pickedFileName != null
                                ? context.l10n.changeFile
                                : context.l10n.selectFile,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Manrope',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Section 3: Options (Exemplars toggle) ──
          InkWell(
            onTap: () {
              setState(() {
                _includeExemplars = !_includeExemplars;
              });
              context
                  .read<StudentManuscriptCheckerCubit>()
                  .toggleIncludeExemplars(_includeExemplars);
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: _includeExemplars
                    ? const Color(0xFFF0F7FC)
                    : AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _includeExemplars
                      ? AppColors.blue100
                      : AppColors.border,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _includeExemplars
                          ? Colors.white
                          : AppColors.borderSoft,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _includeExemplars
                            ? AppColors.blue100
                            : Colors.transparent,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        _includeExemplars
                            ? Icons.verified_rounded
                            : Icons.verified_outlined,
                        size: 18,
                        color: _includeExemplars
                            ? AppColors.primary
                            : AppColors.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.includeValidatedExemplars,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            fontFamily: 'Manrope',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          context.l10n.includeValidatedExemplarsDesc,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                            fontFamily: 'Manrope',
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Switch(
                    value: _includeExemplars,
                    activeThumbColor: AppColors.primary,
                    onChanged: (val) {
                      setState(() {
                        _includeExemplars = val;
                      });
                      context
                          .read<StudentManuscriptCheckerCubit>()
                          .toggleIncludeExemplars(val);
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── Section 4: Submit Button ──
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.zero,
              ),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0071BC), Color(0xFF005F9E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  alignment: Alignment.center,
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 10,
                    children: [
                      const Icon(Icons.spellcheck_rounded, size: 20),
                      Text(
                        context.l10n.checkAlignmentBtn,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Manrope',
                          letterSpacing: 0.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SearchableJournalDropdown extends StatefulWidget {
  final List<TargetJournal> journals;
  final String? selectedJournalId;
  final String? selectedJournalTitle;
  final ValueChanged<TargetJournal> onSelected;

  const SearchableJournalDropdown({
    super.key,
    required this.journals,
    this.selectedJournalId,
    this.selectedJournalTitle,
    required this.onSelected,
  });

  @override
  State<SearchableJournalDropdown> createState() =>
      _SearchableJournalDropdownState();
}

class _SearchableJournalDropdownState extends State<SearchableJournalDropdown> {
  final LayerLink _layerLink = LayerLink();
  bool _isOpen = false;
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _closeDropdown();
    super.dispose();
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  void _closeDropdown() {
    if (_isOpen) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      _isOpen = false;
      if (mounted) setState(() {});
    }
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closeDropdown,
              ),
            ),
            Positioned(
              width: size.width,
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: Offset(0.0, size.height + 6),
                child: _JournalDropdownMenu(
                  journals: widget.journals,
                  selectedJournalId: widget.selectedJournalId,
                  onSelected: (journal) {
                    widget.onSelected(journal);
                    _closeDropdown();
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentTitle =
        (widget.selectedJournalTitle != null &&
            widget.selectedJournalTitle!.isNotEmpty)
        ? widget.selectedJournalTitle!
        : (widget.journals.any((j) => j.id == widget.selectedJournalId)
              ? widget.journals
                    .firstWhere((j) => j.id == widget.selectedJournalId)
                    .title
              : (widget.journals.isNotEmpty
                    ? widget.journals.first.title
                    : context.l10n.selectTargetJournal));

    return CompositedTransformTarget(
      link: _layerLink,
      child: InkWell(
        onTap: _toggleDropdown,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: _isOpen ? Colors.white : AppColors.surfaceSoft,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isOpen ? AppColors.primary : AppColors.border,
              width: _isOpen ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.blue50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.blue100),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  currentTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontFamily: 'Manrope',
                  ),
                ),
              ),
              AnimatedRotation(
                turns: _isOpen ? 0.5 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textSubtle,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JournalDropdownMenu extends StatefulWidget {
  final List<TargetJournal> journals;
  final String? selectedJournalId;
  final ValueChanged<TargetJournal> onSelected;

  const _JournalDropdownMenu({
    required this.journals,
    required this.selectedJournalId,
    required this.onSelected,
  });

  @override
  State<_JournalDropdownMenu> createState() => _JournalDropdownMenuState();
}

class _JournalDropdownMenuState extends State<_JournalDropdownMenu> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchQuery.toLowerCase().trim();
    final filtered = widget.journals.where((j) {
      if (query.isEmpty) return true;
      final titleMatch = j.title.toLowerCase().contains(query);
      final domainMatch = j.domain?.toLowerCase().contains(query) ?? false;
      final idMatch = j.id.toLowerCase().contains(query);
      return titleMatch || domainMatch || idMatch;
    }).toList();

    return Material(
      elevation: 8,
      color: Colors.white,
      shadowColor: Colors.black.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        constraints: const BoxConstraints(maxHeight: 340),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search Input Header
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
              child: Container(
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onChanged: (val) {
                    setState(() => _searchQuery = val);
                  },
                  textAlignVertical: TextAlignVertical.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontFamily: 'Manrope',
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: false,
                    hintText: context.l10n.searchJournalDropdownHint,
                    hintStyle: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF94A3B8),
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w400,
                    ),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(left: 10, right: 8),
                      child: Icon(
                        Icons.search_rounded,
                        size: 17,
                        color: AppColors.primary,
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 35,
                      minHeight: 38,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear_rounded,
                              size: 15,
                              color: Color(0xFF94A3B8),
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 30,
                              minHeight: 38,
                            ),
                          )
                        : null,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 0,
                    ),
                  ),
                ),
              ),
            ),
            const Divider(height: 1, thickness: 1, color: AppColors.borderSoft),
            // Journal List
            Flexible(
              child: filtered.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 24,
                        horizontal: 16,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 28,
                            color: AppColors.textSubtle.withValues(alpha: 0.6),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            context.l10n.noJournalsMatched(_searchQuery),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textMuted,
                              fontFamily: 'Manrope',
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 6,
                      ),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 2),
                      itemBuilder: (context, index) {
                        final j = filtered[index];
                        final isSelected = j.id == widget.selectedJournalId;
                        return InkWell(
                          onTap: () => widget.onSelected(j),
                          borderRadius: BorderRadius.circular(8),
                          hoverColor: AppColors.primarySoft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.blue50
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.blue50
                                        : AppColors.surfaceSoft,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.blue100
                                          : AppColors.borderSoft,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.menu_book_rounded,
                                    size: 14,
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.textSubtle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        j.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w600,
                                          color: isSelected
                                              ? AppColors.primary
                                              : AppColors.textPrimary,
                                          fontFamily: 'Manrope',
                                        ),
                                      ),
                                      if (j.domain != null &&
                                          j.domain!.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          j.domain!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
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
                                if (isSelected) ...[
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    size: 16,
                                    color: AppColors.primary,
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
      ),
    );
  }
}
