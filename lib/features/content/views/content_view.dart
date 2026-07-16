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
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ContentView extends ConsumerWidget {
  const ContentView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = contentHorizontalPadding(constraints.maxWidth);

        return RefreshIndicator(
          color: AppConstants.primary,
          backgroundColor: AppConstants.surfaceColor,
          onRefresh: () => refreshAllContent(ref),
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
                Text(
                  'Content Overview',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppConstants.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Live preview of all published content served to the Emam app.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 28),
                const _DailyInspirationSlot(),
                const SizedBox(height: 24),
                const _PracticeCardSlot(),
                const SizedBox(height: 24),
                const _IslamicEventsSlot(),
                const SizedBox(height: 24),
                const _IslamicNewsSlot(),
                const SizedBox(height: 24),
                const _ScholarlyInsightsSlot(),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DailyInspirationSlot extends ConsumerWidget {
  const _DailyInspirationSlot();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(dailyInspirationProvider);
    return ContentSectionAsync<DailyInspiration>(
      title: 'Daily Inspiration',
      subtitle: 'Ayah and dua for today',
      icon: Icons.auto_awesome_rounded,
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
      icon: Icons.menu_book_rounded,
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
      icon: Icons.event_rounded,
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
      icon: Icons.newspaper_rounded,
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
      icon: CupertinoIcons.book_fill,
      value: value,
      onRetry: () => ref.invalidate(scholarlyInsightsProvider),
      builder: (context, data) => ScholarlyInsightsSection(insights: data),
    );
  }
}
