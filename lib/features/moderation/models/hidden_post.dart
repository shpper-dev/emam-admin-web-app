DateTime? _parseDate(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value);
}

class HiddenPost {
  const HiddenPost({
    required this.id,
    required this.userId,
    required this.userDisplayName,
    required this.location,
    required this.content,
    required this.ameenCount,
    required this.reportCount,
    required this.status,
    required this.hiddenReason,
    required this.hiddenBy,
    required this.hiddenAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String userDisplayName;
  final String location;
  final String content;
  final int ameenCount;
  final int reportCount;
  final String status;
  final String hiddenReason;
  final String hiddenBy;
  final DateTime? hiddenAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory HiddenPost.fromJson(Map<String, dynamic> json) {
    return HiddenPost(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      userDisplayName: json['user_display_name'] as String? ?? '',
      location: json['location'] as String? ?? '',
      content: json['content'] as String? ?? '',
      ameenCount: json['ameen_count'] as int? ?? 0,
      reportCount: json['report_count'] as int? ?? 0,
      status: json['status'] as String? ?? '',
      hiddenReason: json['hidden_reason'] as String? ?? '',
      hiddenBy: json['hidden_by'] as String? ?? '',
      hiddenAt: _parseDate(json['hidden_at']),
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }
}

class HiddenPostsResponse {
  const HiddenPostsResponse({
    required this.posts,
    required this.nextPageToken,
  });

  final List<HiddenPost> posts;
  final String? nextPageToken;

  factory HiddenPostsResponse.fromJson(Map<String, dynamic> json) {
    final rawPosts = json['posts'] as List<dynamic>? ?? const [];
    return HiddenPostsResponse(
      posts: rawPosts
          .whereType<Map<String, dynamic>>()
          .map(HiddenPost.fromJson)
          .toList(),
      nextPageToken: json['next_page_token'] as String?,
    );
  }
}
