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
    required this.postStatus,
    required this.postHidden,
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
  final String postStatus;
  final bool postHidden;
  final String? resolutionAction;
  final String? resolutionNote;
  final String? resolvedBy;
  final DateTime? resolvedAt;
  final DateTime? createdAt;

  bool get isOpen => status.toLowerCase() == 'open';

  bool get isPostHidden {
    if (postHidden) return true;
    if (postStatus.toLowerCase() == 'hidden') return true;
    final action = (resolutionAction ?? '').trim().toLowerCase();
    if (action == 'hide' || action == 'hidden') return true;
    return false;
  }

  factory ModerationReport.fromJson(Map<String, dynamic> json) {
    final postJson = _readPostMap(json);
    var postStatus = _readString(json, const [
      'post_status',
      'postStatus',
      'dua_post_status',
      'duaPostStatus',
    ]) ?? '';
    var postHidden = _readBool(json, const [
      'is_post_hidden',
      'post_hidden',
      'is_hidden',
      'hidden',
      'isPostHidden',
      'postHidden',
    ]);

    if (postJson != null) {
      postStatus = _firstNonEmpty([
        postStatus,
        _readString(postJson, const ['status', 'post_status', 'postStatus']),
        _readString(postJson, const ['visibility', 'post_visibility']),
      ]);
      postHidden = postHidden ||
          _readBool(postJson, const ['hidden', 'is_hidden', 'isHidden']) ||
          _hasHiddenTimestamp(postJson);
      if (postStatus.toLowerCase() == 'hidden') postHidden = true;
    }

    postHidden = postHidden ||
        _hasHiddenTimestamp(json) ||
        _statusImpliesHidden(postStatus) ||
        _statusImpliesHidden(_readString(json, const [
              'visibility',
              'post_visibility',
            ]) ??
            '');

    final resolutionAction = json['resolution_action'] as String? ??
        json['resolutionAction'] as String?;
    final action = (resolutionAction ?? '').trim().toLowerCase();
    if (action == 'hide' || action == 'hidden' || action == 'post_hidden') {
      postHidden = true;
    }

    return ModerationReport(
      id: json['id'] as String? ?? '',
      postId: _readPostId(json, postJson),
      postAuthorUserId: _readString(json, const [
            'post_author_user_id',
            'postAuthorUserId',
          ]) ??
          _readString(postJson ?? const {}, const ['user_id', 'userId']) ??
          '',
      reporterUserId: _readString(json, const [
            'reporter_user_id',
            'reporterUserId',
          ]) ??
          '',
      reason: json['reason'] as String? ?? '',
      details: json['details'] as String? ?? '',
      status: json['status'] as String? ?? '',
      postStatus: postStatus,
      postHidden: postHidden,
      resolutionAction: resolutionAction,
      resolutionNote: json['resolution_note'] as String? ??
          json['resolutionNote'] as String?,
      resolvedBy:
          json['resolved_by'] as String? ?? json['resolvedBy'] as String?,
      resolvedAt: _parseDate(json['resolved_at'] ?? json['resolvedAt']),
      createdAt: _parseDate(json['created_at'] ?? json['createdAt']),
    );
  }

  static Map<String, dynamic>? _readPostMap(Map<String, dynamic> json) {
    final post = json['post'] ?? json['dua_post'] ?? json['duaPost'];
    return post is Map<String, dynamic> ? post : null;
  }

  static String _readPostId(
    Map<String, dynamic> json,
    Map<String, dynamic>? postJson,
  ) {
    return _firstNonEmpty([
      _readString(json, const ['post_id', 'postId', 'dua_post_id', 'duaPostId']),
      if (postJson != null)
        _readString(postJson, const ['id', 'post_id', 'postId']),
    ]);
  }

  static String? _readString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }

  static bool _readBool(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value == true) return true;
    }
    return false;
  }

  static bool _hasHiddenTimestamp(Map<String, dynamic> json) {
    for (final key in const [
      'hidden_at',
      'hiddenAt',
      'post_hidden_at',
      'postHiddenAt',
    ]) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) return true;
      if (value != null && value is! String) return true;
    }
    return false;
  }

  static bool _statusImpliesHidden(String status) {
    final normalized = status.trim().toLowerCase();
    return normalized == 'hidden' ||
        normalized == 'moderation_hidden' ||
        normalized == 'post_hidden';
  }

  static String _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) return value.trim();
    }
    return '';
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
