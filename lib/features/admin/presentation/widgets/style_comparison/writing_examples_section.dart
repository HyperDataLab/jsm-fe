import '../../../../../core/localization/app_localizations.dart';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../../../../../../app/theme/app_colors.dart';
import '../../../../../../core/widgets/app_notification.dart';

class WritingExamplesSection extends StatelessWidget {
  final List<Map<String, dynamic>> profiles;
  final List<Color> colors;

  const WritingExamplesSection({
    super.key,
    required this.profiles,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    if (profiles.isEmpty) return const SizedBox.shrink();

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
            children: [
              const Icon(
                Icons.format_quote_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                context.l10n.writingExamplesTitle,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontFamily: 'Manrope',
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.writingExamplesSubtitle,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
              fontFamily: 'Manrope',
            ),
          ),
          const SizedBox(height: 20),

          // Side-by-side or stacked cards
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 800;

              if (isWide && profiles.length > 1) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: profiles.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final p = entry.value;
                    final col = colors[idx % colors.length];

                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: idx < profiles.length - 1 ? 16 : 0,
                        ),
                        child: _buildExemplarCard(context, p, col),
                      ),
                    );
                  }).toList(),
                );
              }

              return Column(
                children: profiles.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final p = entry.value;
                  final col = colors[idx % colors.length];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildExemplarCard(context, p, col),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExemplarCard(
    BuildContext context,
    Map<String, dynamic> profile,
    Color color,
  ) {
    final name = profile['journal_name'] ?? 'Tạp chí';
    final exemplar = profile['exemplar'] as Map<String, dynamic>?;
    final sentence =
        exemplar?['sentence'] ??
        'We present an empirical evaluation of deep neural models across large-scale scientific corpora to benchmark linguistic variation.';
    final doi =
        exemplar?['doi'] ?? 'https://doi.org/10.1371/journal.pone.0297921';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.content_copy_rounded,
                  size: 16,
                  color: AppColors.textMuted,
                ),
                tooltip: context.l10n.copySentenceTooltip,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: sentence));
                  AppNotification.showSuccess(
                    context,
                    context.l10n.sentenceCopied,
                    duration: const Duration(seconds: 2),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '“$sentence”',
            style: const TextStyle(
              fontSize: 12.5,
              fontStyle: FontStyle.italic,
              color: AppColors.textPrimary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.link_rounded,
                size: 14,
                color: AppColors.textSubtle,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  doi,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
