import 'package:emam_admin_web_app/core/constants/api_constants.dart';
import 'package:emam_admin_web_app/core/network/dio_client.dart';
import 'package:emam_admin_web_app/features/moderation/models/hidden_post.dart';
import 'package:emam_admin_web_app/features/moderation/models/moderation_queue.dart';
import 'package:emam_admin_web_app/features/moderation/models/moderation_report.dart';

class ModerationRepository {
  ModerationRepository(this._client);

  final DioClient _client;

  Future<ModerationReportsResponse> fetchReports({
    String status = 'open',
    String? pageToken,
    int limit = 50,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.moderationReports,
      queryParameters: {
        'status': status,
        'limit': limit,
        if (pageToken != null && pageToken.isNotEmpty) 'page_token': pageToken,
      },
    );
    return ModerationReportsResponse.fromJson(response.data ?? const {});
  }

  /// Open reports and hidden posts merged by urgency (`limit` 1-100).
  Future<ModerationQueue> fetchQueue({int limit = 30}) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.moderationQueue,
      queryParameters: {'limit': limit},
    );
    return ModerationQueue.fromJson(response.data ?? const {});
  }

  Future<PostDetail> fetchPostDetail(String postId) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.moderationPost(postId),
    );
    return PostDetail.fromJson(response.data ?? const {});
  }

  /// [action] is `dismiss` or `action_taken`.
  Future<void> resolveReport(String reportId, {required String action}) async {
    await _client.post<void>(
      ApiConstants.resolveReport(reportId),
      data: {'action': action},
    );
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
  Future<Set<String>> fetchAllHiddenPostIds({
    int limit = 50,
    int maxPages = 200,
  }) async {
    final ids = <String>{};
    final seenTokens = <String>{};
    String? pageToken;

    // Stops on a repeated token or the page cap so a misbehaving backend
    // cursor can never loop forever (and keep the screen loading).
    for (var i = 0; i < maxPages; i++) {
      final page = await fetchHiddenPosts(pageToken: pageToken, limit: limit);
      for (final post in page.posts) {
        final id = post.id.trim();
        if (id.isNotEmpty) ids.add(id);
      }
      pageToken = page.nextPageToken?.trim();
      if (pageToken == null || pageToken.isEmpty) break;
      if (!seenTokens.add(pageToken)) break;
    }

    return ids;
  }

  Future<void> hideDuaPost(String postId, {required String reason}) async {
    await _client.post<void>(
      ApiConstants.hideDuaPost(postId),
      data: {'reason': reason},
    );
  }

  Future<void> restoreDuaPost(String postId) async {
    await _client.post<void>(ApiConstants.restoreDuaPost(postId));
  }
}
