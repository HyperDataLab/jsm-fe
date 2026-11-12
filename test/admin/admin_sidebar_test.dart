import 'package:material_ui/material_ui.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jsm_fe/features/admin/presentation/widgets/admin_sidebar.dart';

import 'package:flutter_localizations/flutter_localizations.dart'
    hide GlobalCupertinoLocalizations, GlobalMaterialLocalizations;
import 'package:jsm_fe/core/localization/app_localizations.dart';

Widget _buildSidebarTestHarness({
  required bool isCollapsed,
  required VoidCallback onToggle,
}) {
  return MaterialApp(
    locale: const Locale('vi'),
    supportedLocales: const [Locale('en'), Locale('vi')],
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Scaffold(
      body: Row(
        children: [
          AdminSidebar(
            selectedIndex: 0,
            onDestinationSelected: (_) {},
            isCollapsed: isCollapsed,
            onToggleCollapse: onToggle,
          ),
          const Expanded(child: SizedBox()),
        ],
      ),
    ),
  );
}

void main() {
  testWidgets(
    'expanded sidebar: shows collapse button near logo, shows user profile at bottom',
    (tester) async {
      bool toggled = false;

      await tester.pumpWidget(
        _buildSidebarTestHarness(
          isCollapsed: false,
          onToggle: () => toggled = true,
        ),
      );
      await tester.pumpAndSettle();

      // 1. Brand header has Logo and HyperData Lab
      expect(find.text('HyperData Lab'), findsOneWidget);
      expect(find.byType(Image), findsWidgets);

      // 2. Collapse button is located at top next to logo
      final collapseBtn = find.byTooltip('Thu gọn thanh menu');
      expect(collapseBtn, findsOneWidget);
      await tester.tap(collapseBtn);
      expect(toggled, isTrue);

      // 3. Old 'Quay về trang chủ' button is removed
      expect(find.text('Quay về trang chủ'), findsNothing);

      // 4. Bottom area shows account profile fallback
      expect(find.text('Admin'), findsOneWidget);
      expect(find.text('ADMIN'), findsOneWidget);
    },
  );

  testWidgets(
    'collapsed sidebar: shows clickable logo to expand, shows avatar tooltip at bottom',
    (tester) async {
      bool toggled = false;

      await tester.pumpWidget(
        _buildSidebarTestHarness(
          isCollapsed: true,
          onToggle: () => toggled = true,
        ),
      );
      await tester.pumpAndSettle();

      // 1. Text 'HyperData Lab' is hidden
      expect(find.text('HyperData Lab'), findsNothing);

      // 2. Logo has expand tooltip and tapping toggles
      final expandTooltip = find.byTooltip('Mở rộng thanh menu');
      expect(expandTooltip, findsOneWidget);
      await tester.tap(expandTooltip);
      expect(toggled, isTrue);

      // 3. Old 'Quay về trang chủ' is not present
      expect(find.text('Quay về trang chủ'), findsNothing);

      // 4. Avatar with tooltip at bottom
      expect(find.byTooltip('Admin (ADMIN)'), findsOneWidget);
    },
  );
}
