import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jsm_fe/features/student_manuscript_checker/domain/entities/feature_comparison.dart';
import 'package:jsm_fe/features/student_manuscript_checker/domain/entities/manuscript_check_result.dart';
import 'package:jsm_fe/features/student_manuscript_checker/domain/entities/stance_comparison.dart';
import 'package:jsm_fe/features/student_manuscript_checker/domain/entities/voice_person_comparison.dart';
import 'package:jsm_fe/features/student_manuscript_checker/presentation/widgets/priority_improvements_card.dart';

void main() {
  testWidgets(
    'PriorityImprovementsCard renders subtle semantic tints and indicators',
    (tester) async {
      const result = ManuscriptCheckResult(
        suitabilityScore: 82.0,
        ratingLevel: 'GOOD_ALIGNMENT',
        summary: 'Test summary',
        sectionScores: {'METHODS': 76.0},
        featureComparison: FeatureComparison(
          voiceAndPerson: VoicePersonComparison(
            userPassiveRate: 20.0,
            journalPassiveRate: 31.0,
            userWeRate: 0.0,
            journalWeRate: 3.8,
          ),
          stance: StanceComparison(
            userHedgeRate: 10.0,
            journalHedgeRate: 12.0,
            userBoosterRate: 0.0,
            journalBoosterRate: 5.6,
          ),
        ),
        warnings: [],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PriorityImprovementsCard(result: result)),
        ),
      );

      await tester.pumpAndSettle();

      // Verify section title and issues count badge
      expect(find.text('Priority Improvements'), findsOneWidget);
      expect(find.text('3 Issues'), findsOneWidget);

      // Verify issue titles
      expect(find.text('Author Voice ("We")'), findsOneWidget);
      expect(find.text('Epistemic Boosters'), findsOneWidget);
      expect(find.text('METHODS Style Alignment'), findsOneWidget);

      // Verify priority badges
      expect(find.text('HIGH PRIORITY'), findsNWidgets(2));
      expect(find.text('MEDIUM PRIORITY'), findsOneWidget);

      // Verify chips: Manuscript and Journal
      expect(find.text('Manuscript: 0.0%'), findsOneWidget);
      expect(find.text('Journal: 3.8%'), findsOneWidget);
      expect(find.text('-3.8 pp'), findsOneWidget);

      expect(find.text('Manuscript: 0.0 /1k'), findsOneWidget);
      expect(find.text('Journal: 5.6 /1k'), findsOneWidget);
      expect(find.text('-5.6 /1k'), findsOneWidget);

      expect(find.text('Manuscript: 76%'), findsOneWidget);
      expect(find.text('Journal: >= 85%'), findsOneWidget);
      expect(find.text('-9 pp'), findsOneWidget);
    },
  );
}
