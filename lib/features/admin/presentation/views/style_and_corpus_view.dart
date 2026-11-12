import 'package:material_ui/material_ui.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import 'profiles_review_view.dart';
import 'snapshots_view.dart';

/// Style & Corpus Unified Workspace (Tab 1)
/// Consolidates Member 3's deep NLP Style Profiles and Corpus Snapshots into
/// a sleek composite view with a top segmented tab switcher.
class StyleAndCorpusView extends StatefulWidget {
  final Function(int, {String? journalId}) onNavigateToTab;
  final String? selectedJournalId;
  final int initialSubTabIndex;

  const StyleAndCorpusView({
    super.key,
    required this.onNavigateToTab,
    this.selectedJournalId,
    this.initialSubTabIndex = 0,
  });

  @override
  State<StyleAndCorpusView> createState() => _StyleAndCorpusViewState();
}

class _StyleAndCorpusViewState extends State<StyleAndCorpusView> {
  late int _activeSubTab;

  @override
  void initState() {
    super.initState();
    _activeSubTab = widget.initialSubTabIndex;
  }

  @override
  void didUpdateWidget(covariant StyleAndCorpusView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSubTabIndex != widget.initialSubTabIndex) {
      setState(() => _activeSubTab = widget.initialSubTabIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Segmented Navigation Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(
              bottom: BorderSide(color: AppColors.border, width: 1),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildSegmentItem(
                  index: 0,
                  icon: Icons.psychology_rounded,
                  title: context.l10n.tabNlpProfilesTitle,
                  subtitle: context.l10n.tabNlpProfilesSubtitle,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildSegmentItem(
                  index: 1,
                  icon: Icons.layers_rounded,
                  title: context.l10n.tabCorpusSnapshotsTitle,
                  subtitle: context.l10n.tabCorpusSnapshotsSubtitle,
                ),
              ),
            ],
          ),
        ),

        // Sub-view Body (Using IndexedStack to preserve child state and scroll positions)
        Expanded(
          child: IndexedStack(
            index: _activeSubTab,
            children: [
              ProfilesReviewView(
                onNavigateToTab: widget.onNavigateToTab,
                selectedJournalId: widget.selectedJournalId,
              ),
              SnapshotsView(onNavigateToTab: widget.onNavigateToTab),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentItem({
    required int index,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _activeSubTab == index;

    return InkWell(
      onTap: () => setState(() => _activeSubTab = index),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.blue50 : AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w600,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                      fontFamily: 'Manrope',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      fontFamily: 'Manrope',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
