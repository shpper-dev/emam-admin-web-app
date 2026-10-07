import 'package:emam_admin_web_app/features/moderation/models/moderation_queue.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('queue parses hidden_post items', () {
    final queue = ModerationQueue.fromJson({
      'items': [
        {
          'kind': 'hidden_post',
          'priority': 201,
          'post': {
            'id': 'p1',
            'user_display_name': 'A',
            'content': 'Pray',
            'ameen_count': 3,
            'report_count': 1,
            'status': 'hidden',
            'hidden_reason': 'Reported.',
            'hidden_at': '2026-09-30T10:17:05.093000Z',
          },
          'post_id': 'p1',
          'created_at': '2026-09-30T10:17:05.093000Z',
        },
      ],
      'count': 1,
    });
    final item = queue.items.single;
    expect(queue.count, 1);
    expect(item.isHiddenPost, isTrue);
    expect(item.report, isNull);
    expect(item.postId, 'p1');
    expect(item.priority, 201);
    expect(item.post.hiddenReason, 'Reported.');
  });

  test('queue parses report items with embedded post', () {
    final item = QueueItem.fromJson({
      'kind': 'report',
      'priority': 100,
      'id': 'r1',
      'post_id': 'p2',
      'reason': 'spam',
      'status': 'open',
      'post': {'id': 'p2', 'content': 'x', 'status': 'active'},
    });
    expect(item.isHiddenPost, isFalse);
    expect(item.report?.reason, 'spam');
    expect(item.postId, 'p2');
  });

  test('post detail tolerates null hidden fields', () {
    final d = PostDetail.fromJson({
      'post': {
        'id': 'p3',
        'status': 'active',
        'hidden_reason': null,
        'hidden_by': null,
        'hidden_at': null,
      },
      'reports': [
        {'id': 'r', 'post_id': 'p3', 'status': 'resolved', 'reason': 'spam'},
      ],
      'open_report_count': 0,
    });
    expect(d.isHidden, isFalse);
    expect(d.reports.single.isOpen, isFalse);
    expect(d.openReportCount, 0);
  });
}
