import 'package:emam_admin_web_app/core/constants/api_constants.dart';
import 'package:emam_admin_web_app/core/network/dio_client.dart';
import 'package:emam_admin_web_app/features/users/models/app_user.dart';
import 'package:emam_admin_web_app/features/users/models/restricted_user.dart';

class UsersRepository {
  UsersRepository(this._client);

  final DioClient _client;

  Future<UsersResponse> fetchUsers({
    String? pageToken,
    int limit = 50,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.users,
      queryParameters: {
        'limit': limit,
        if (pageToken != null && pageToken.isNotEmpty) 'page_token': pageToken,
      },
    );
    return UsersResponse.fromJson(response.data ?? const {});
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
    return RestrictedUsersResponse.fromJson(response.data ?? const {});
  }
}
