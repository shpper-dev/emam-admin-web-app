import 'package:emam_admin_web_app/core/constants/api_constants.dart';
import 'package:emam_admin_web_app/core/network/dio_client.dart';
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
}
