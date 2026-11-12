import 'package:material_ui/material_ui.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_notification.dart';
import '../../../../core/localization/app_localizations.dart';
import '../views/journals_view.dart';
import '../views/style_and_corpus_view.dart';
import '../views/system_and_debug_view.dart';
import '../widgets/admin_header.dart';
import '../widgets/admin_sidebar.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedIndex = 0;
  bool _isSidebarCollapsed = false;
  String? _targetJournalIdForProfile;
  int _styleCorpusSubTab = 0;
  int _systemDebugSubTab = 0;

  void _navigateToTab(int index, {String? journalId, int? subTabIndex}) {
    setState(() {
      _selectedIndex = index;
      if (journalId != null) {
        _targetJournalIdForProfile = journalId;
      }
      if (subTabIndex != null) {
        if (index == 1) _styleCorpusSubTab = subTabIndex;
        if (index == 2) _systemDebugSubTab = subTabIndex;
      }
    });
  }

  void _showTriggerAnalysisDialog() {
    final journalController = TextEditingController();
    int yearStart = 2021;
    int yearEnd = 2024;
    double targetPapers = 200;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20), // --ds-radius-panel
              ),
              title: Text(
                context.l10n.triggerMiningTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Manrope',
                  color: AppColors.textPrimary,
                ),
              ),
              content: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 480,
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.triggerMiningDesc,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                          fontFamily: 'Manrope',
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        context.l10n.issnOrJournalName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          fontFamily: 'Manrope',
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: journalController,
                        decoration: InputDecoration(
                          hintText: context.l10n.issnHint,
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
                                  context.l10n.fromYear,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
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
                                  items: [2018, 2019, 2020, 2021, 2022].map((
                                    y,
                                  ) {
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
                                  context.l10n.toYear,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
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
                                  items: [2023, 2024, 2025, 2026].map((y) {
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
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            context.l10n.targetPapersCount,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              fontFamily: 'Manrope',
                            ),
                          ),
                          Text(
                            '${targetPapers.toInt()} ${context.l10n.papersUnit}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                              fontFamily: 'Manrope',
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: targetPapers,
                        min: 50,
                        max: 500,
                        divisions: 9,
                        activeColor: AppColors.primary,
                        onChanged: (val) =>
                            setModalState(() => targetPapers = val),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(context.l10n.cancel),
                ),
                ElevatedButton(
                  onPressed: () {
                    final successMsg = context.l10n.analysisTriggeredSuccess;
                    Navigator.of(ctx).pop();
                    _navigateToTab(
                      2,
                      subTabIndex: 0,
                    ); // Navigate to Tab 2 (Job Monitor logs)
                    AppNotification.showSuccess(
                      context,
                      successMsg,
                      title: context.l10n.success,
                    );
                  },
                  child: Text(context.l10n.startAnalysis),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildActiveView() {
    switch (_selectedIndex) {
      case 0:
        return JournalsView(
          onNavigateToTab: _navigateToTab,
          onTriggerNewAnalysis: _showTriggerAnalysisDialog,
        );
      case 1:
        return StyleAndCorpusView(
          onNavigateToTab: _navigateToTab,
          selectedJournalId: _targetJournalIdForProfile,
          initialSubTabIndex: _styleCorpusSubTab,
        );
      case 2:
        return SystemAndDebugView(
          onNavigateToTab: _navigateToTab,
          onTriggerNewAnalysis: _showTriggerAnalysisDialog,
          initialSubTabIndex: _systemDebugSubTab,
        );
      default:
        return JournalsView(
          onNavigateToTab: _navigateToTab,
          onTriggerNewAnalysis: _showTriggerAnalysisDialog,
        );
    }
  }

  static const double _minDashboardWidth = 1024.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 1100;
        final effectiveCollapsed = isNarrow || _isSidebarCollapsed;

        final dashboardScaffold = Scaffold(
          backgroundColor: AppColors.background,
          body: Row(
            children: [
              // Sidebar on the left
              AdminSidebar(
                selectedIndex: _selectedIndex,
                onDestinationSelected: _navigateToTab,
                isCollapsed: effectiveCollapsed,
                onToggleCollapse: () {
                  setState(() {
                    _isSidebarCollapsed = !_isSidebarCollapsed;
                  });
                },
              ),

              // Main Content Area (Header + Subview)
              Expanded(
                child: Column(
                  children: [
                    AdminHeader(
                      selectedIndex: _selectedIndex,
                      onNewJobPressed: _showTriggerAnalysisDialog,
                    ),
                    Expanded(child: _buildActiveView()),
                  ],
                ),
              ),
            ],
          ),
        );

        if (constraints.maxWidth < _minDashboardWidth) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: _minDashboardWidth,
              height: constraints.hasBoundedHeight
                  ? constraints.maxHeight
                  : null,
              child: dashboardScaffold,
            ),
          );
        }

        return dashboardScaffold;
      },
    );
  }
}
