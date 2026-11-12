import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jsm_fe/app/theme/app_theme.dart';
import 'package:jsm_fe/core/widgets/error_view.dart';
import 'package:jsm_fe/features/student_manuscript_checker/domain/entities/evaluation_history_response.dart';
import 'package:jsm_fe/features/student_manuscript_checker/domain/entities/evaluation_history_stats.dart';
import 'package:jsm_fe/features/student_manuscript_checker/domain/entities/exemplar_item.dart';
import 'package:jsm_fe/features/student_manuscript_checker/domain/entities/feature_comparison.dart';
import 'package:jsm_fe/features/student_manuscript_checker/domain/entities/journal_recommendation_response.dart';
import 'package:jsm_fe/features/student_manuscript_checker/domain/entities/manuscript_check_result.dart';
import 'package:jsm_fe/features/student_manuscript_checker/domain/entities/sentence_length_comparison.dart';
import 'package:jsm_fe/features/student_manuscript_checker/domain/entities/stance_comparison.dart';
import 'package:jsm_fe/features/student_manuscript_checker/domain/entities/target_journal.dart';
import 'package:jsm_fe/features/student_manuscript_checker/domain/entities/voice_person_comparison.dart';
import 'package:jsm_fe/features/student_manuscript_checker/domain/entities/warning_item.dart';
import 'package:jsm_fe/features/student_manuscript_checker/domain/repositories/student_manuscript_repository.dart';
import 'package:jsm_fe/features/student_manuscript_checker/domain/usecases/check_manuscript_usecase.dart';
import 'package:jsm_fe/features/student_manuscript_checker/domain/usecases/get_available_journals_usecase.dart';
import 'package:jsm_fe/features/student_manuscript_checker/presentation/cubit/student_manuscript_checker_cubit.dart';
import 'package:jsm_fe/features/student_manuscript_checker/presentation/cubit/student_manuscript_checker_state.dart';
import 'package:jsm_fe/features/student_manuscript_checker/presentation/pages/student_manuscript_checker_page.dart';
import 'package:jsm_fe/features/student_manuscript_checker/presentation/widgets/manuscript_analysis_loading_view.dart';
import 'package:jsm_fe/features/student_manuscript_checker/presentation/widgets/manuscript_input_card.dart';

class _MockRepo implements StudentManuscriptRepository {
  ManuscriptCheckResult? resultToReturn;
  Object? errorToThrow;
  List<TargetJournal> journals = const [
    TargetJournal(
      id: 'j-uuid-101',
      title: 'IEEE Transactions on Software Engineering',
      domain: 'Software Engineering',
    ),
  ];

  @override
  Future<ManuscriptCheckResult> checkManuscript({
    required List<int> fileBytes,
    required String filename,
    required String targetJournalId,
    bool includeExemplars = false,
  }) async {
    if (errorToThrow != null) throw errorToThrow!;
    return resultToReturn ?? _defaultResult();
  }

  @override
  Stream<Map<String, dynamic>> checkManuscriptStream({
    required List<int> fileBytes,
    required String filename,
    required String targetJournalId,
    bool includeExemplars = false,
  }) async* {
    if (errorToThrow != null) throw errorToThrow!;
    final res = resultToReturn ?? _defaultResult();
    yield {
      'event': 'analysis.completed',
      'stage': 'COMPLETED',
      'progress': 100,
      'message': 'Analysis complete',
      'data': res.toMap(),
    };
  }

  @override
  Future<List<TargetJournal>> getAvailableJournals() async {
    if (errorToThrow != null) throw errorToThrow!;
    return journals;
  }

  @override
  Future<EvaluationHistoryResponse> getEvaluationHistory({
    int page = 1,
    int limit = 10,
    String sort = 'newest',
    String? journal,
    String? compatibility,
    String? search,
  }) async {
    return const EvaluationHistoryResponse(
      items: [],
      page: 1,
      limit: 10,
      total: 0,
      totalPages: 0,
    );
  }

  @override
  Future<EvaluationHistoryStats> getEvaluationStats() async {
    return const EvaluationHistoryStats();
  }

  @override
  Future<ManuscriptCheckResult> getEvaluationDetail(String id) async {
    return resultToReturn ?? _defaultResult();
  }

  @override
  Future<void> deleteEvaluation(String id) async {}

  @override
  Future<JournalRecommendationResponse> getJournalRecommendations({
    List<int>? fileBytes,
    String? filename,
    String? evaluationId,
  }) async {
    return const JournalRecommendationResponse(
      manuscriptName: 'test.pdf',
      totalWords: 1000,
      totalSentences: 50,
      candidateCount: 0,
      recommendations: [],
    );
  }
}

