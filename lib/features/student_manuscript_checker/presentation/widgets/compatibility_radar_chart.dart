import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/entities/manuscript_check_result.dart';

class RadarDimension {
  final String label;
  final double userValue;
  final double journalValue;
  final String userDisplay;
  final String journalDisplay;
  final String deviationDisplay;
  final String status;

  const RadarDimension({
    required this.label,
    required this.userValue,
    required this.journalValue,
    required this.userDisplay,
    required this.journalDisplay,
    required this.deviationDisplay,
    required this.status,
  });
}

class CompatibilityRadarChart extends StatefulWidget {
  final ManuscriptCheckResult result;

  const CompatibilityRadarChart({super.key, required this.result});

  @override
  State<CompatibilityRadarChart> createState() =>
      _CompatibilityRadarChartState();
}

class _CompatibilityRadarChartState extends State<CompatibilityRadarChart> {
  int? _hoveredIndex;

  List<RadarDimension> _extractDimensions() {
    final comparison = widget.result.featureComparison;
    final vp = comparison.voiceAndPerson;
    final sl = comparison.sentenceLength;
    final st = comparison.stance;

    // Calculate section structure alignment (average of available sections)
    double secScore = 0.85;
    if (widget.result.sectionScores.isNotEmpty) {
      secScore =
          widget.result.sectionScores.values.reduce((a, b) => a + b) /
          (widget.result.sectionScores.length * 100.0);
    }

    // 1. Structure
    final dStructure = RadarDimension(
      label: 'Section Structure',
      userValue: secScore.clamp(0.1, 1.0),
      journalValue: 0.95,
      userDisplay: '${(secScore * 100).toStringAsFixed(0)}%',
      journalDisplay: '95%',
      deviationDisplay: '${((secScore - 0.95) * 100).toStringAsFixed(0)} pp',
      status: secScore >= 0.85 ? 'Aligned' : 'Needs Adjustment',
    );

    // 2. Sentence Length
    double slUser = 0.5;
    double slJournal = 0.7;
    String slUserDisp = 'N/A';
    String slJournDisp = 'N/A';
    String slDevDisp = 'N/A';
    String slStatus = 'Aligned';
    if (sl != null) {
      slUserDisp = '${sl.userMedian.toStringAsFixed(1)} words';
      slJournDisp = '${sl.journalMedian.toStringAsFixed(1)} words';
      slUser = (sl.userMedian / 40.0).clamp(0.1, 1.0);
      slJournal = (sl.journalMedian / 40.0).clamp(0.1, 1.0);
      slDevDisp =
          '${(sl.userMedian - sl.journalMedian).toStringAsFixed(1)} words';
      slStatus = sl.isWithinRange ? 'Within range' : 'Deviation';
    }
    final dSentenceLength = RadarDimension(
      label: 'Sentence Length',
      userValue: slUser,
      journalValue: slJournal,
      userDisplay: slUserDisp,
      journalDisplay: slJournDisp,
      deviationDisplay: slDevDisp,
      status: slStatus,
    );

    // 3. Passive Voice
    double pvUser = 0.5;
    double pvJournal = 0.6;
    String pvUserDisp = 'N/A';
    String pvJournDisp = 'N/A';
    String pvDevDisp = 'N/A';
    String pvStatus = 'Aligned';
    if (vp != null) {
      pvUser = (vp.userPassiveRate / 40.0).clamp(0.1, 1.0);
      pvJournal = (vp.journalPassiveRate / 40.0).clamp(0.1, 1.0);
      pvUserDisp = '${vp.userPassiveRate.toStringAsFixed(1)}%';
      pvJournDisp = '${vp.journalPassiveRate.toStringAsFixed(1)}%';
      final diff = vp.userPassiveRate - vp.journalPassiveRate;
      pvDevDisp = '${diff >= 0 ? "+" : ""}${diff.toStringAsFixed(1)} pp';
      pvStatus = diff.abs() > 10 ? 'Moderate deviation' : 'Aligned';
    }
    final dPassive = RadarDimension(
      label: 'Passive Voice',
      userValue: pvUser,
      journalValue: pvJournal,
      userDisplay: pvUserDisp,
      journalDisplay: pvJournDisp,
      deviationDisplay: pvDevDisp,
      status: pvStatus,
    );

    // 4. Author Person
    double apUser = 0.1;
    double apJournal = 0.5;
    String apUserDisp = '0%';
    String apJournDisp = 'N/A';
    String apDevDisp = 'N/A';
    String apStatus = 'Aligned';
    if (vp != null) {
      apUser = (vp.userWeRate / 10.0).clamp(0.1, 1.0);
      apJournal = (vp.journalWeRate / 10.0).clamp(0.1, 1.0);
      apUserDisp = '${vp.userWeRate.toStringAsFixed(1)}%';
      apJournDisp = '${vp.journalWeRate.toStringAsFixed(1)}%';
      final diff = vp.userWeRate - vp.journalWeRate;
      apDevDisp = '${diff >= 0 ? "+" : ""}${diff.toStringAsFixed(1)} pp';
      apStatus = diff.abs() > 3 ? 'Major mismatch' : 'Aligned';
    }
    final dAuthor = RadarDimension(
      label: 'Author Person',
      userValue: apUser,
      journalValue: apJournal,
      userDisplay: apUserDisp,
      journalDisplay: apJournDisp,
      deviationDisplay: apDevDisp,
      status: apStatus,
    );

    // 5. Hedges
    double hdUser = 0.5;
    double hdJournal = 0.6;
    String hdUserDisp = 'N/A';
    String hdJournDisp = 'N/A';
    String hdDevDisp = 'N/A';
    String hdStatus = 'Aligned';
    if (st != null) {
      hdUser = (st.userHedgeRate / 30.0).clamp(0.1, 1.0);
      hdJournal = (st.journalHedgeRate / 30.0).clamp(0.1, 1.0);
      hdUserDisp = '${st.userHedgeRate.toStringAsFixed(1)} /1k';
      hdJournDisp = '${st.journalHedgeRate.toStringAsFixed(1)} /1k';
      final diff = st.userHedgeRate - st.journalHedgeRate;
      hdDevDisp = '${diff >= 0 ? "+" : ""}${diff.toStringAsFixed(1)} /1k';
      hdStatus = diff.abs() > 5 ? 'Moderate deviation' : 'Aligned';
    }
    final dHedges = RadarDimension(
      label: 'Hedges',
      userValue: hdUser,
      journalValue: hdJournal,
      userDisplay: hdUserDisp,
      journalDisplay: hdJournDisp,
      deviationDisplay: hdDevDisp,
      status: hdStatus,
    );

    // 6. Boosters
    double bstUser = 0.1;
    double bstJournal = 0.6;
    String bstUserDisp = '0 /1k';
    String bstJournDisp = 'N/A';
    String bstDevDisp = 'N/A';
    String bstStatus = 'Aligned';
    if (st != null) {
      bstUser = (st.userBoosterRate / 15.0).clamp(0.1, 1.0);
      bstJournal = (st.journalBoosterRate / 15.0).clamp(0.1, 1.0);
      bstUserDisp = '${st.userBoosterRate.toStringAsFixed(1)} /1k';
      bstJournDisp = '${st.journalBoosterRate.toStringAsFixed(1)} /1k';
      final diff = st.userBoosterRate - st.journalBoosterRate;
      bstDevDisp = '${diff >= 0 ? "+" : ""}${diff.toStringAsFixed(1)} /1k';
      bstStatus = diff.abs() > 3 ? 'Major mismatch' : 'Aligned';
    }
    final dBoosters = RadarDimension(
      label: 'Boosters',
      userValue: bstUser,
      journalValue: bstJournal,
      userDisplay: bstUserDisp,
      journalDisplay: bstJournDisp,
      deviationDisplay: bstDevDisp,
      status: bstStatus,
    );

    // 7. Rhetorical Moves
    final missingMovesCount = widget.result.rhetoricalMoveWarnings.length;
    final rmVal = (1.0 - (missingMovesCount * 0.25)).clamp(0.1, 1.0);
    final dMoves = RadarDimension(
      label: 'Rhetorical Moves',
      userValue: rmVal,
      journalValue: 0.95,
      userDisplay: missingMovesCount == 0
          ? 'All present'
          : '$missingMovesCount missing',
      journalDisplay: 'Complete',
      deviationDisplay: missingMovesCount == 0
          ? 'None'
          : '-$missingMovesCount moves',
      status: missingMovesCount == 0 ? 'Aligned' : 'Needs attention',
    );

    return [
      dStructure,
      dSentenceLength,
      dPassive,
      dAuthor,
      dHedges,
      dBoosters,
      dMoves,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final dimensions = _extractDimensions();

    return Container(
      constraints: const BoxConstraints(minHeight: 375),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              const Text(
                'Compatibility by Dimension',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontFamily: 'Manrope',
                ),
              ),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        'Manuscript',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                          fontFamily: 'Manrope',
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.textSubtle,
                            width: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        'Journal Profile',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                          fontFamily: 'Manrope',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 240,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return CustomPaint(
                  size: Size(constraints.maxWidth, 240),
                  painter: _RadarChartPainter(
                    dimensions: dimensions,
                    hoveredIndex: _hoveredIndex,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          // Tooltip/Detail strip for hovered or summary
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceAround,
              spacing: 12,
              runSpacing: 6,
              children: [
                _buildLegendItem('Structure', dimensions[0].status),
                _buildLegendItem('Voice/Person', dimensions[2].status),
                _buildLegendItem('Stance', dimensions[4].status),
                _buildLegendItem('Moves', dimensions[6].status),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String title, String status) {
    Color dotColor = AppColors.green700;
    if (status.toLowerCase().contains('major') ||
        status.toLowerCase().contains('needs')) {
      dotColor = AppColors.red700;
    } else if (status.toLowerCase().contains('moderate') ||
        status.toLowerCase().contains('deviation')) {
      dotColor = const Color(0xFFD97706);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
        ),
        const SizedBox(width: 5),
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            fontFamily: 'Manrope',
          ),
        ),
      ],
    );
  }
}

