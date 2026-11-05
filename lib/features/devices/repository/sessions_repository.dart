import 'package:emam_admin_web_app/core/constants/api_constants.dart';
import 'package:emam_admin_web_app/core/network/dio_client.dart';
import 'package:emam_admin_web_app/features/devices/models/signed_in_session.dart';

class SessionsRepository {
  SessionsRepository(this._client);

  final DioClient _client;

  Future<SignedInSessions> fetchSessions() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.authSessionsAll,
    );
    return SignedInSessions.fromJson(response.data ?? const {});
  }

  /// [adminUserId] targets another admin's row (from the `/all` listing).
  Future<void> revokeSession(String sessionId, {String? adminUserId}) async {
    await _client.delete<Object>(
      ApiConstants.authSession(sessionId),
      queryParameters: {'admin_user_id': ?adminUserId},
    );
  }
}
