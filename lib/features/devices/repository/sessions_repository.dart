import 'package:emam_admin_web_app/core/constants/api_constants.dart';
import 'package:emam_admin_web_app/core/network/dio_client.dart';
import 'package:emam_admin_web_app/features/devices/models/signed_in_session.dart';

class SessionsRepository {
  SessionsRepository(this._client);

  final DioClient _client;

  Future<SignedInSessions> fetchSessions() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.authSessions,
    );
    return SignedInSessions.fromJson(response.data ?? const {});
  }

  Future<void> revokeSession(String sessionId) async {
    await _client.delete<Object>(ApiConstants.authSession(sessionId));
  }

  /// Returns how many other sessions were signed out.
  Future<int> revokeOthers() async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.authSessionsRevokeOthers,
    );
    final data = response.data?['data'];
    final count = data is Map ? data['revoked_count'] : null;
    return count is int ? count : 0;
  }
}