class _RadarChartPainter extends CustomPainter {
  final List<RadarDimension> dimensions;
  final int? hoveredIndex;

  _RadarChartPainter({required this.dimensions, this.hoveredIndex});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width / 2, size.height / 2) - 36;
    final numPoints = dimensions.length;
    final angleStep = (2 * math.pi) / numPoints;

    final gridPaint = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw concentric web polygons (4 levels: 25%, 50%, 75%, 100%)
    for (int level = 1; level <= 4; level++) {
      final levelRadius = radius * (level / 4.0);
      final path = Path();
      for (int i = 0; i < numPoints; i++) {
        final angle = -math.pi / 2 + (i * angleStep);
        final x = center.dx + levelRadius * math.cos(angle);
        final y = center.dy + levelRadius * math.sin(angle);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    // Draw axis lines and labels
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    for (int i = 0; i < numPoints; i++) {
      final angle = -math.pi / 2 + (i * angleStep);
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);

      canvas.drawLine(center, Offset(x, y), gridPaint);

      // Label
      final labelRadius = radius + 20;
      final lx = center.dx + labelRadius * math.cos(angle);
      final ly = center.dy + labelRadius * math.sin(angle);

      textPainter.text = TextSpan(
        text: dimensions[i].label,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          fontFamily: 'Manrope',
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(lx - textPainter.width / 2, ly - textPainter.height / 2),
      );
    }

    // Draw Journal Target Polygon
    final journalPath = Path();
    for (int i = 0; i < numPoints; i++) {
      final angle = -math.pi / 2 + (i * angleStep);
      final val = dimensions[i].journalValue;
      final x = center.dx + (radius * val) * math.cos(angle);
      final y = center.dy + (radius * val) * math.sin(angle);
      if (i == 0) {
        journalPath.moveTo(x, y);
      } else {
        journalPath.lineTo(x, y);
      }
    }
    journalPath.close();

    final journalStrokePaint = Paint()
      ..color = AppColors.slate400.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final journalFillPaint = Paint()
      ..color = AppColors.slate300.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    canvas.drawPath(journalPath, journalFillPaint);
    canvas.drawPath(journalPath, journalStrokePaint);

    // Draw User Manuscript Polygon
    final userPath = Path();
    for (int i = 0; i < numPoints; i++) {
      final angle = -math.pi / 2 + (i * angleStep);
      final val = dimensions[i].userValue;
      final x = center.dx + (radius * val) * math.cos(angle);
      final y = center.dy + (radius * val) * math.sin(angle);
      if (i == 0) {
        userPath.moveTo(x, y);
      } else {
        userPath.lineTo(x, y);
      }
    }
    userPath.close();

    final userFillPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    final userStrokePaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawPath(userPath, userFillPaint);
    canvas.drawPath(userPath, userStrokePaint);

    // Draw Points
    final dotPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    for (int i = 0; i < numPoints; i++) {
      final angle = -math.pi / 2 + (i * angleStep);
      final val = dimensions[i].userValue;
      final x = center.dx + (radius * val) * math.cos(angle);
      final y = center.dy + (radius * val) * math.sin(angle);
      canvas.drawCircle(Offset(x, y), 3.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarChartPainter oldDelegate) => true;
}
