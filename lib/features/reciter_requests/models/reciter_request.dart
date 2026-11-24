const List<String> kReciterStatuses = [
  'new',
  'planned',
  'added',
  'not_possible',
];

String reciterStatusLabel(String status) => switch (status) {
  'new' => 'New',
  'planned' => 'Planned',
  'added' => 'Added',
  'not_possible' => 'Not possible',
  _ => status,
};

class ReciterRequestEvent {
  const ReciterRequestEvent({
    required this.lang,
    required this.platform,
    required this.appVersion,
    required this.createdAt,
  });

  final String lang;
  final String? platform;
  final String? appVersion;
  final DateTime? createdAt;

  factory ReciterRequestEvent.fromJson(Map<String, dynamic> json) {
    String? opt(String k) {
      final v = json[k];
      return v is String && v.isNotEmpty ? v : null;
    }

    return ReciterRequestEvent(
      lang: json['lang'] as String? ?? '',
      platform: opt('platform'),
      appVersion: opt('app_version'),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }
}

class ReciterRequest {
  const ReciterRequest({
    required this.id,
    required this.displayName,
    required this.requestCount,
    required this.langCounts,
    required this.status,
    required this.editorNote,
    required this.lastRequestedAt,
    required this.createdAt,
    required this.recentEvents,
  });

  final String id;
  final String displayName;
  final int requestCount;
  final Map<String, int> langCounts;
  final String status;
  final String? editorNote;
  final DateTime? lastRequestedAt;
  final DateTime? createdAt;
  final List<ReciterRequestEvent> recentEvents;

  factory ReciterRequest.fromJson(Map<String, dynamic> json) {
    final note = json['editor_note'];
    final counts = json['lang_counts'];
    final events = json['recent_events'];
    return ReciterRequest(
      id: json['request_id'] as String? ?? '',
      displayName:
          json['display_name'] as String? ??
          json['normalized_name'] as String? ??
          '',
      requestCount: (json['request_count'] as num?)?.toInt() ?? 0,
      langCounts: counts is Map
          ? {
              for (final e in counts.entries)
                e.key.toString(): (e.value as num?)?.toInt() ?? 0,
            }
          : const {},
      status: json['status'] as String? ?? 'new',
      editorNote: note is String && note.isNotEmpty ? note : null,
      lastRequestedAt: DateTime.tryParse(
        json['last_requested_at'] as String? ?? '',
      ),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      recentEvents: events is List
          ? events
                .whereType<Map<String, dynamic>>()
                .map(ReciterRequestEvent.fromJson)
                .toList()
          : const [],
    );
  }
}

class ReciterRequestsResponse {
  const ReciterRequestsResponse({
    required this.items,
    required this.nextPageToken,
    required this.newCount,
  });

  final List<ReciterRequest> items;
  final String? nextPageToken;
  final int? newCount;

  factory ReciterRequestsResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['items'] as List<dynamic>? ?? const [];
    final meta = json['meta'];
    return ReciterRequestsResponse(
      items: raw
          .whereType<Map<String, dynamic>>()
          .map(ReciterRequest.fromJson)
          .toList(),
      nextPageToken: json['next_page_token'] as String?,
      newCount: meta is Map<String, dynamic>
          ? (meta['new_count'] as num?)?.toInt()
          : null,
    );
  }
}
