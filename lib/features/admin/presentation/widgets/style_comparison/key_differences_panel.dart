import '../../../../../core/localization/app_localizations.dart';

import 'package:material_ui/material_ui.dart';

import '../../../../../../app/theme/app_colors.dart';

class KeyDifferencesPanel extends StatefulWidget {
  final List<Map<String, dynamic>> profiles;
  final List<Color> colors;

  const KeyDifferencesPanel({
    super.key,
    required this.profiles,
    required this.colors,
  });

  @override
  State<KeyDifferencesPanel> createState() => _KeyDifferencesPanelState();
}

class _KeyDifferencesPanelState extends State<KeyDifferencesPanel> {
  final Set<int> _expandedInsights = {};

  @override
  Widget build(BuildContext context) {
    if (widget.profiles.isEmpty) return const SizedBox.shrink();

    // If single profile, show key profile summary
    if (widget.profiles.length == 1) {
      return _buildSingleJournalSummary();
    }

    final insights = _calculateTopDifferences();

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
                    Icons.bolt_rounded,
                    size: 20,
                    color: Color(0xFFD97706),
                  ),
                  SizedBox(width: 8),
                  Text(
                    context.l10n.keyDifferencesTitle,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontFamily: 'Manrope',
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFD97706).withAlpha(15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  context.l10n.top3Differences,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD97706),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.styleDifferencesSubtitle,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
              fontFamily: 'Manrope',
            ),
          ),
          const SizedBox(height: 16),

          ...insights.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            final isExpanded = _expandedInsights.contains(idx);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: item.leaderColor.withAlpha(12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: item.leaderColor.withAlpha(50)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: item.leaderColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '#${idx + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                fontFamily: 'Manrope',
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.shortHighlight,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: item.leaderColor,
                                fontFamily: 'Manrope',
                              ),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          setState(() {
                            if (isExpanded) {
                              _expandedInsights.remove(idx);
                            } else {
                              _expandedInsights.add(idx);
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          child: Row(
                            children: [
                              Text(
                                isExpanded
                                    ? context.l10n.collapse
                                    : context.l10n.explain,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Icon(
                                isExpanded
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.keyboard_arrow_down_rounded,
                                size: 16,
                                color: AppColors.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (isExpanded) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(200),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.detailedExplanation,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                          height: 1.4,
                          fontFamily: 'Manrope',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSingleJournalSummary() {
    final p = widget.profiles.first;
    final name = p['journal_name'] ?? 'Tạp chí';
    final metrics = p['sentence_metrics'] as Map<String, dynamic>?;
    final stance = p['stance'] as Map<String, dynamic>?;

    final meanLen = (metrics?['mean_length'] as num?)?.toDouble() ?? 22.0;
    final lexDensity =
        (metrics?['lexical_density'] as num?)?.toDouble() ?? 0.55;
    final hedges = (metrics?['hedges_per_1k'] as num?)?.toDouble() ?? 15.0;
    final boosters = (metrics?['boosters_per_1k'] as num?)?.toDouble() ?? 10.0;
    final neutral = (stance?['neutral'] as num?)?.toDouble() ?? 0.65;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_outline_rounded,
                size: 18,
                color: Color(0xFFD97706),
              ),
              const SizedBox(width: 8),
              Text(
                context.l10n.styleFeatureTitle(name),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStaticInsight(
            context.l10n.sentenceComplexity,
            context.l10n.isVietnamese
                ? 'Độ dài câu trung bình ${meanLen.toStringAsFixed(1)} từ, mật độ từ vựng ${(lexDensity * 100).toInt()}%. '
                : 'Average sentence length of ${meanLen.toStringAsFixed(1)} words, lexical density of ${(lexDensity * 100).toInt()}%.',
            widget.colors[0],
          ),
          const SizedBox(height: 10),
          _buildStaticInsight(
            context.l10n.academicTone,
            context.l10n.isVietnamese
                ? 'Cân bằng giữa ${hedges.toStringAsFixed(1)} từ rào đón/1k từ và ${boosters.toStringAsFixed(1)} từ khẳng định/1k từ.'
                : 'Balanced between ${hedges.toStringAsFixed(1)} hedges/1k words and ${boosters.toStringAsFixed(1)} boosters/1k words.',
            widget.colors[0],
          ),
          const SizedBox(height: 10),
          _buildStaticInsight(
            context.l10n.objectiveNeutral,
            context.l10n.isVietnamese
                ? 'Đạt ${(neutral * 100).toInt()}% câu mang lập trường trung lập, tuân thủ chuẩn mực xuất bản khoa học.'
                : 'Achieved ${(neutral * 100).toInt()}% neutral stance sentences, following scientific publication standards.',
            widget.colors[0],
          ),
        ],
      ),
    );
  }

  Widget _buildStaticInsight(String title, String desc, Color col) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: col.withAlpha(12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: col.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            desc,
            style: const TextStyle(
              fontSize: 11.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  List<_DifferenceItem> _calculateTopDifferences() {
    final list = <_DifferenceItem>[];

    // 1. Lexical Density
    _evaluateDifference(
      list,
      title: context.l10n.lexicalDensityLabel,
      unit: '%',
      isPercent: true,
      getValue: (p) =>
          (p['sentence_metrics']?['lexical_density'] as num?)?.toDouble() ??
          0.5,
      getExplanation: (leader, minName, diff, leaderVal, minVal) =>
          context.l10n.isVietnamese
          ? '$leader có mật độ thông tin học thuật cao hơn $minName (${(leaderVal * 100).toStringAsFixed(0)}% vs ${(minVal * 100).toStringAsFixed(0)}%), thể hiện tỷ lệ danh từ, động từ nội dung cao hơn.'
          : '$leader has higher academic information density than $minName (${(leaderVal * 100).toStringAsFixed(0)}% vs ${(minVal * 100).toStringAsFixed(0)}%), indicating a higher proportion of content words.',
    );

    // 2. Sentence Length
    _evaluateDifference(
      list,
      title: context.l10n.sentenceLengthLabel,
      unit: context.l10n.unitWordsPerSentence,
      isPercent: false,
      getValue: (p) =>
          (p['sentence_metrics']?['mean_length'] as num?)?.toDouble() ?? 20.0,
      getExplanation: (leader, minName, diff, leaderVal, minVal) =>
          context.l10n.isVietnamese
          ? '$leader chuộng câu phức hợp nhiều mệnh đề (${leaderVal.toStringAsFixed(1)} từ/câu) so với văn phong cô đọng của $minName (${minVal.toStringAsFixed(1)} từ/câu).'
          : '$leader prefers multi-clause complex sentences (${leaderVal.toStringAsFixed(1)} words/sent) compared to the concise style of $minName (${minVal.toStringAsFixed(1)} words/sent).',
    );

    // 3. Boosters
    _evaluateDifference(
      list,
      title: context.l10n.boostersLabel,
      unit: context.l10n.unitPer1kWords,
      isPercent: false,
      getValue: (p) =>
          (p['sentence_metrics']?['boosters_per_1k'] as num?)?.toDouble() ??
          5.0,
      getExplanation: (leader, minName, diff, leaderVal, minVal) =>
          context.l10n.isVietnamese
          ? '$leader sử dụng từ ngữ quả quyết mạnh mẽ hơn $minName (${leaderVal.toStringAsFixed(1)} vs ${minVal.toStringAsFixed(1)} trên 1.000 từ), tạo giọng văn quyết đoán hơn.'
          : '$leader uses stronger boosters than $minName (${leaderVal.toStringAsFixed(1)} vs ${minVal.toStringAsFixed(1)} per 1,000 words), creating a more assertive tone.',
    );

    // 4. Hedges
    _evaluateDifference(
      list,
      title: context.l10n.hedgingLabel,
      unit: context.l10n.unitPer1kWords,
      isPercent: false,
      getValue: (p) =>
          (p['sentence_metrics']?['hedges_per_1k'] as num?)?.toDouble() ?? 10.0,
      getExplanation: (leader, minName, diff, leaderVal, minVal) =>
          context.l10n.isVietnamese
          ? '$leader thận trọng hơn trong nhận định, dùng nhiều từ rào đón (${leaderVal.toStringAsFixed(1)} vs ${minVal.toStringAsFixed(1)}/1k từ) để giảm tính tuyệt đối.'
          : '$leader is more cautious in claims, using more hedges (${leaderVal.toStringAsFixed(1)} vs ${minVal.toStringAsFixed(1)}/1k words) to reduce absoluteness.',
    );

    // 5. Neutral stance
    _evaluateDifference(
      list,
      title: context.l10n.neutralStanceLabel,
      unit: '%',
      isPercent: true,
      getValue: (p) => (p['stance']?['neutral'] as num?)?.toDouble() ?? 0.7,
      getExplanation: (leader, minName, diff, leaderVal, minVal) =>
          context.l10n.isVietnamese
          ? '$leader duy trì lập trường khách quan cao hơn (${(leaderVal * 100).toStringAsFixed(0)}% vs ${(minVal * 100).toStringAsFixed(0)}%), hạn chế bộc lộ cảm tính trong kết quả.'
          : '$leader maintains a higher objective stance (${(leaderVal * 100).toStringAsFixed(0)}% vs ${(minVal * 100).toStringAsFixed(0)}%), limiting emotional expression in results.',
    );

    // Sort by relative difference magnitude
    list.sort((a, b) => b.normalizedDiffScore.compareTo(a.normalizedDiffScore));
    return list.take(3).toList();
  }

  void _evaluateDifference(
    List<_DifferenceItem> list, {
    required String title,
    required String unit,
    required bool isPercent,
    required double Function(Map<String, dynamic>) getValue,
    required String Function(
      String leader,
      String minName,
      double diff,
      double leaderVal,
      double minVal,
    )
    getExplanation,
  }) {
    double maxVal = -1.0;
    double minVal = double.infinity;
    int maxIdx = 0;
    int minIdx = 0;

    for (int i = 0; i < widget.profiles.length; i++) {
      final v = getValue(widget.profiles[i]);
      if (v > maxVal) {
        maxVal = v;
        maxIdx = i;
      }
      if (v < minVal) {
        minVal = v;
        minIdx = i;
      }
    }

    final diff = maxVal - minVal;
    final leaderName =
        widget.profiles[maxIdx]['journal_name'] ?? 'Tạp chí $maxIdx';
    final minName =
        widget.profiles[minIdx]['journal_name'] ?? 'Tạp chí $minIdx';
    final leaderColor = widget.colors[maxIdx % widget.colors.length];

    final score = isPercent ? diff : (diff / (maxVal == 0 ? 1 : maxVal));
    final diffFormatted = isPercent
        ? '+${(diff * 100).toStringAsFixed(1)}%'
        : '+${diff.toStringAsFixed(1)} $unit';

    list.add(
      _DifferenceItem(
        title: title,
        shortHighlight: context.l10n.higherByLabel(leaderName, diffFormatted),
        detailedExplanation: getExplanation(
          leaderName,
          minName,
          diff,
          maxVal,
          minVal,
        ),
        leaderColor: leaderColor,
        normalizedDiffScore: score,
      ),
    );
  }
}

class _DifferenceItem {
  final String title;
  final String shortHighlight;
  final String detailedExplanation;
  final Color leaderColor;
  final double normalizedDiffScore;

  _DifferenceItem({
    required this.title,
    required this.shortHighlight,
    required this.detailedExplanation,
    required this.leaderColor,
    required this.normalizedDiffScore,
  });
}
