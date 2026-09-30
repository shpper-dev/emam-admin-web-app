class AuditEntry {
  const AuditEntry({
    required this.id,
    required this.adminUserId,
    required this.action,
    required this.targetType,
    required this.targetId,
    required this.metadata,
    required this.createdAt,
  });

  final String id;
  final String adminUserId;
  final String action;
  final String targetType;
  final String targetId;
  final Map<String, dynamic> metadata;
  final DateTime? createdAt;

  factory AuditEntry.fromJson(Map<String, dynamic> json) {
    return AuditEntry(
      id: json['id'] as String? ?? '',
      adminUserId: json['admin_user_id'] as String? ?? '',
      action: json['action'] as String? ?? '',
      targetType: json['target_type'] as String? ?? '',
      targetId: json['target_id'] as String? ?? '',
      metadata: json['metadata'] is Map<String, dynamic>
          ? json['metadata'] as Map<String, dynamic>
          : const {},
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }
}

class AuditResponse {
  const AuditResponse({
    required this.entries,
    required this.nextPageToken,
    required this.count,
  });

  final List<AuditEntry> entries;
  final String? nextPageToken;
  final int count;

  /// [pageSize] is used to infer a cursor when the backend omits
  /// `next_page_token`: a full page is assumed to have more, and the last
  /// entry id is used as the cursor.
  factory AuditResponse.fromJson(Map<String, dynamic> json, {int? pageSize}) {
    final raw = json['entries'] as List<dynamic>? ?? const [];
    final entries = raw
        .whereType<Map<String, dynamic>>()
        .map(AuditEntry.fromJson)
        .toList();
    var token = json['next_page_token'] as String?;
    if ((token ?? '').isEmpty &&
        !json.containsKey('next_page_token') &&
        pageSize != null &&
        entries.length >= pageSize) {
      token = entries.last.id;
    }
    return AuditResponse(
      entries: entries,
      nextPageToken: token,
      count: json['count'] as int? ?? entries.length,
    );
  }
}
