import 'package:emam_admin_web_app/core/constants/api_constants.dart';
import 'package:emam_admin_web_app/core/network/dio_client.dart';
import 'package:emam_admin_web_app/features/content_reports/models/content_report.dart';

class ContentReportsRepository {
  ContentReportsRepository(this._client);

  final DioClient _client;

  Future<ContentReportsResponse> fetch({
    String? pageToken,
    int limit = 50,
    String? status,
    String? contentType,
    String? query,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.contentReports,
      queryParameters: {
        'limit': limit,
        if (pageToken != null && pageToken.isNotEmpty) 'page_token': pageToken,
        'status': ?status,
        'content_type': ?contentType,
        if (query != null && query.isNotEmpty) 'q': query,
      },
    );
    return ContentReportsResponse.fromJson(response.data ?? const {});
  }

  Future<ContentReport> update(
    String id, {
    String? status,
    String? editorNote,
    String? duplicateOfReportId,
  }) async {
    final response = await _client.patch<Map<String, dynamic>>(
      ApiConstants.contentReport(id),
      data: {
        'status': ?status,
        'editor_note': ?editorNote,
        'duplicate_of_report_id': ?duplicateOfReportId,
      },
    );
    return ContentReport.fromJson(response.data ?? const {});
  }
}
