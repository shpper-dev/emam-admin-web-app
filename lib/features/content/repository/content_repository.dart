import 'package:emam_admin_web_app/core/constants/api_constants.dart';
import 'package:emam_admin_web_app/core/network/dio_client.dart';
import 'package:emam_admin_web_app/features/content/models/daily_inspiration.dart';
import 'package:emam_admin_web_app/features/content/models/islamic_event.dart';
import 'package:emam_admin_web_app/features/content/models/islamic_news_item.dart';
import 'package:emam_admin_web_app/features/content/models/practice_card.dart';
import 'package:emam_admin_web_app/features/content/models/scholarly_insight.dart';

class ContentRepository {
  ContentRepository(this._client);

  final DioClient _client;

  Future<IslamicNewsResponse> fetchIslamicNews() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.islamicNews,
    );
    return IslamicNewsResponse.fromJson(response.data ?? {});
  }

  Future<IslamicEventsResponse> fetchIslamicEvents() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.islamicEvents,
    );
    return IslamicEventsResponse.fromJson(response.data ?? {});
  }

  Future<PracticeCard> fetchPracticeCard() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.practiceCard,
    );
    return PracticeCard.fromJson(response.data ?? {});
  }

  Future<ScholarlyInsightsResponse> fetchScholarlyInsights() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.scholarlyInsights,
    );
    return ScholarlyInsightsResponse.fromJson(response.data ?? {});
  }

  Future<DailyInspiration> fetchDailyInspiration() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.dailyInspiration,
    );
    return DailyInspiration.fromJson(response.data ?? {});
  }
}
