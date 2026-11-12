import 'package:material_ui/material_ui.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    hide GlobalCupertinoLocalizations, GlobalMaterialLocalizations;
import 'package:flutter_test/flutter_test.dart';
import 'package:jsm_fe/core/localization/app_localizations.dart';
import 'package:jsm_fe/features/admin/presentation/widgets/journal_command_center_panel.dart';

void main() {
  testWidgets(
    'JournalCommandCenterPanel initializes without throwing InheritedWidget exception',
    (tester) async {
      final journal = {
        'id': 'test-journal-1',
        'title': 'Test Journal',
        'issn': '1234-5678',
        'field': null, // test fallback to default domain
      };

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('vi')],
          home: Scaffold(
            body: JournalCommandCenterPanel(
              journal: journal,
              onNavigateToTab: (tabId, {args}) {},
              onRefreshParent: () {},
            ),
          ),
        ),
      );

      // Initial pump triggers initState and didChangeDependencies
      await tester.pump();

      // Verify it mounted without throwing exception
      expect(find.byType(JournalCommandCenterPanel), findsOneWidget);
    },
  );
}
