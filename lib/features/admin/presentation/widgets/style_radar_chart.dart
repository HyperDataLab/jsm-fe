import '../../../../core/localization/app_localizations.dart';

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../../../app/theme/app_colors.dart';

/// Represents a single journal's stylistic series plotted on the radar chart.
class RadarDataset {
  final String id;
  final String name;
  final Color color;
  final List<double> values;
  final List<String> rawDisplayValues;

  const RadarDataset({
    required this.id,
    required this.name,
    required this.color,
    required this.values,
    required this.rawDisplayValues,
  });

  /// Factory helper to build a normalized dataset from an API profile map.
  factory RadarDataset.fromProfile(
    Map<String, dynamic> profile,
    Color color,
    AppLocalizations l10n,
  ) {
    final name = profile['journal_name']?.toString() ?? 'Tạp chí';
    final id = profile['journal_id']?.toString() ?? name;
    final metrics = profile['sentence_metrics'] as Map<String, dynamic>?;
    final stance = profile['stance'] as Map<String, dynamic>?;
    final moves = profile['cars_moves'] as Map<String, dynamic>?;

    final meanLen = (metrics?['mean_length'] as num?)?.toDouble() ?? 22.0;
    final lexDensity =
        (metrics?['lexical_density'] as num?)?.toDouble() ?? 0.55;
    final hedges = (metrics?['hedges_per_1k'] as num?)?.toDouble() ?? 15.0;
    final boosters = (metrics?['boosters_per_1k'] as num?)?.toDouble() ?? 10.0;
    final neutral = (stance?['neutral'] as num?)?.toDouble() ?? 0.65;

    final m1 = (moves?['territory'] as num?)?.toDouble() ?? 0.90;
    final m2 = (moves?['niche'] as num?)?.toDouble() ?? 0.85;
    final m3 = (moves?['occupying'] as num?)?.toDouble() ?? 0.88;
    final carsScore = (m1 + m2 + m3) / 3.0;

    // Normalization logic: Scale each metric between 0.1 and 1.0 for visual balance
    final normLen = ((meanLen - 12.0) / 20.0).clamp(0.1, 1.0);
    final normLex = ((lexDensity - 0.35) / 0.35).clamp(0.1, 1.0);
    final normHedge = (hedges / 32.0).clamp(0.1, 1.0);
    final normBooster = (boosters / 24.0).clamp(0.1, 1.0);
    final normNeutral = neutral.clamp(0.1, 1.0);
    final normCars = carsScore.clamp(0.1, 1.0);

    return RadarDataset(
      id: id,
      name: name,
      color: color,
      values: [normLen, normLex, normHedge, normBooster, normNeutral, normCars],
      rawDisplayValues: [
        l10n.rawSentenceLength(meanLen.toStringAsFixed(1)),
        l10n.rawLexicalDensity((lexDensity * 100).toStringAsFixed(0)),
        l10n.rawPer1k(hedges.toStringAsFixed(1)),
        l10n.rawPer1k(boosters.toStringAsFixed(1)),
        l10n.rawNeutral((neutral * 100).toStringAsFixed(0)),
        l10n.rawCars((carsScore * 100).toStringAsFixed(0)),
      ],
    );
  }
}

/// Interactive 6-Axis Multi-Series Radar Chart for style fingerprint comparison
/// with hover inspection and floating tooltip badges.
class StyleRadarChart extends StatefulWidget {
  final List<RadarDataset> datasets;
  final double height;
  final bool showLegend;

  const StyleRadarChart({
    super.key,
    required this.datasets,
    this.height = 360,
    this.showLegend = true,
  });

  @override
  State<StyleRadarChart> createState() => _StyleRadarChartState();
}

class _StyleRadarChartState extends State<StyleRadarChart> {
  int? _hoveredDatasetIndex;
  int? _hoveredAxisIndex;
  Offset? _hoverPosition;

