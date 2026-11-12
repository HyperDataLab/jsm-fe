import 'package:material_ui/material_ui.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../student_manuscript_checker/presentation/pages/evaluation_history_page.dart';
import '../../../student_manuscript_checker/presentation/pages/journal_recommendations_page.dart';
import '../../../student_manuscript_checker/presentation/pages/student_manuscript_checker_page.dart';
import '../widgets/user_header.dart';
import '../widgets/user_sidebar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  bool _isSidebarCollapsed = false;

  void _navigateToTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildActiveTab() {
    switch (_selectedIndex) {
      case 0:
        return const StudentManuscriptCheckerPage(showAppBar: false);
      case 1:
        return const JournalRecommendationsPage();
      case 2:
        return EvaluationHistoryPage(
          onNewCheckRequested: () => _navigateToTab(0),
        );
      default:
        return const StudentManuscriptCheckerPage(showAppBar: false);
    }
  }

  static const double _minDashboardWidth = 1024.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 1100;
        final effectiveCollapsed = isNarrow || _isSidebarCollapsed;

        final scaffold = Scaffold(
          backgroundColor: AppColors.background,
          body: Row(
            children: [
              // User Sidebar
              UserSidebar(
                selectedIndex: _selectedIndex,
                onDestinationSelected: _navigateToTab,
                isCollapsed: effectiveCollapsed,
                onToggleCollapse: () {
                  setState(() {
                    _isSidebarCollapsed = !_isSidebarCollapsed;
                  });
                },
              ),

              // Main content area
              Expanded(
                child: Column(
                  children: [
                    UserHeader(selectedIndex: _selectedIndex),
                    Expanded(child: _buildActiveTab()),
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
              child: scaffold,
            ),
          );
        }

        return scaffold;
      },
    );
  }
}
