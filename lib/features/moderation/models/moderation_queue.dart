import 'package:emam_admin_web_app/features/moderation/models/hidden_post.dart';
import 'package:emam_admin_web_app/features/moderation/models/moderation_report.dart';

DateTime? _parseDate(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value);
}

/// One row of `GET /admin/moderation/queue`: either a hidden post or an open
/// report (with its post embedded).
class QueueItem {
  const QueueItem({
    required this.kind,
    required this.priority,
    required this.post,
    required this.report,
    required this.createdAt,
  });

  static const hiddenPostKind = 'hidden_post';

  final String kind;
  final int priority;
  final HiddenPost post;

  /// Set for report items, null for hidden posts.
  final ModerationReport? report;
  final DateTime? createdAt;

  bool get isHiddenPost => kind == hiddenPostKind;

  String get postId => post.id;

  factory QueueItem.fromJson(Map<String, dynamic> json) {
    final kind = json['kind'] as String? ?? '';
    final isHidden = kind == hiddenPostKind;
    final rawReport = json['report'];
    final report = isHidden
        ? null
        : ModerationReport.fromJson(
            rawReport is Map<String, dynamic> ? rawReport : json,
          );
    final rawPost = json['post'];
    final postJson = rawPost is Map<String, dynamic>
        ? rawPost
        : <String, dynamic>{'id': json['post_id']};
    return QueueItem(
      kind: kind,
      priority: (json['priority'] as num?)?.toInt() ?? 0,
      post: HiddenPost.fromJson(postJson),
      report: report,
      createdAt: _parseDate(json['created_at']),
    );
  }
}

class ModerationQueue {
  const ModerationQueue({required this.items, required this.count});

  final List<QueueItem> items;
  final int count;

  factory ModerationQueue.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(QueueItem.fromJson)
        .toList();
    return ModerationQueue(
      items: items,
      count: (json['count'] as num?)?.toInt() ?? items.length,
    );
  }
}

/// `GET /admin/moderation/posts/{post_id}`.
class PostDetail {
  const PostDetail({
    required this.post,
    required this.reports,
    required this.openReportCount,
  });

  final HiddenPost post;
  final List<ModerationReport> reports;
  final int openReportCount;

  bool get isHidden => post.status.toLowerCase() == 'hidden';

  factory PostDetail.fromJson(Map<String, dynamic> json) {
    final rawPost = json['post'];
    return PostDetail(
      post: HiddenPost.fromJson(
        rawPost is Map<String, dynamic> ? rawPost : const {},
      ),
      reports: (json['reports'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ModerationReport.fromJson)
          .toList(),
      openReportCount: (json['open_report_count'] as num?)?.toInt() ?? 0,
    );
  }
}
