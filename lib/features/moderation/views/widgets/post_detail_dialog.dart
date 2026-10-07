import 'package:dio/dio.dart';
import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:emam_admin_web_app/core/network/api_error.dart';
import 'package:emam_admin_web_app/core/utils/formatters.dart';
import 'package:emam_admin_web_app/core/widgets/admin_alert_dialog.dart';
import 'package:emam_admin_web_app/core/widgets/detail_block.dart';
import 'package:emam_admin_web_app/core/widgets/inline_retry_error.dart';
import 'package:emam_admin_web_app/core/widgets/status_badge.dart';
import 'package:emam_admin_web_app/features/content/views/widgets/content_section_card.dart';
import 'package:emam_admin_web_app/features/moderation/models/moderation_queue.dart';
import 'package:emam_admin_web_app/features/moderation/models/moderation_report.dart';
import 'package:emam_admin_web_app/features/moderation/provider/moderation_queue_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showPostDetailDialog(
  BuildContext context, {
  required String postId,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => PostDetailDialog(postId: postId),
  );
}

String _date(DateTime? d) => formatAdminDate(d, includeTime: true);

class PostDetailDialog extends ConsumerWidget {
  const PostDetailDialog({super.key, required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(postDetailProvider(postId));

    return AdminAlertDialog(
      title: 'Post ${shortId(postId)}',
      icon: Icons.article_rounded,
      accentColor: AppConstants.warning,
      contentWidth: 560,
      content: detail.when(
        loading: () => const SectionLoadingIndicator(),
        error: (e, _) => InlineRetryError(
          message: e is DioException
              ? parseApiError(e)
              : 'Failed to load post. Please try again.',
          onRetry: () => ref.invalidate(postDetailProvider(postId)),
        ),
        data: (d) => _Body(detail: d),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.detail});

  final PostDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final post = detail.post;
    final hidden = detail.isHidden;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  post.userDisplayName.isNotEmpty
                      ? post.userDisplayName
                      : 'Unknown user',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              StatusBadge(
                label: titleCase(post.status),
                color: hidden ? AppConstants.danger : AppConstants.success,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            post.location.isNotEmpty ? post.location : 'No location',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppConstants.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          DetailBlock(
            label: 'Content',
            value: post.content.isNotEmpty ? post.content : 'No content',
          ),
          if (hidden && post.hiddenReason.isNotEmpty) ...[
            const SizedBox(height: 10),
            DetailBlock(label: 'Hidden reason', value: post.hiddenReason),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ContentMetaChip(label: '${post.ameenCount} ameen'),
              ContentMetaChip(label: '${post.reportCount} reports'),
              ContentMetaChip(
                label: '${detail.openReportCount} open',
                color: detail.openReportCount > 0
                    ? AppConstants.warning
                    : AppConstants.primary,
              ),
              if (post.userId.isNotEmpty)
                ContentMetaChip(label: 'Author ${shortId(post.userId)}'),
              if (hidden && post.hiddenBy.isNotEmpty)
                ContentMetaChip(label: 'Hidden by ${shortId(post.hiddenBy)}'),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Posted ${_date(post.createdAt)}'
            '${hidden ? ' · Hidden ${_date(post.hiddenAt)}' : ''}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppConstants.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Reports (${detail.reports.length})',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          if (detail.reports.isEmpty)
            Text(
              'No reports on this post.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppConstants.textMuted,
              ),
            )
          else
            for (final report in detail.reports) ...[
              _ReportTile(report: report),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  const _ReportTile({required this.report});

  final ModerationReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolved = !report.isOpen;
    final action = (report.resolutionAction ?? '').trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.space12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(AppConstants.radiusSm),
        border: Border.all(color: AppConstants.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  titleCase(report.reason.isNotEmpty ? report.reason : 'other'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              StatusBadge(
                label: resolved && action.isNotEmpty
                    ? '${titleCase(report.status)} · ${action.replaceAll('_', ' ')}'
                    : titleCase(report.status),
                color: resolved ? AppConstants.success : AppConstants.warning,
              ),
            ],
          ),
          if (report.details.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(report.details, style: theme.textTheme.bodySmall),
          ],
          const SizedBox(height: 6),
          Text(
            'By ${shortId(report.reporterUserId)} · ${_date(report.createdAt)}'
            '${resolved && report.resolvedAt != null ? ' · Resolved ${_date(report.resolvedAt)}' : ''}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppConstants.textMuted,
            ),
          ),
          if ((report.resolutionNote ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Note: ${report.resolutionNote}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