  @override
  void didUpdateWidget(covariant StyleRadarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_hoveredDatasetIndex != null &&
        _hoveredDatasetIndex! >= widget.datasets.length) {
      _hoveredDatasetIndex = null;
      _hoveredAxisIndex = null;
      _hoverPosition = null;
    }
  }

  void _handleHover(Offset localPos, double width, double height) {
    if (widget.datasets.isEmpty) return;

    final center = Offset(width / 2, height / 2);
    final maxRadius = (math.min(width, height) / 2) - 44.0;
    if (maxRadius <= 20) return;

    const totalAxes = 6;
    final angleStep = (2 * math.pi) / totalAxes;
    const startAngle = -math.pi / 2;

    int? bestDs;
    int? bestAxis;
    double minDistance = double.infinity;
    const hitRadius = 18.0;

    for (int dsIdx = 0; dsIdx < widget.datasets.length; dsIdx++) {
      final dataset = widget.datasets[dsIdx];
      if (dataset.values.length < totalAxes) continue;

      for (int i = 0; i < totalAxes; i++) {
        final angle = startAngle + i * angleStep;
        final val = dataset.values[i].clamp(0.05, 1.0);
        final r = maxRadius * val;
        final pt = Offset(
          center.dx + r * math.cos(angle),
          center.dy + r * math.sin(angle),
        );

        final dist = (localPos - pt).distance;
        if (dist <= hitRadius && dist < minDistance) {
          minDistance = dist;
          bestDs = dsIdx;
          bestAxis = i;
        }
      }
    }

    if (bestDs != _hoveredDatasetIndex ||
        bestAxis != _hoveredAxisIndex ||
        localPos != _hoverPosition) {
      setState(() {
        _hoveredDatasetIndex = bestDs;
        _hoveredAxisIndex = bestAxis;
        _hoverPosition = (bestDs != null) ? localPos : null;
      });
    }
  }

  void _handleExit() {
    if (_hoveredDatasetIndex != null) {
      setState(() {
        _hoveredDatasetIndex = null;
        _hoveredAxisIndex = null;
        _hoverPosition = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final axisTitles = [
      context.l10n.radarAxisSentenceLength,
      context.l10n.radarAxisLexicalDensity,
      context.l10n.radarAxisHedges,
      context.l10n.radarAxisBoosters,
      context.l10n.radarAxisNeutral,
      context.l10n.radarAxisCars,
    ];

    if (widget.datasets.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: Center(
          child: Text(
            context.l10n.selectJournalsForRadar,
            style: TextStyle(color: AppColors.textSubtle, fontSize: 13),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final chartWidth = constraints.maxWidth;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Legend
            if (widget.showLegend) ...[
              Wrap(
                spacing: 16,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: widget.datasets.map((ds) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: ds.color.withAlpha(20),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: ds.color.withAlpha(120),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: ds.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          ds.name,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Radar Chart with Interactive Hover & Floating Tooltip
            SizedBox(
              width: chartWidth,
              height: widget.height,
              child: MouseRegion(
                onHover: (event) => _handleHover(
                  event.localPosition,
                  chartWidth,
                  widget.height,
                ),
                onExit: (_) => _handleExit(),
                cursor: _hoveredDatasetIndex != null
                    ? SystemMouseCursors.click
                    : MouseCursor.defer,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CustomPaint(
                      size: Size(chartWidth, widget.height),
                      painter: _StyleRadarPainter(
                        datasets: widget.datasets,
                        axisTitles: axisTitles,

                        hoveredDatasetIndex: _hoveredDatasetIndex,
                        hoveredAxisIndex: _hoveredAxisIndex,
                      ),
                    ),
                    // Floating Tooltip Badge
                    if (_hoveredDatasetIndex != null &&
                        _hoveredAxisIndex != null &&
                        _hoverPosition != null &&
                        _hoveredDatasetIndex! < widget.datasets.length)
                      _buildFloatingTooltip(
                        chartWidth,
                        widget.height,
                        axisTitles,
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFloatingTooltip(
    double chartWidth,
    double chartHeight,
    List<String> axisTitles,
  ) {
    final ds = widget.datasets[_hoveredDatasetIndex!];
    final axisIdx = _hoveredAxisIndex!;
    final pos = _hoverPosition!;

    const tooltipWidth = 230.0;
    const tooltipHeight = 92.0;

    // Boundary aware positioning
    double left = pos.dx + 16.0;
    if (left + tooltipWidth > chartWidth - 10) {
      left = pos.dx - tooltipWidth - 16.0;
    }
    if (left < 10) left = 10;

    double top = pos.dy - tooltipHeight - 12.0;
    if (top < 10) {
      top = pos.dy + 18.0;
    }
    if (top + tooltipHeight > chartHeight - 10) {
      top = chartHeight - tooltipHeight - 10;
    }

    final rawVal = (axisIdx < ds.rawDisplayValues.length)
        ? ds.rawDisplayValues[axisIdx]
        : '-';
    final normPct = (axisIdx < ds.values.length)
        ? '${(ds.values[axisIdx] * 100).toStringAsFixed(0)}%'
        : '-';
    final title = axisTitles[axisIdx];

    return Positioned(
      left: left,
      top: top,
      child: IgnorePointer(
        child: Container(
          width: tooltipWidth,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ds.color.withAlpha(140), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(24),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
              BoxShadow(
                color: ds.color.withAlpha(20),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header: Journal Color Dot + Name + Normalized Score Badge
              Row(
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: ds.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      ds.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontFamily: 'Manrope',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: ds.color.withAlpha(24),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      normPct,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: ds.color,
                        fontFamily: 'Manrope',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Axis Name
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                  fontFamily: 'Manrope',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              // Raw Value
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    context.l10n.measuredLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSubtle,
                      fontFamily: 'Manrope',
                    ),
                  ),
                  Text(
                    rawVal,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: ds.color,
                      fontFamily: 'Manrope',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StyleRadarPainter extends CustomPainter {
  final List<RadarDataset> datasets;
  final List<String> axisTitles;

  final int? hoveredDatasetIndex;
  final int? hoveredAxisIndex;

  _StyleRadarPainter({
    required this.datasets,
    required this.axisTitles,

    this.hoveredDatasetIndex,
    this.hoveredAxisIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // Reserve margin for text labels around vertices
    final maxRadius = (math.min(size.width, size.height) / 2) - 44.0;
    if (maxRadius <= 20) return;

    final ringPaint = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final ringLevels = [0.2, 0.4, 0.6, 0.8, 1.0];
    const totalAxes = 6;
    final angleStep = (2 * math.pi) / totalAxes;
    // Start pointing straight UP (-pi / 2)
    const startAngle = -math.pi / 2;

    // 1. Draw concentric hexagonal grid rings
    for (final level in ringLevels) {
      final r = maxRadius * level;
      final path = Path();
      for (int i = 0; i < totalAxes; i++) {
        final angle = startAngle + i * angleStep;
        final x = center.dx + r * math.cos(angle);
        final y = center.dy + r * math.sin(angle);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, ringPaint);
    }

    // 2. Draw radial axis lines from center to outer ring
    final axisLinePaint = Paint()
      ..color = AppColors.border.withAlpha(180)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 0; i < totalAxes; i++) {
      final angle = startAngle + i * angleStep;
      final outerX = center.dx + maxRadius * math.cos(angle);
      final outerY = center.dy + maxRadius * math.sin(angle);
      canvas.drawLine(center, Offset(outerX, outerY), axisLinePaint);

      // Draw axis labels
      _drawAxisLabel(canvas, center, maxRadius, angle, i);
    }

    // 3. Draw dataset polygons & vertices
    for (int dsIdx = 0; dsIdx < datasets.length; dsIdx++) {
      final dataset = datasets[dsIdx];
      if (dataset.values.length < totalAxes) continue;

      final polyPath = Path();
      final points = <Offset>[];

      for (int i = 0; i < totalAxes; i++) {
        final angle = startAngle + i * angleStep;
        final val = dataset.values[i].clamp(0.05, 1.0);
        final r = maxRadius * val;
        final x = center.dx + r * math.cos(angle);
        final y = center.dy + r * math.sin(angle);
        final pt = Offset(x, y);
        points.add(pt);

        if (i == 0) {
          polyPath.moveTo(x, y);
        } else {
          polyPath.lineTo(x, y);
        }
      }
      polyPath.close();

      // Transparent polygon fill
      final fillPaint = Paint()
        ..color = dataset.color.withAlpha(38)
        ..style = PaintingStyle.fill;
      canvas.drawPath(polyPath, fillPaint);

      // Solid outline stroke
      final strokePaint = Paint()
        ..color = dataset.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(polyPath, strokePaint);

      // Draw vertex markers with white center
      final dotFill = Paint()..color = Colors.white;
      final dotStroke = Paint()
        ..color = dataset.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      for (int i = 0; i < points.length; i++) {
        final pt = points[i];
        final isHovered =
            (hoveredDatasetIndex == dsIdx && hoveredAxisIndex == i);

        if (isHovered) {
          // Draw outer halo glow
          final haloPaint = Paint()
            ..color = dataset.color.withAlpha(50)
            ..style = PaintingStyle.fill;
          canvas.drawCircle(pt, 12.0, haloPaint);

          final haloRing = Paint()
            ..color = dataset.color.withAlpha(160)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6;
          canvas.drawCircle(pt, 9.0, haloRing);

          // Enlarge point
          canvas.drawCircle(pt, 5.5, dotFill);
          canvas.drawCircle(
            pt,
            5.5,
            Paint()
              ..color = dataset.color
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.8,
          );
        } else {
          canvas.drawCircle(pt, 4.0, dotFill);
          canvas.drawCircle(pt, 4.0, dotStroke);
        }
      }
    }
  }

  void _drawAxisLabel(
    Canvas canvas,
    Offset center,
    double radius,
    double angle,
    int index,
  ) {
    final title = axisTitles[index];
    final textSpan = TextSpan(
      text: title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // Position label slightly outside the vertex
    final labelDistance = radius + 22.0;
    final lx = center.dx + labelDistance * math.cos(angle);
    final ly = center.dy + labelDistance * math.sin(angle);

    final offset = Offset(
      lx - (textPainter.width / 2),
      ly - (textPainter.height / 2),
    );

    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _StyleRadarPainter oldDelegate) {
    if (oldDelegate.hoveredDatasetIndex != hoveredDatasetIndex ||
        oldDelegate.hoveredAxisIndex != hoveredAxisIndex) {
      return true;
    }
    if (oldDelegate.datasets.length != datasets.length) return true;
    for (int i = 0; i < datasets.length; i++) {
      if (oldDelegate.datasets[i].id != datasets[i].id ||
          oldDelegate.datasets[i].color != datasets[i].color) {
        return true;
      }
    }
    return false;
  }
}
