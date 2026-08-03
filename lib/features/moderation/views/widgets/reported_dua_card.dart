import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:emam_admin_web_app/core/utils/formatters.dart';
import 'package:emam_admin_web_app/core/widgets/admin_alert_dialog.dart';
import 'package:emam_admin_web_app/core/widgets/detail_block.dart';
import 'package:emam_admin_web_app/core/widgets/pill_action_button.dart';
import 'package:emam_admin_web_app/core/widgets/status_badge.dart';
import 'package:emam_admin_web_app/features/content/views/widgets/content_section_card.dart';
import 'package:emam_admin_web_app/features/moderation/models/moderation_report.dart';
import 'package:emam_admin_web_app/features/moderation/provider/hidden_posts_provider.dart';
import 'package:emam_admin_web_app/features/moderation/provider/reported_duas_provider.dart';
import 'package:emam_admin_web_app/features/moderation/utils/reported_post_hidden.dart';
import 'package:emam_admin_web_app/features/moderation/views/widgets/hide_dua_dialog.dart';
import 'package:emam_admin_web_app/features/moderation/views/widgets/restore_dua_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReportedDuaCard extends ConsumerWidget {
  const ReportedDuaCard({super.key, required this.report});

  final ModerationReport report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final hiddenPostIds = ref.watch(
      reportedDuasProvider.select((state) => state.hiddenPostIds),
    );
    final cachedHiddenIds = ref.watch(hiddenPostIdsProvider);
    final isPostHidden = isReportedPostHidden(report, {
      ...hiddenPostIds,
      ...cachedHiddenIds,
    });
    final displayName = report.postUserDisplayName.isNotEmpty
        ? report.postUserDisplayName
        : 'Unknown author';
    final location = report.postLocation.isNotEmpty
        ? report.postLocation
        : 'No location';
    final postStatusLabel = report.postStatus.isNotEmpty
        ? titleCase(report.postStatus)
        : (isPostHidden ? 'Hidden' : 'Active');
    final postStatusColor =
        isPostHidden || postStatusLabel.toLowerCase() == 'hidden'
        ? AppConstants.danger
        : AppConstants.success;

    final duaText = report.postContent.isNotEmpty
        ? report.postContent
        : 'No content available';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppConstants.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showReportDetailsDialog(
                context,
                report: report,
                isPostHidden: isPostHidden,
              ),
              borderRadius: BorderRadius.circular(10),
              mouseCursor: SystemMouseCursors.click,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppConstants.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.flag_rounded,
                            color: AppConstants.primary,
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
                                location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppConstants.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Reported ${_formatReportDate(report.createdAt)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppConstants.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusBadge(
                          label: 'Post $postStatusLabel',
                          color: postStatusColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    DetailBlock(label: 'Dua', value: duaText),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ContentMetaChip(
                          label: '${report.postReportCount} reports',
                        ),
                        ContentMetaChip(
                          label: '${report.postAmeenCount} ameen',
                        ),
                        if (report.postCreatedAt != null)
                          ContentMetaChip(
                            label:
                                'Posted ${_formatReportDate(report.postCreatedAt)}',
                          ),
                        if (isPostHidden && report.postHiddenAt != null)
                          ContentMetaChip(
                            label:
                                'Hidden ${_formatReportDate(report.postHiddenAt)}',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Spacer(),
              if (isPostHidden)
                PillActionButton(
                  icon: Icons.visibility_rounded,
                  label: 'Restore',
                  color: AppConstants.success,
                  onPressed: report.postId.isEmpty
                      ? null
                      : () => _onRestorePressed(context, ref),
                )
              else
                PillActionButton(
                  icon: Icons.visibility_off_rounded,
                  label: 'Hide',
                  color: AppConstants.danger,
                  onPressed: report.postId.isEmpty
                      ? null
                      : () => _onHidePressed(context, ref),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static void _showReportDetailsDialog(
    BuildContext context, {
    required ModerationReport report,
    required bool isPostHidden,
  }) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AdminAlertDialog(
          title: 'Report details',
          contentWidth: 420,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DetailBlock(
                label: 'Report reason',
                value: report.reason.isNotEmpty
                    ? report.reason
                    : 'No reason given',
              ),
              const SizedBox(height: 10),
              DetailBlock(
                label: 'Reporter note',
                value: report.details.isNotEmpty
                    ? report.details
                    : 'No note provided',
              ),
              if (isPostHidden) ...[
                const SizedBox(height: 10),
                DetailBlock(
                  label: 'Hidden reason by admin',
                  value: report.postHiddenReason.isNotEmpty
                      ? report.postHiddenReason
                      : 'No reason recorded',
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _onHidePressed(BuildContext context, WidgetRef ref) async {
    final hidden = await showHideDuaDialog(context, postId: report.postId);
    if (hidden != true || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_postSummary(report)} has been hidden.')),
    );
    await ref.read(reportedDuasProvider.notifier).refresh();
    await ref.read(hiddenPostsPaginationProvider.notifier).refresh();
  }

  Future<void> _onRestorePressed(BuildContext context, WidgetRef ref) async {
    final restored = await showRestoreDuaDialog(context, postId: report.postId);
    if (restored != true || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_postSummary(report)} has been restored.')),
    );
    await ref.read(reportedDuasProvider.notifier).refresh();
    await ref.read(hiddenPostsPaginationProvider.notifier).refresh();
  }

  static String _postSummary(ModerationReport report) {
    if (report.postContent.isNotEmpty) {
      final content = report.postContent.trim();
      if (content.length <= 48) return '"$content"';
      return '"${content.substring(0, 45)}…"';
    }
    if (report.postUserDisplayName.isNotEmpty) {
      return "${report.postUserDisplayName}'s dua";
    }
    return 'Dua';
  }

  static String _formatReportDate(DateTime? date) =>
      formatAdminDate(date, unknownLabel: 'unknown date', includeTime: true);
}
