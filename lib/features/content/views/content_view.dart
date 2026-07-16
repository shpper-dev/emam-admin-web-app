import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:emam_admin_web_app/features/content/models/daily_inspiration.dart';
import 'package:emam_admin_web_app/features/content/models/islamic_event.dart';
import 'package:emam_admin_web_app/features/content/models/islamic_news_item.dart';
import 'package:emam_admin_web_app/features/content/models/practice_card.dart';
import 'package:emam_admin_web_app/features/content/models/scholarly_insight.dart';
import 'package:emam_admin_web_app/features/content/provider/content_provider.dart';
import 'package:emam_admin_web_app/features/content/views/widgets/content_section_card.dart';
import 'package:emam_admin_web_app/features/content/views/widgets/daily_inspiration_section.dart';
import 'package:emam_admin_web_app/features/content/views/widgets/islamic_events_section.dart';
import 'package:emam_admin_web_app/features/content/views/widgets/islamic_news_section.dart';
import 'package:emam_admin_web_app/features/content/views/widgets/practice_card_section.dart';
import 'package:emam_admin_web_app/features/content/views/widgets/scholarly_insights_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ContentView extends StatelessWidget {
  const ContentView({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding =
            contentHorizontalPadding(constraints.maxWidth);

        return _ContentRefreshWrapper(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              24,
              horizontalPadding,
              32,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _ContentPrefetch(),
                Text(
                  'Content Overview',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppConstants.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap a section to preview the content it serves to the Emam app.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 24),
                const _SectionTileGrid(),
                const SizedBox(height: 28),
                const RepaintBoundary(child: _SelectedSectionContent()),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Wraps [RefreshIndicator] as a Consumer so the outer [ContentView] can stay
/// a `StatelessWidget` and doesn't need to rebuild for pull-to-refresh.
class _ContentRefreshWrapper extends ConsumerWidget {
  const _ContentRefreshWrapper({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      color: AppConstants.primary,
      backgroundColor: AppConstants.surfaceColor,
      onRefresh: () => refreshAllContent(ref),
      child: child,
    );
  }
}

/// Invisible consumer that watches all 5 providers so the requests kick off in
/// parallel as soon as the page mounts, without triggering rebuilds of the
/// visible widget tree when their state changes.
class _ContentPrefetch extends ConsumerWidget {
  const _ContentPrefetch();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(dailyInspirationProvider);
    ref.watch(practiceCardProvider);
    ref.watch(islamicEventsProvider);
    ref.watch(islamicNewsProvider);
    ref.watch(scholarlyInsightsProvider);
    return const SizedBox.shrink();
  }
}

class _SectionTileGrid extends StatelessWidget {
  const _SectionTileGrid();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _tileGridColumns(constraints.maxWidth);
        const spacing = 16.0;
        final totalSpacing = spacing * (columns - 1);
        final tileWidth = (constraints.maxWidth - totalSpacing) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final section in ContentSection.values)
              SizedBox(
                width: tileWidth,
                child: _SectionTile(section: section),
              ),
          ],
        );
      },
    );
  }
}

class _SectionTile extends ConsumerWidget {
  const _SectionTile({required this.section});

  final ContentSection section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Subscribe only to whether *this* tile is currently selected. Other tiles
    // won't rebuild when the selection changes elsewhere.
    final selected = ref.watch(
      selectedContentSectionProvider.select((s) => s == section),
    );

