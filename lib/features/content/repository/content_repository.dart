import 'package:emam_admin_web_app/core/constants/api_constants.dart';
import 'package:emam_admin_web_app/core/network/dio_client.dart';
import 'package:emam_admin_web_app/features/content/models/content_snapshot.dart';
import 'package:emam_admin_web_app/features/content/models/daily_inspiration.dart';
import 'package:emam_admin_web_app/features/content/models/islamic_event.dart';
import 'package:emam_admin_web_app/features/content/models/islamic_news_item.dart';
import 'package:emam_admin_web_app/features/content/models/practice_card.dart';
import 'package:emam_admin_web_app/features/content/models/scholarly_insight.dart';

class ContentRepository {
  ContentRepository(this._client);

  final DioClient _client;

  Future<ContentSnapshot> fetchAll() async {
    final results = await Future.wait([
      _fetchIslamicNews(),
      _fetchIslamicEvents(),
      _fetchPracticeCard(),
      _fetchScholarlyInsights(),
      _fetchDailyInspiration(),
    ]);

    return ContentSnapshot(
      islamicNews: results[0] as IslamicNewsResponse,
      islamicEvents: results[1] as IslamicEventsResponse,
      practiceCard: results[2] as PracticeCard,
      scholarlyInsights: results[3] as ScholarlyInsightsResponse,
      dailyInspiration: results[4] as DailyInspiration,
    );
  }

  Future<IslamicNewsResponse> _fetchIslamicNews() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.islamicNews,
    );
    return IslamicNewsResponse.fromJson(response.data ?? {});
  }

  Future<IslamicEventsResponse> _fetchIslamicEvents() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.islamicEvents,
    );
    return IslamicEventsResponse.fromJson(response.data ?? {});
  }

  Future<PracticeCard> _fetchPracticeCard() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.practiceCard,
    );
    return PracticeCard.fromJson(response.data ?? {});
  }

  Future<ScholarlyInsightsResponse> _fetchScholarlyInsights() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.scholarlyInsights,
    );
    return ScholarlyInsightsResponse.fromJson(response.data ?? {});
  }

  Future<DailyInspiration> _fetchDailyInspiration() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.dailyInspiration,
    );
    return DailyInspiration.fromJson(response.data ?? {});
  }
}
