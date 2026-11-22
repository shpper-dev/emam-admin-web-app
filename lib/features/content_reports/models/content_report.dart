const List<String> kReportStatuses = [
  'new',
  'in_review',
  'fixed',
  'rejected',
  'duplicate',
];

const Map<String, String> kReportContentTypes = {
  'quran_ayah': 'Ayah',
  'quran_translation': 'Translation',
  'tafsir': 'Tafsir',
  'hadith': 'Hadith',
  'dua': 'Dua',
  'lesson': 'Lesson',
};

String reportStatusLabel(String status) => switch (status) {
  'new' => 'New',
  'in_review' => 'In review',
  'fixed' => 'Fixed',
  'rejected' => 'Rejected',
  'duplicate' => 'Duplicate',
  _ => status,
};

String reportTypeLabel(String type) => kReportContentTypes[type] ?? type;

class ContentReport {
  const ContentReport({
    required this.id,
    required this.contentType,
    required this.contentId,
    required this.readableReference,
    required this.editionId,
    required this.lang,
    required this.originalText,
    required this.userNote,
    required this.status,
    required this.appVersion,
    required this.platform,
    required this.userId,
    required this.deviceId,
    required this.editorNote,
    required this.closedBy,
    required this.closedAt,
    required this.duplicateOfReportId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String contentType;
  final String contentId;
  final String readableReference;
  final String? editionId;
  final String lang;
  final String originalText;
  final String userNote;
  final String status;
  final String? appVersion;
  final String? platform;
  final String? userId;
  final String? deviceId;
  final String? editorNote;
  final String? closedBy;
  final DateTime? closedAt;
  final String? duplicateOfReportId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isClosed =>
      status == 'fixed' || status == 'rejected' || status == 'duplicate';

  factory ContentReport.fromJson(Map<String, dynamic> json) {
    String? opt(String k) {
      final v = json[k];
      return v is String && v.isNotEmpty ? v : null;
    }

    return ContentReport(
      id: json['id'] as String? ?? '',
      contentType: json['content_type'] as String? ?? '',
      contentId: json['content_id'] as String? ?? '',
      readableReference: json['readable_reference'] as String? ?? '',
      editionId: opt('edition_id'),
      lang: json['lang'] as String? ?? '',
      originalText: json['original_text'] as String? ?? '',
      userNote: json['user_note'] as String? ?? '',
      status: json['status'] as String? ?? 'new',
      appVersion: opt('app_version'),
      platform: opt('platform'),
      userId: opt('user_id'),
      deviceId: opt('device_id'),
      editorNote: opt('editor_note'),
      closedBy: opt('closed_by'),
      closedAt: DateTime.tryParse(json['closed_at'] as String? ?? ''),
      duplicateOfReportId: opt('duplicate_of_report_id'),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? ''),
    );
  }
}

class ContentReportsResponse {
  const ContentReportsResponse({
    required this.reports,
    required this.nextPageToken,
    required this.newCount,
  });

  final List<ContentReport> reports;
  final String? nextPageToken;
  final int? newCount;

  factory ContentReportsResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['reports'] as List<dynamic>? ?? const [];
    final meta = json['meta'];
    return ContentReportsResponse(
      reports: raw
          .whereType<Map<String, dynamic>>()
          .map(ContentReport.fromJson)
          .toList(),
      nextPageToken: json['next_page_token'] as String?,
      newCount: meta is Map<String, dynamic> ? meta['new_count'] as int? : null,
    );
  }
}
