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

  /// Loads every hidden post id (paginates until no next token).
  Future<Set<String>> fetchAllHiddenPostIds({int limit = 50}) async {
    final ids = <String>{};
    String? pageToken;

    do {
      final page = await fetchHiddenPosts(pageToken: pageToken, limit: limit);
      for (final post in page.posts) {
        final id = post.id.trim();
        if (id.isNotEmpty) ids.add(id);
      }
      pageToken = page.nextPageToken?.trim();
      if (pageToken != null && pageToken.isEmpty) pageToken = null;
    } while (pageToken != null);

    return ids;
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

  Future<void> restoreDuaPost(String postId) async {
    await _client.post<void>(ApiConstants.restoreDuaPost(postId));
  }
}
