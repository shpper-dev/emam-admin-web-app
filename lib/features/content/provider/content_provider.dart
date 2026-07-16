import 'package:emam_admin_web_app/features/content/models/daily_inspiration.dart';
import 'package:emam_admin_web_app/features/content/models/islamic_event.dart';
import 'package:emam_admin_web_app/features/content/models/islamic_news_item.dart';
import 'package:emam_admin_web_app/features/content/models/practice_card.dart';
import 'package:emam_admin_web_app/features/content/models/scholarly_insight.dart';
import 'package:emam_admin_web_app/features/content/provider/content_repository_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ContentSection {
  dailyInspiration('Daily Inspiration', Icons.auto_awesome_rounded),
  practiceCard('Practice Card', Icons.menu_book_rounded),
  islamicEvents('Islamic Events', Icons.event_rounded),
  islamicNews('Islamic News', Icons.newspaper_rounded),
  scholarlyInsights('Scholarly Insights', CupertinoIcons.book_fill);

  const ContentSection(this.label, this.icon);

  final String label;
  final IconData icon;
}

final selectedContentSectionProvider =
    NotifierProvider<SelectedContentSectionNotifier, ContentSection>(
  SelectedContentSectionNotifier.new,
);

class SelectedContentSectionNotifier extends Notifier<ContentSection> {
  @override
  ContentSection build() => ContentSection.dailyInspiration;

  void select(ContentSection section) => state = section;
}

final dailyInspirationProvider = FutureProvider<DailyInspiration>((ref) {
  return ref.watch(contentRepositoryProvider).fetchDailyInspiration();
});

final practiceCardProvider = FutureProvider<PracticeCard>((ref) {
  return ref.watch(contentRepositoryProvider).fetchPracticeCard();
});

final islamicEventsProvider = FutureProvider<IslamicEventsResponse>((ref) {
  return ref.watch(contentRepositoryProvider).fetchIslamicEvents();
});

final islamicNewsProvider = FutureProvider<IslamicNewsResponse>((ref) {
  return ref.watch(contentRepositoryProvider).fetchIslamicNews();
});

final scholarlyInsightsProvider =
    FutureProvider<ScholarlyInsightsResponse>((ref) {
  return ref.watch(contentRepositoryProvider).fetchScholarlyInsights();
});

Future<void> refreshAllContent(WidgetRef ref) async {
  ref.invalidate(dailyInspirationProvider);
  ref.invalidate(practiceCardProvider);
  ref.invalidate(islamicEventsProvider);
  ref.invalidate(islamicNewsProvider);
  ref.invalidate(scholarlyInsightsProvider);

  await Future.wait([
    ref.read(dailyInspirationProvider.future),
    ref.read(practiceCardProvider.future),
    ref.read(islamicEventsProvider.future),
    ref.read(islamicNewsProvider.future),
    ref.read(scholarlyInsightsProvider.future),
  ]);
}
