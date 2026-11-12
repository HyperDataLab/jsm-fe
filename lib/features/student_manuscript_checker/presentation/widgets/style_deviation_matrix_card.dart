import 'package:material_ui/material_ui.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/entities/manuscript_check_result.dart';

enum MatrixStatus { aligned, moderate, major }

class StyleDeviationMatrixCard extends StatelessWidget {
  final ManuscriptCheckResult result;

  const StyleDeviationMatrixCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final comp = result.featureComparison;
    final vp = comp.voiceAndPerson;
    final sl = comp.sentenceLength;
    final st = comp.stance;

    // Derived matrix statuses
    final slStatus = sl != null && sl.isWithinRange
        ? MatrixStatus.aligned
        : MatrixStatus.moderate;

    final pvDiff = vp != null
        ? (vp.userPassiveRate - vp.journalPassiveRate).abs()
        : 0.0;
    final pvStatus = pvDiff > 15.0
        ? MatrixStatus.major
        : pvDiff > 8.0
        ? MatrixStatus.moderate
        : MatrixStatus.aligned;

    final weDiff = vp != null ? (vp.userWeRate - vp.journalWeRate).abs() : 0.0;
    final weStatus = weDiff > 3.0
        ? MatrixStatus.major
        : weDiff > 1.5
        ? MatrixStatus.moderate
        : MatrixStatus.aligned;

    final hdDiff = st != null ? st.hedgeRateDiff.abs() : 0.0;
    final hdStatus = hdDiff > 6.0
        ? MatrixStatus.major
        : hdDiff > 3.0
        ? MatrixStatus.moderate
        : MatrixStatus.aligned;

    final bstDiff = st != null ? st.boosterRateDiff.abs() : 0.0;
    final bstStatus = bstDiff > 4.0
        ? MatrixStatus.major
        : bstDiff > 2.0
        ? MatrixStatus.moderate
        : MatrixStatus.aligned;

    final rmStatus = result.rhetoricalMoveWarnings.isNotEmpty
        ? MatrixStatus.major
        : MatrixStatus.aligned;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              const Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Icon(
                    Icons.grid_on_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  Text(
                    'Stylistic Deviation Matrix',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontFamily: 'Manrope',
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _buildLegendDot(AppColors.green700, 'Aligned'),
                  _buildLegendDot(const Color(0xFFD97706), 'Moderate'),
                  _buildLegendDot(AppColors.red700, 'Major'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Matrix Table with horizontal scroll support for narrow containers
          LayoutBuilder(
            builder: (context, constraints) {
              final tableWidth = constraints.maxWidth > 440
                  ? constraints.maxWidth
                  : 440.0;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: tableWidth,
                  child: Table(
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    columnWidths: const {
                      0: FlexColumnWidth(2.0),
                      1: FlexColumnWidth(1.0),
                      2: FlexColumnWidth(1.0),
                      3: FlexColumnWidth(1.0),
                      4: FlexColumnWidth(1.0),
                    },
                    children: [
                      // Header Row
                      TableRow(
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: AppColors.borderSoft,
                              width: 1.5,
                            ),
                          ),
                        ),
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 6),
                            child: Text(
                              'DIMENSION',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textSubtle,
                                fontFamily: 'Manrope',
                              ),
                            ),
                          ),
                          _buildHeaderCell('INTRO'),
                          _buildHeaderCell('METHODS'),
                          _buildHeaderCell('RESULTS'),
                          _buildHeaderCell('DISCUSSION'),
                        ],
                      ),

                      // Rows
                      _buildMatrixRow(
                        'Sentence Length',
                        slStatus,
                        slStatus,
                        slStatus,
                        slStatus,
                      ),
                      _buildMatrixRow(
                        'Passive Voice',
                        MatrixStatus.aligned,
                        pvStatus,
                        MatrixStatus.moderate,
                        MatrixStatus.aligned,
                      ),
                      _buildMatrixRow(
                        'Author Person ("We")',
                        weStatus,
                        MatrixStatus.moderate,
                        MatrixStatus.aligned,
                        MatrixStatus.aligned,
                      ),
                      _buildMatrixRow(
                        'Epistemic Hedges',
                        MatrixStatus.aligned,
                        MatrixStatus.aligned,
                        hdStatus,
                        MatrixStatus.aligned,
                      ),
                      _buildMatrixRow(
                        'Epistemic Boosters',
                        MatrixStatus.moderate,
                        bstStatus,
                        MatrixStatus.moderate,
                        MatrixStatus.aligned,
                      ),
                      _buildMatrixRow(
                        'Rhetorical Moves',
                        rmStatus,
                        MatrixStatus.aligned,
                        MatrixStatus.aligned,
                        MatrixStatus.aligned,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontFamily: 'Manrope',
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCell(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Center(
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: AppColors.textSubtle,
            fontFamily: 'Manrope',
          ),
        ),
      ),
    );
  }

  TableRow _buildMatrixRow(
    String label,
    MatrixStatus c1,
    MatrixStatus c2,
    MatrixStatus c3,
    MatrixStatus c4,
  ) {
    return TableRow(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.surfaceSoft)),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontFamily: 'Manrope',
            ),
          ),
        ),
        Center(child: _buildStatusDot(c1)),
        Center(child: _buildStatusDot(c2)),
        Center(child: _buildStatusDot(c3)),
        Center(child: _buildStatusDot(c4)),
      ],
    );
  }

  Widget _buildStatusDot(MatrixStatus status) {
    Color color = AppColors.green700;
    IconData icon = Icons.circle;

    if (status == MatrixStatus.major) {
      color = AppColors.red700;
      icon = Icons.cancel;
    } else if (status == MatrixStatus.moderate) {
      color = const Color(0xFFD97706);
      icon = Icons.change_history;
    }

    return Icon(icon, size: 10, color: color);
  }
}
