import 'package:emam_admin_web_app/core/constants/api_constants.dart';
import 'package:emam_admin_web_app/core/network/dio_client.dart';
import 'package:emam_admin_web_app/features/audit/models/audit_entry.dart';

class AuditRepository {
  AuditRepository(this._client);

  final DioClient _client;

  Future<AuditResponse> fetchAudit({
    String? pageToken,
    int limit = 50,
    String? action,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.auditLog,
      queryParameters: {
        'limit': limit,
        if (pageToken != null && pageToken.isNotEmpty) 'page_token': pageToken,
        if (action != null && action.isNotEmpty) 'action': action,
      },
    );
    return AuditResponse.fromJson(response.data ?? const {}, pageSize: limit);
  }
}
