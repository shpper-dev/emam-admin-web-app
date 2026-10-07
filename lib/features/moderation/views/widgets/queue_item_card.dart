import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:emam_admin_web_app/core/widgets/status_badge.dart';
import 'package:emam_admin_web_app/features/moderation/models/moderation_queue.dart';
import 'package:emam_admin_web_app/features/moderation/views/widgets/hidden_post_card.dart';
import 'package:emam_admin_web_app/features/moderation/views/widgets/post_detail_dialog.dart';
import 'package:emam_admin_web_app/features/moderation/views/widgets/reported_dua_card.dart';
import 'package:flutter/material.dart';

/// A moderation-queue row: a rank + kind header, then the same card (and
/// actions) used in the Reports / Hidden views, plus a link to post detail.
class QueueItemCard extends StatelessWidget {
  const QueueItemCard({super.key, required this.item, required this.rank});

  final QueueItem item;

  /// 1-based position in the server's urgency order.
  final int rank;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final report = item.report;
    final color = item.isHiddenPost
        ? AppConstants.danger
        : AppConstants.warning;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              Text(
                '#$rank',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppConstants.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 10),
              StatusBadge(
                label: item.isHiddenPost
                    ? 'Hidden · review or restore'
                    : 'Open report · needs a decision',
                color: color,
              ),
            ],
          ),
        ),
        if (report != null)
          ReportedDuaCard(report: report)
        else
          HiddenPostCard(post: item.post),
        if (item.postId.isNotEmpty)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () =>
                  showPostDetailDialog(context, postId: item.postId),
              icon: const Icon(Icons.article_rounded, size: 17),
              label: const Text('Full post & report history'),
            ),
          ),
      ],
    );
  }
}
