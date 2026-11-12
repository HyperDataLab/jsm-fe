import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jsm_fe/features/student_manuscript_checker/domain/entities/feature_comparison.dart';
import 'package:jsm_fe/features/student_manuscript_checker/domain/entities/manuscript_check_result.dart';
import 'package:jsm_fe/features/student_manuscript_checker/domain/entities/sentence_length_comparison.dart';
import 'package:jsm_fe/features/student_manuscript_checker/domain/entities/stance_comparison.dart';
import 'package:jsm_fe/features/student_manuscript_checker/domain/entities/voice_person_comparison.dart';
import 'package:jsm_fe/features/student_manuscript_checker/presentation/widgets/style_deviation_matrix_card.dart';

void main() {
  testWidgets(
    'StyleDeviationMatrixCard expands to full available width on desktop',
    (tester) async {
      const result = ManuscriptCheckResult(
        suitabilityScore: 85.0,
        ratingLevel: 'EXCELLENT_ALIGNMENT',
        summary: 'Summary',
        sectionScores: {'INTRO': 90.0},
        featureComparison: FeatureComparison(
          sentenceLength: SentenceLengthComparison(
            userMedian: 20,
            journalMedian: 20,
            journalP10: 15,
            journalP90: 25,
            status: 'WITHIN_RANGE',
          ),
          voiceAndPerson: VoicePersonComparison(
            userPassiveRate: 20.0,
            journalPassiveRate: 22.0,
            userWeRate: 5.0,
            journalWeRate: 5.0,
          ),
          stance: StanceComparison(
            userHedgeRate: 10,
            journalHedgeRate: 10,
            userBoosterRate: 5,
            journalBoosterRate: 5,
          ),
        ),
        warnings: [],
      );

      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: StyleDeviationMatrixCard(result: result),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify card is rendered
      expect(find.text('Stylistic Deviation Matrix'), findsOneWidget);

      // Verify card width is full 1160 (1200 - 40 padding)
      final cardFinder = find.byType(StyleDeviationMatrixCard);
      final cardSize = tester.getSize(cardFinder);
      expect(cardSize.width, equals(1160.0));

      // Verify Table width fills the entire inner card (1160 - 40 card padding - 2 border width = 1118)
      final tableFinder = find.byType(Table);
      final tableSize = tester.getSize(tableFinder);
      expect(tableSize.width, equals(1118.0));
    },
  );
}
