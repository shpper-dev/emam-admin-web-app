import 'package:emam_admin_web_app/core/constants/api_constants.dart';
import 'package:emam_admin_web_app/core/network/dio_client.dart';
import 'package:emam_admin_web_app/features/moderation/models/hidden_post.dart';
import 'package:emam_admin_web_app/features/moderation/models/moderation_report.dart';

class ModerationRepository {
  ModerationRepository(this._client);

  final DioClient _client;

  Future<ModerationReportsResponse> fetchReports() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.moderationReports,
    );
    return ModerationReportsResponse.fromJson(response.data ?? const {});
  }

  Future<HiddenPostsResponse> fetchHiddenPosts({
    String? pageToken,
    int limit = 50,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.hiddenPosts,
      queryParameters: {
        'limit': limit,
        if (pageToken != null && pageToken.isNotEmpty) 'page_token': pageToken,
      },
    );
    return HiddenPostsResponse.fromJson(response.data ?? const {});
  }

  Future<void> hideDuaPost(
    String postId, {
    required String reason,
  }) async {
    await _client.post<void>(
      ApiConstants.hideDuaPost(postId),
      data: {'reason': reason},
    );
  }
}
