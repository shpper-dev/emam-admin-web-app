import 'package:emam_admin_web_app/core/constants/api_constants.dart';
import 'package:emam_admin_web_app/core/network/dio_client.dart';
import 'package:emam_admin_web_app/features/moderation/models/moderation_report.dart';
import 'package:emam_admin_web_app/features/users/models/app_user.dart';
import 'package:emam_admin_web_app/features/users/models/restricted_user.dart';
import 'package:emam_admin_web_app/features/users/models/user_detail.dart';
import 'package:emam_admin_web_app/features/users/utils/admin_panel_user.dart';

class UsersRepository {
  UsersRepository(this._client, {this.adminEmail});

  final DioClient _client;

  /// Signed-in admin's email (from `/admin/auth/me`), hidden from user lists.
  final String? adminEmail;

  Future<UsersResponse> fetchUsers({String? pageToken, int limit = 50}) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.users,
      queryParameters: {
        'limit': limit,
        if (pageToken != null && pageToken.isNotEmpty) 'page_token': pageToken,
      },
    );
    return withoutAdminPanelUsers(
      UsersResponse.fromJson(response.data ?? const {}),
      adminEmail,
    );
  }

  Future<UsersResponse> searchUsers({
    required String query,
    int limit = 20,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.usersSearch,
      queryParameters: {'q': query.trim(), 'limit': limit.clamp(1, 50)},
    );
    return withoutAdminPanelUsers(
      UsersResponse.fromJson(response.data ?? const {}),
      adminEmail,
    );
  }

  Future<RestrictedUsersResponse> fetchRestrictedUsers({
    String? pageToken,
    int limit = 50,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.restrictedUsers,
      queryParameters: {
        'limit': limit,
        if (pageToken != null && pageToken.isNotEmpty) 'page_token': pageToken,
      },
    );
    return withoutAdminPanelRestrictedUsers(
      RestrictedUsersResponse.fromJson(response.data ?? const {}),
      adminEmail,
    );
  }

  Future<UserDetailResponse> fetchUserDetail(String userId) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.userDetail(userId),
    );
    return hideAdminPanelUserDetail(
      UserDetailResponse.fromJson(response.data ?? const {}),
      adminEmail,
    );
  }

  Future<UserRecentPostsPage> fetchUserPosts(
    String userId, {
    String? pageToken,
    int limit = kUserDetailPostsPageSize,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.userPosts(userId),
      queryParameters: {
        'limit': limit,
        if (pageToken != null && pageToken.isNotEmpty) 'page_token': pageToken,
      },
    );
    return UserRecentPostsPage.fromJson(response.data ?? const {});
  }

  Future<void> applyUserRestriction(
    String userId, {
    required String reason,
    String duration = '30d',
  }) async {
    await _client.post<void>(
      ApiConstants.userRestriction(userId),
      data: {'duration': duration, 'reason': reason},
    );
  }

  Future<void> unblockUser(String userId) async {
    await _client.post<void>(ApiConstants.userUnblock(userId));
  }

  /// Current restriction; the endpoint answers `{ moderation: {...} }`.
  Future<UserDetailModeration> fetchUserRestriction(String userId) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.userRestriction(userId),
    );
    final data = response.data ?? const {};
    final moderation = data['moderation'];
    return UserDetailModeration.fromJson(
      moderation is Map<String, dynamic> ? moderation : data,
    );
  }

  Future<void> clearUserRestriction(String userId) async {
    await _client.delete<void>(ApiConstants.userRestriction(userId));
  }

  Future<void> resetUserQuota(String userId) async {
    await _client.post<void>(ApiConstants.userQuotaReset(userId));
  }

  Future<List<ModerationReport>> fetchReportsFiled(String userId) =>
      _fetchUserReports(ApiConstants.userReportsFiled(userId));

  Future<List<ModerationReport>> fetchReportsReceived(String userId) =>
      _fetchUserReports(ApiConstants.userReportsReceived(userId));

  Future<List<ModerationReport>> _fetchUserReports(String path) async {
    final response = await _client.get<Map<String, dynamic>>(
      path,
      queryParameters: {'limit': 50},
    );
    return ModerationReportsResponse.fromJson(
      response.data ?? const {},
    ).reports;
  }
}
