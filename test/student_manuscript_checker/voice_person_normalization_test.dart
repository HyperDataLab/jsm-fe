import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jsm_fe/features/student_manuscript_checker/domain/entities/voice_person_comparison.dart';
import 'package:jsm_fe/features/student_manuscript_checker/presentation/widgets/voice_person_card.dart';

void main() {
  group('Voice and Person Percentage Normalization Tests', () {
    test('Entity correctly calculates percentage point differences without * 100 distortion', () {
      final comp = VoicePersonComparison.fromMap({
        'user_passive_rate': 20.0,
        'journal_passive_rate': 31.2,
        'user_we_rate': 0.0,
        'journal_we_rate': 3.8,
      });

      expect(comp.userPassiveRate, equals(20.0));
      expect(comp.journalPassiveRate, equals(31.2));
      expect(comp.userWeRate, equals(0.0));
      expect(comp.journalWeRate, equals(3.8));

      // Differences in percentage points (pp)
      expect(comp.passiveRateDiff, closeTo(-11.2, 0.001));
      expect(comp.weRateDiff, closeTo(-3.8, 0.001));

      // Ensure 31.2 NEVER becomes 3120.0
      expect(comp.journalPassiveRate, isNot(equals(3120.0)));
      expect(comp.journalWeRate, isNot(equals(380.0)));
    });

    testWidgets(
      'VoicePersonCard displays clean percentage values, correct pp differences and shared scale',
      (tester) async {
        const comp = VoicePersonComparison(
          userPassiveRate: 20.0,
          journalPassiveRate: 31.2,
          userWeRate: 0.0,
          journalWeRate: 3.8,
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: VoicePersonCard(comparison: comp)),
          ),
        );

        await tester.pumpAndSettle();

        // Verify exact percentage display (NOT 2000.0% or 3120.0%)
        expect(find.text('20.0%'), findsOneWidget);
        expect(find.text('31.2%'), findsOneWidget);
        expect(find.text('0.0%'), findsOneWidget);
        expect(find.text('3.8%'), findsOneWidget);

        expect(find.text('3120.0%'), findsNothing);
        expect(find.text('380.0%'), findsNothing);
        expect(find.text('-3100.0 pp'), findsNothing);
        expect(find.text('-380.0 pp'), findsNothing);

        // Verify exact difference in percentage points
        expect(find.text('-11.2 pp'), findsOneWidget);
        expect(find.text('-3.8 pp'), findsOneWidget);

        // Verify severity labels recalculated from real thresholds:
        // Passive voice with 11.2 pp deviation is "Moderate deviation" (8.0 < diff <= 15.0)
        expect(find.text('Moderate deviation'), findsOneWidget);
        // Author voice with 3.8 pp deviation is "Major mismatch" (diff > 3.0)
        expect(find.text('Major mismatch'), findsOneWidget);

        // Verify chart bars use shared scale (maxScale 50.0 for passive voice, 15.0 for author)
        final fractionallySizedBoxes = tester
            .widgetList<FractionallySizedBox>(find.byType(FractionallySizedBox))
            .toList();

        // Passive voice manuscript: 20.0 / 50.0 = 0.40
        expect(fractionallySizedBoxes[0].widthFactor, closeTo(0.40, 0.01));
        // Passive voice journal: 31.2 / 50.0 = 0.624
        expect(fractionallySizedBoxes[1].widthFactor, closeTo(0.624, 0.01));

        // Manuscript 20.0% bar is visibly smaller than Journal 31.2% bar
        expect(
          fractionallySizedBoxes[0].widthFactor! <
              fractionallySizedBoxes[1].widthFactor!,
          isTrue,
        );

        // Author voice manuscript: 0.0 / 15.0 = 0.0
        expect(fractionallySizedBoxes[2].widthFactor, closeTo(0.0, 0.01));
        // Author voice journal: 3.8 / 15.0 = 0.253
        expect(fractionallySizedBoxes[3].widthFactor, closeTo(0.253, 0.01));
      },
    );
  });
}
