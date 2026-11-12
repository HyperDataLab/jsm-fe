import '../../../../../core/localization/app_localizations.dart';

import 'package:material_ui/material_ui.dart';

import '../../../../../../app/theme/app_colors.dart';
import '../style_radar_chart.dart';

enum FingerprintViewMode { radar, parallel }

class StyleFingerprintCard extends StatefulWidget {
  final List<Map<String, dynamic>> profiles;
  final List<Color> colors;

  const StyleFingerprintCard({
    super.key,
    required this.profiles,
    required this.colors,
  });

  @override
  State<StyleFingerprintCard> createState() => _StyleFingerprintCardState();
}

class _StyleFingerprintCardState extends State<StyleFingerprintCard> {
  FingerprintViewMode _viewMode = FingerprintViewMode.radar;

  @override
  Widget build(BuildContext context) {
    if (widget.profiles.isEmpty) return const SizedBox.shrink();

    final axisTitles = [
      context.l10n.radarAxisSentenceLength,
      context.l10n.radarAxisLexicalDensity,
      context.l10n.radarAxisHedges,
      context.l10n.radarAxisBoosters,
      context.l10n.radarAxisNeutral,
      context.l10n.radarAxisCars,
    ];

    final datasets = <RadarDataset>[];
    for (int i = 0; i < widget.profiles.length; i++) {
      final color = widget.colors[i % widget.colors.length];
      datasets.add(
        RadarDataset.fromProfile(widget.profiles[i], color, context.l10n),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink900.withAlpha(4),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.fingerprint_rounded,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.profiles.length == 1
                        ? context.l10n.styleFingerprintTitle
                        : context.l10n.multiStyleFingerprintTitle,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontFamily: 'Manrope',
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  SegmentedButton<FingerprintViewMode>(
                    segments: [
                      ButtonSegment(
                        value: FingerprintViewMode.radar,
                        icon: const Icon(Icons.radar_rounded, size: 14),
                        label: Text(context.l10n.radarCoordinates),
                      ),
                      ButtonSegment(
                        value: FingerprintViewMode.parallel,
                        icon: const Icon(
                          Icons.stacked_line_chart_rounded,
                          size: 14,
                        ),
                        label: Text(context.l10n.parallelCoordinates),
                      ),
                    ],
                    selected: {_viewMode},
                    onSelectionChanged: (set) {
                      setState(() {
                        _viewMode = set.first;
                      });
                    },
                    style: SegmentedButton.styleFrom(
                      textStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Manrope',
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.styleFingerprintSubtitle,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
              fontFamily: 'Manrope',
            ),
          ),
          const SizedBox(height: 20),

          // Chart Display
          if (_viewMode == FingerprintViewMode.radar)
            StyleRadarChart(datasets: datasets, height: 340, showLegend: true)
          else
            _buildParallelCoordinates(datasets, axisTitles),
        ],
      ),
    );
  }

  Widget _buildParallelCoordinates(
    List<RadarDataset> datasets,
    List<String> axisTitles,
  ) {
    return Column(
      children: [
        // Legend
        Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: datasets.map((ds) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: ds.color.withAlpha(20),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: ds.color.withAlpha(120), width: 1.2),
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
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        // Parallel Axes Plot
        SizedBox(
          height: 320,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              const h = 260.0;
              final numAxes = axisTitles.length;
              final axisSpacing = w / (numAxes - 1);

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Axis Lines & Labels
                  for (int i = 0; i < numAxes; i++) ...[
                    Positioned(
                      left: i * axisSpacing - 0.5,
                      top: 10,
                      height: h,
                      child: Container(width: 1, color: AppColors.border),
                    ),
                    Positioned(
                      left: i * axisSpacing - 45,
                      top: h + 18,
                      width: 90,
                      child: Text(
                        axisTitles[i],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],

                  // Lines for each dataset
                  CustomPaint(
                    size: Size(w, h + 10),
                    painter: _ParallelCoordinatesPainter(
                      datasets: datasets,
                      numAxes: numAxes,
                      axisSpacing: axisSpacing,
                      plotHeight: h,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ParallelCoordinatesPainter extends CustomPainter {
  final List<RadarDataset> datasets;
  final int numAxes;
  final double axisSpacing;
  final double plotHeight;

  _ParallelCoordinatesPainter({
    required this.datasets,
    required this.numAxes,
    required this.axisSpacing,
    required this.plotHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const topPadding = 10.0;

    for (final ds in datasets) {
      if (ds.values.length < numAxes) continue;

      final path = Path();
      final points = <Offset>[];

      for (int i = 0; i < numAxes; i++) {
        final x = i * axisSpacing;
        final normVal = ds.values[i].clamp(0.0, 1.0);
        final y = topPadding + plotHeight * (1.0 - normVal);
        final pt = Offset(x, y);
        points.add(pt);

        if (i == 0) {
          path.moveTo(pt.dx, pt.dy);
        } else {
          path.lineTo(pt.dx, pt.dy);
        }
      }

      // Draw line
      final linePaint = Paint()
        ..color = ds.color.withAlpha(200)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      canvas.drawPath(path, linePaint);

      // Draw dots
      final dotPaint = Paint()
        ..color = ds.color
        ..style = PaintingStyle.fill;
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      for (final pt in points) {
        canvas.drawCircle(pt, 5, dotPaint);
        canvas.drawCircle(pt, 5, borderPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ParallelCoordinatesPainter oldDelegate) {
    return oldDelegate.datasets != datasets;
  }
}
