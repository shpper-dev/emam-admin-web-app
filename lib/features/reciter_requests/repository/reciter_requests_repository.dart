import 'package:emam_admin_web_app/core/constants/api_constants.dart';
import 'package:emam_admin_web_app/core/network/dio_client.dart';
import 'package:emam_admin_web_app/features/reciter_requests/models/reciter_request.dart';

class ReciterRequestsRepository {
  ReciterRequestsRepository(this._client);

  final DioClient _client;

  Future<ReciterRequestsResponse> fetch({
    String? pageToken,
    int limit = 50,
    String? status,
    String? query,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.reciterRequests,
      queryParameters: {
        'limit': limit,
        if (pageToken != null && pageToken.isNotEmpty) 'page_token': pageToken,
        'status': ?status,
        if (query != null && query.isNotEmpty) 'q': query,
      },
    );
    return ReciterRequestsResponse.fromJson(response.data ?? const {});
  }

  Future<ReciterRequest> detail(String id) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.reciterRequest(id),
    );
    return ReciterRequest.fromJson(response.data ?? const {});
  }

  Future<ReciterRequest> update(
    String id, {
    String? status,
    String? editorNote,
  }) async {
    final response = await _client.patch<Map<String, dynamic>>(
      ApiConstants.reciterRequest(id),
      data: {'status': ?status, 'editor_note': ?editorNote},
    );
    return ReciterRequest.fromJson(response.data ?? const {});
  }
}