class _SlowRepo extends _MockRepo {
  @override
  Future<ManuscriptCheckResult> checkManuscript({
    required List<int> fileBytes,
    required String filename,
    required String targetJournalId,
    bool includeExemplars = false,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _defaultResult();
  }

  @override
  Stream<Map<String, dynamic>> checkManuscriptStream({
    required List<int> fileBytes,
    required String filename,
    required String targetJournalId,
    bool includeExemplars = false,
  }) async* {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final res = _defaultResult();
    yield {
      'event': 'analysis.completed',
      'stage': 'COMPLETED',
      'progress': 100,
      'message': 'Analysis complete',
      'data': res.toMap(),
    };
  }
}

ManuscriptCheckResult _defaultResult({
  bool includeMissingGap = true,
  bool includeExemplar = true,
}) {
  return ManuscriptCheckResult(
    suitabilityScore: 88.5,
    ratingLevel: 'EXCELLENT_ALIGNMENT',
    summary:
        'The manuscript shows excellent alignment with the target journal.',
    sectionScores: const {'INTRO': 92.0, 'METHODS': 85.0},
    featureComparison: const FeatureComparison(
      sentenceLength: SentenceLengthComparison(
        userMedian: 19.5,
        journalMedian: 20.0,
        journalP10: 12.0,
        journalP90: 28.0,
        status: 'WITHIN_RANGE',
      ),
      voiceAndPerson: VoicePersonComparison(
        userPassiveRate: 24.0,
        journalPassiveRate: 22.0,
        userWeRate: 5.0,
        journalWeRate: 8.0,
      ),
      stance: StanceComparison(
        userHedgeRate: 12.5,
        journalHedgeRate: 15.0,
        userBoosterRate: 8.0,
        journalBoosterRate: 9.0,
      ),
    ),
    warnings: [
      if (includeMissingGap)
        WarningItem(
          id: 'W-GAP-01',
          severity: 'CRITICAL',
          section: 'INTRO',
          title: 'Missing Research Gap',
          message: 'The manuscript section does not contain a research gap.',
          exemplar: includeExemplar
              ? const ExemplarItem(
                  text: 'However, prior approaches remain limited.',
                  articleTitle: 'A Benchmark Empirical Study',
                  doi: '10.1109/TSE.2024.12345',
                )
              : null,
        ),
      const WarningItem(
        id: 'W-STYLE-01',
        severity: 'HIGH',
        section: 'METHODS',
        title: 'Sentence Length Outside Journal Range',
        message: 'Median sentence length exceeds expected journal band.',
      ),
    ],
  );
}

Widget _buildTestApp({required StudentManuscriptCheckerCubit cubit}) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    home: StudentManuscriptCheckerPage(cubit: cubit),
  );
}