    final borderColor = selected
        ? AppConstants.primary
        : Colors.white.withValues(alpha: 0.08);
    final background = selected
        ? AppConstants.primary.withValues(alpha: 0.14)
        : AppConstants.surfaceColor;
    final iconColor =
        selected ? AppConstants.primary : Colors.white.withValues(alpha: 0.78);
    final labelColor =
        selected ? AppConstants.primary : Colors.white.withValues(alpha: 0.88);

    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => ref
              .read(selectedContentSectionProvider.notifier)
              .select(section),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: selected ? 1.4 : 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppConstants.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(section.icon, color: iconColor, size: 26),
                ),
                const SizedBox(height: 12),
                Text(
                  section.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: labelColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Lazily mounts each section the first time it is selected, then keeps every
/// mounted section alive across selection changes so switching tiles is
/// effectively free.
///
/// - Sections never selected are not in the widget tree.
/// - Sections previously selected stay mounted, wrapped in `Offstage` so they
///   take zero space and don't paint.
/// - `TickerMode(enabled: false)` freezes animations in hidden sections so
///   they don't do background work.
/// - Each section is keyed by its enum so Flutter reuses the exact same
///   `Element` / `RenderObject` subtree across rebuilds — no re-layout of the
///   `MasonryGridView`, no re-bind of `CachedNetworkImage`, no re-decode.
class _SelectedSectionContent extends ConsumerStatefulWidget {
  const _SelectedSectionContent();

  @override
  ConsumerState<_SelectedSectionContent> createState() =>
      _SelectedSectionContentState();
}

class _SelectedSectionContentState
    extends ConsumerState<_SelectedSectionContent> {
  final Set<ContentSection> _mounted = <ContentSection>{};

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(selectedContentSectionProvider);
    _mounted.add(selected);

    return Column(
      children: [
        for (final section in ContentSection.values)
          if (_mounted.contains(section))
            Offstage(
              offstage: section != selected,
              child: TickerMode(
                enabled: section == selected,
                child: KeyedSubtree(
                  key: ValueKey(section),
                  child: _slotFor(section),
                ),
              ),
            ),
      ],
    );
  }

  Widget _slotFor(ContentSection section) => switch (section) {
        ContentSection.dailyInspiration => const _DailyInspirationSlot(),
        ContentSection.practiceCard => const _PracticeCardSlot(),
        ContentSection.islamicEvents => const _IslamicEventsSlot(),
        ContentSection.islamicNews => const _IslamicNewsSlot(),
        ContentSection.scholarlyInsights => const _ScholarlyInsightsSlot(),
      };
}

class _DailyInspirationSlot extends ConsumerWidget {
  const _DailyInspirationSlot();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(dailyInspirationProvider);
    return ContentSectionAsync<DailyInspiration>(
      title: 'Daily Inspiration',
      subtitle: 'Ayah and dua for today',
      icon: ContentSection.dailyInspiration.icon,
      value: value,
      onRetry: () => ref.invalidate(dailyInspirationProvider),
      builder: (context, data) => DailyInspirationSection(inspiration: data),
    );
  }
}

class _PracticeCardSlot extends ConsumerWidget {
  const _PracticeCardSlot();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(practiceCardProvider);
    return ContentSectionAsync<PracticeCard>(
      title: 'Practice Card',
      subtitle: "Today's recommended practice",
      icon: ContentSection.practiceCard.icon,
      value: value,
      onRetry: () => ref.invalidate(practiceCardProvider),
      builder: (context, data) => PracticeCardSection(card: data),
    );
  }
}

class _IslamicEventsSlot extends ConsumerWidget {
  const _IslamicEventsSlot();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(islamicEventsProvider);
    return ContentSectionAsync<IslamicEventsResponse>(
      title: 'Islamic Events',
      subtitle: 'Upcoming events',
      icon: ContentSection.islamicEvents.icon,
      value: value,
      onRetry: () => ref.invalidate(islamicEventsProvider),
      builder: (context, data) => IslamicEventsSection(events: data),
    );
  }
}

class _IslamicNewsSlot extends ConsumerWidget {
  const _IslamicNewsSlot();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(islamicNewsProvider);
    return ContentSectionAsync<IslamicNewsResponse>(
      title: 'Islamic News',
      subtitle: 'Latest articles',
      icon: ContentSection.islamicNews.icon,
      value: value,
      onRetry: () => ref.invalidate(islamicNewsProvider),
      builder: (context, data) => IslamicNewsSection(news: data),
    );
  }
}

class _ScholarlyInsightsSlot extends ConsumerWidget {
  const _ScholarlyInsightsSlot();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(scholarlyInsightsProvider);
    return ContentSectionAsync<ScholarlyInsightsResponse>(
      title: 'Scholarly Insights',
      subtitle: 'Curated insights and lectures',
      icon: ContentSection.scholarlyInsights.icon,
      value: value,
      onRetry: () => ref.invalidate(scholarlyInsightsProvider),
      builder: (context, data) => ScholarlyInsightsSection(insights: data),
    );
  }
}

int _tileGridColumns(double width) {
  if (width >= 1200) return 5;
  if (width >= 900) return 4;
  if (width >= 600) return 3;
  if (width >= 380) return 2;
  return 1;
}
