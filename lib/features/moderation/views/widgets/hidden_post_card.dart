import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:emam_admin_web_app/core/utils/formatters.dart';
import 'package:emam_admin_web_app/core/widgets/detail_block.dart';
import 'package:emam_admin_web_app/core/widgets/pill_action_button.dart';
import 'package:emam_admin_web_app/core/widgets/status_badge.dart';
import 'package:emam_admin_web_app/features/content/views/widgets/content_section_card.dart';
import 'package:emam_admin_web_app/features/moderation/models/hidden_post.dart';
import 'package:emam_admin_web_app/features/moderation/provider/hidden_posts_provider.dart';
import 'package:emam_admin_web_app/features/moderation/views/widgets/restore_dua_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HiddenPostCard extends ConsumerWidget {
  const HiddenPostCard({super.key, required this.post});

  final HiddenPost post;

  static const Color _danger = Color(0xFFE57373);
  static const Color _restoreGreen = Color(0xFF66BB6A);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final displayName = post.userDisplayName.isNotEmpty
        ? post.userDisplayName
        : 'Unknown user';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppConstants.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _danger.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.visibility_off_rounded,
                  color: _danger,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      post.location.isNotEmpty ? post.location : 'No location',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(
                label: titleCase(post.status),
                color: _danger,
              ),
            ],
          ),
          const SizedBox(height: 14),
          DetailBlock(
            label: 'Content',
            value: post.content.isNotEmpty ? post.content : 'No content',
          ),
          if (post.hiddenReason.isNotEmpty) ...[
            const SizedBox(height: 10),
            DetailBlock(
              label: 'Hidden reason',
              value: post.hiddenReason,
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ContentMetaChip(label: '${post.reportCount} reports'),
              ContentMetaChip(label: '${post.ameenCount} ameen'),
              if (post.hiddenBy.isNotEmpty)
                ContentMetaChip(label: 'Hidden by ${shortId(post.hiddenBy)}'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Hidden ${_formatPostDate(post.hiddenAt)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white54,
                  ),
                ),
              ),
              PillActionButton(
                icon: Icons.visibility_rounded,
                label: 'Restore',
                color: _restoreGreen,
                onPressed: post.id.isEmpty
                    ? null
                    : () => _onRestorePressed(context, ref),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _onRestorePressed(BuildContext context, WidgetRef ref) async {
    final restored = await showRestoreDuaDialog(
      context,
      postId: post.id,
    );
    if (restored != true || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Post ${shortId(post.id)} has been restored.',
        ),
      ),
    );
    await ref.read(hiddenPostsPaginationProvider.notifier).refresh();
  }

  static String _formatPostDate(DateTime? date) =>
      formatAdminDate(date, unknownLabel: 'unknown date', includeTime: true);
}