void main() {
  group('StudentManuscriptCheckerPage Widget Tests', () {
    testWidgets('renders input form with journal selection and sample loader', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = _MockRepo();
      final cubit = StudentManuscriptCheckerCubit(
        checkManuscriptUseCase: CheckManuscriptUseCase(repo),
        getAvailableJournalsUseCase: GetAvailableJournalsUseCase(repo),
      );

      await tester.pumpWidget(_buildTestApp(cubit: cubit));
      await tester.pumpAndSettle();

      expect(find.text('Student Manuscript Checker'), findsOneWidget);
      expect(find.byType(ManuscriptInputCard), findsOneWidget);
      expect(find.text('Direct Text / Draft'), findsOneWidget);
      expect(find.text('Upload File'), findsOneWidget);
      expect(find.text('Load Sample Manuscript'), findsOneWidget);
      expect(
        find.text('Include validated exemplars from journal corpus'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(ElevatedButton, 'Check Alignment'),
        findsOneWidget,
      );

      // Tap "Load Sample Manuscript"
      await tester.tap(find.text('Load Sample Manuscript'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Recent deep learning architectures'),
        findsOneWidget,
      );
    });

    testWidgets(
      'submitting valid manuscript shows loading then full results dashboard',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final repo = _SlowRepo();
        final cubit = StudentManuscriptCheckerCubit(
          checkManuscriptUseCase: CheckManuscriptUseCase(repo),
          getAvailableJournalsUseCase: GetAvailableJournalsUseCase(repo),
        );
        await cubit.loadJournals();

        await tester.pumpWidget(_buildTestApp(cubit: cubit));
        await tester.pumpAndSettle();

        // Load sample text
        await tester.tap(find.text('Load Sample Manuscript'));
        await tester.pumpAndSettle();

        // Scroll submit button into view and submit
        final submitFinder = find.widgetWithText(
          ElevatedButton,
          'Check Alignment',
        );
        await tester.ensureVisible(submitFinder);
        await tester.pumpAndSettle();

        await tester.tap(submitFinder);
        await tester.pump();
        await tester.pump();

        // Verify Loading View during background delay
        expect(find.byType(ManuscriptAnalysisLoadingView), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsWidgets);

        // Settle once background check completes
        await tester.pumpAndSettle();

        // Verify Success Dashboard & New Components
        expect(find.text('88.5'), findsOneWidget);
        expect(find.text('MODERATE MATCH'), findsOneWidget); // Critical mismatch override turns 88.5 with missing GAP into MODERATE MATCH
        expect(
          find.text('Compatibility by Dimension'),
          findsOneWidget,
        ); // Radar Chart
        expect(
          find.text('Priority Improvements'),
          findsOneWidget,
        ); // Action Card

        // Verify Missing GAP alert card inside Priority Issues
        expect(find.text('Missing Research Gap'), findsWidgets);

        // Verify Breakdown Cards
        expect(find.text('Section Alignment Scores'), findsOneWidget);
        expect(find.text('Sentence Length Analysis'), findsOneWidget);
        expect(find.text('Voice & Person Comparison'), findsOneWidget);
        expect(find.text('Stance & Epistemic Markers'), findsOneWidget);
        expect(find.text('Rhetorical Move Analysis'), findsOneWidget);
        expect(
          find.text('Stylistic Deviation Matrix'),
          findsOneWidget,
        ); // Matrix Card
        expect(
          find.text('Diagnostics & Validated Evidence'),
          findsOneWidget,
        ); // Diagnostics Card

        // Verify Reset Action
        expect(find.text('New Check'), findsOneWidget);
        await tester.tap(find.text('New Check'));
        await tester.pumpAndSettle();

        expect(
          find.widgetWithText(ElevatedButton, 'Check Alignment'),
          findsOneWidget,
        );
      },
    );

    testWidgets('shows ErrorView when failure state is emitted', (
      tester,
    ) async {
      final repo = _MockRepo();
      final cubit = StudentManuscriptCheckerCubit(
        checkManuscriptUseCase: CheckManuscriptUseCase(repo),
      );

      await tester.pumpWidget(_buildTestApp(cubit: cubit));
      await tester.pumpAndSettle();

      cubit.emit(
        const StudentManuscriptCheckerFailure(
          message: 'Could not connect to analysis service.',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ErrorView), findsOneWidget);
      expect(
        find.text('Could not connect to analysis service.'),
        findsOneWidget,
      );
      expect(find.text('Return to Submission Form'), findsOneWidget);

      await tester.tap(find.text('Return to Submission Form'));
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(ElevatedButton, 'Check Alignment'),
        findsOneWidget,
      );
    });

    testWidgets('shows Empty view when manuscript has no readable sections', (
      tester,
    ) async {
      final repo = _MockRepo();
      final cubit = StudentManuscriptCheckerCubit(
        checkManuscriptUseCase: CheckManuscriptUseCase(repo),
      );

      await tester.pumpWidget(_buildTestApp(cubit: cubit));
      await tester.pumpAndSettle();

      cubit.emit(
        const StudentManuscriptCheckerEmpty(
          message: 'The manuscript is empty or contains no readable sections.',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No Manuscript Sections Found'), findsOneWidget);
      expect(find.text('Submit Another Draft'), findsOneWidget);

      await tester.tap(find.text('Submit Another Draft'));
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(ElevatedButton, 'Check Alignment'),
        findsOneWidget,
      );
    });

    testWidgets(
      'renders results dashboard without overflow on narrow viewport (360px)',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final repo = _MockRepo();
        final cubit = StudentManuscriptCheckerCubit(
          checkManuscriptUseCase: CheckManuscriptUseCase(repo),
        );

        cubit.emit(
          StudentManuscriptCheckerSuccess(
            result: _defaultResult(),
            manuscriptFileName: 'thesis_chapter1.pdf',
            targetJournalId: 'j-uuid-101',
            targetJournalTitle: 'IEEE Transactions on Software Engineering',
            includeExemplars: false,
          ),
        );

        await tester.pumpWidget(_buildTestApp(cubit: cubit));
        await tester.pumpAndSettle();

        // Verify key widgets are rendered without throwing any layout overflow exceptions
        expect(find.text('88.5'), findsOneWidget);
        expect(find.text('STYLE MATCH DISTRIBUTION'), findsOneWidget);
        expect(find.text('Priority Improvements'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'renders results dashboard without overflow on ultra-narrow viewport (320px)',
      (tester) async {
        tester.view.physicalSize = const Size(320, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final repo = _MockRepo();
        final cubit = StudentManuscriptCheckerCubit(
          checkManuscriptUseCase: CheckManuscriptUseCase(repo),
        );

        cubit.emit(
          StudentManuscriptCheckerSuccess(
            result: _defaultResult(),
            manuscriptFileName: 'thesis_chapter1.pdf',
            targetJournalId: 'j-uuid-101',
            targetJournalTitle: 'IEEE Transactions on Software Engineering',
            includeExemplars: false,
          ),
        );

        await tester.pumpWidget(_buildTestApp(cubit: cubit));
        await tester.pumpAndSettle();

        expect(find.text('88.5'), findsOneWidget);
      },
    );

    testWidgets(
      'renders results dashboard without overflow on tablet viewport (768px)',
      (tester) async {
        tester.view.physicalSize = const Size(768, 1024);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final repo = _MockRepo();
        final cubit = StudentManuscriptCheckerCubit(
          checkManuscriptUseCase: CheckManuscriptUseCase(repo),
        );

        cubit.emit(
          StudentManuscriptCheckerSuccess(
            result: _defaultResult(),
            manuscriptFileName: 'thesis_chapter1.pdf',
            targetJournalId: 'j-uuid-101',
            targetJournalTitle: 'IEEE Transactions on Software Engineering',
            includeExemplars: false,
          ),
        );

        await tester.pumpWidget(_buildTestApp(cubit: cubit));
        await tester.pumpAndSettle();

        expect(find.text('88.5'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
