DateTime? _parseDate(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value);
}

class ModerationReport {
  const ModerationReport({
    required this.id,
    required this.postId,
    required this.postAuthorUserId,
    required this.reporterUserId,
    required this.reason,
    required this.details,
    required this.status,
    required this.resolutionAction,
    required this.resolutionNote,
    required this.resolvedBy,
    required this.resolvedAt,
    required this.createdAt,
  });

  final String id;
  final String postId;
  final String postAuthorUserId;
  final String reporterUserId;
  final String reason;
  final String details;
  final String status;
  final String? resolutionAction;
  final String? resolutionNote;
  final String? resolvedBy;
  final DateTime? resolvedAt;
  final DateTime? createdAt;

  bool get isOpen => status.toLowerCase() == 'open';

  factory ModerationReport.fromJson(Map<String, dynamic> json) {
    return ModerationReport(
      id: json['id'] as String? ?? '',
      postId: json['post_id'] as String? ?? '',
      postAuthorUserId: json['post_author_user_id'] as String? ?? '',
      reporterUserId: json['reporter_user_id'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      details: json['details'] as String? ?? '',
      status: json['status'] as String? ?? '',
      resolutionAction: json['resolution_action'] as String?,
      resolutionNote: json['resolution_note'] as String?,
      resolvedBy: json['resolved_by'] as String?,
      resolvedAt: _parseDate(json['resolved_at']),
      createdAt: _parseDate(json['created_at']),
    );
  }
}

class ModerationReportsResponse {
  const ModerationReportsResponse({required this.reports});

  final List<ModerationReport> reports;

  factory ModerationReportsResponse.fromJson(Map<String, dynamic> json) {
    final rawReports = json['reports'] as List<dynamic>? ?? const [];
    return ModerationReportsResponse(
      reports: rawReports
          .whereType<Map<String, dynamic>>()
          .map(ModerationReport.fromJson)
          .toList(),
    );
  }
}
