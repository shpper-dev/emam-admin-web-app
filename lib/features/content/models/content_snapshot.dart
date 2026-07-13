import 'package:emam_admin_web_app/features/content/models/daily_inspiration.dart';
import 'package:emam_admin_web_app/features/content/models/islamic_event.dart';
import 'package:emam_admin_web_app/features/content/models/islamic_news_item.dart';
import 'package:emam_admin_web_app/features/content/models/practice_card.dart';
import 'package:emam_admin_web_app/features/content/models/scholarly_insight.dart';

class ContentSnapshot {
  const ContentSnapshot({
    required this.islamicNews,
    required this.islamicEvents,
    required this.practiceCard,
    required this.scholarlyInsights,
    required this.dailyInspiration,
  });

  final IslamicNewsResponse islamicNews;
  final IslamicEventsResponse islamicEvents;
  final PracticeCard practiceCard;
  final ScholarlyInsightsResponse scholarlyInsights;
  final DailyInspiration dailyInspiration;
}
