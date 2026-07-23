import 'package:emam_admin_web_app/core/constants/app_constants.dart';
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

  static const Color _success = Color(0xFF81C784);
  static const Color _danger = Color(0xFFE57373);
  static const Color _restoreGreen = Color(0xFF66BB6A);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final hiddenPostIds = ref.watch(
      reportedDuasProvider.select((state) => state.hiddenPostIds),
    );
    final cachedHiddenIds = ref.watch(hiddenPostIdsProvider);
    final isPostHidden = isReportedPostHidden(
      report,
      {...hiddenPostIds, ...cachedHiddenIds},
    );
    final displayName = report.postUserDisplayName.isNotEmpty
        ? report.postUserDisplayName
        : 'Unknown author';
    final location = report.postLocation.isNotEmpty
        ? report.postLocation
        : 'No location';
    final postStatusLabel = report.postStatus.isNotEmpty
        ? _titleCase(report.postStatus)
        : (isPostHidden ? 'Hidden' : 'Active');
    final postStatusColor =
        isPostHidden || postStatusLabel.toLowerCase() == 'hidden'
            ? _danger
            : _success;

    final duaText = report.postContent.isNotEmpty
        ? report.postContent
        : 'No content available';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
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
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Reported ${_formatDate(report.createdAt)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusBadge(
                          label: 'Post $postStatusLabel',
                          color: postStatusColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _DetailBlock(label: 'Dua', value: duaText),
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
                            label: 'Posted ${_formatDate(report.postCreatedAt)}',
                          ),
                        if (isPostHidden && report.postHiddenAt != null)
                          ContentMetaChip(
                            label:
                                'Hidden ${_formatDate(report.postHiddenAt)}',
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
                TextButton.icon(
                  onPressed: report.postId.isEmpty
                      ? null
                      : () => _onRestorePressed(context, ref),
                  icon: const Icon(Icons.visibility_rounded, size: 18),
                  label: const Text('Restore'),
                  style: TextButton.styleFrom(
                    foregroundColor: _restoreGreen,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 12,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    side: BorderSide(
                      color: _restoreGreen.withValues(alpha: 0.55),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                )
              else
                TextButton.icon(
                  onPressed: report.postId.isEmpty
                      ? null
                      : () => _onHidePressed(context, ref),
                  icon: const Icon(Icons.visibility_off_rounded, size: 18),
                  label: const Text('Hide'),
                  style: TextButton.styleFrom(
                    foregroundColor: _danger,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 12,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    side: BorderSide(color: _danger.withValues(alpha: 0.55)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
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
    final theme = Theme.of(context);

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppConstants.surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
          title: Text(
            'Report details',
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DetailBlock(
                  label: 'Report reason',
                  value: report.reason.isNotEmpty
                      ? report.reason
                      : 'No reason given',
                ),
                const SizedBox(height: 10),
                _DetailBlock(
                  label: 'Reporter note',
                  value: report.details.isNotEmpty
                      ? report.details
                      : 'No note provided',
                ),
                if (isPostHidden) ...[
                  const SizedBox(height: 10),
                  _DetailBlock(
                    label: 'Hidden reason by admin',
                    value: report.postHiddenReason.isNotEmpty
                        ? report.postHiddenReason
                        : 'No reason recorded',
                  ),
                ],
              ],
            ),
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
    final hidden = await showHideDuaDialog(
      context,
      postId: report.postId,
    );
    if (hidden != true || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_postSummary(report)} has been hidden.'),
      ),
    );
    await ref.read(reportedDuasProvider.notifier).refresh();
    await ref.read(hiddenPostsPaginationProvider.notifier).refresh();
  }

  Future<void> _onRestorePressed(BuildContext context, WidgetRef ref) async {
    final restored = await showRestoreDuaDialog(
      context,
      postId: report.postId,
    );
    if (restored != true || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_postSummary(report)} has been restored.'),
      ),
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

  static String _titleCase(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }

  static String _formatDate(DateTime? date) {
    if (date == null) return 'unknown date';
    final local = date.toLocal();
    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}

class _DetailBlock extends StatelessWidget {
  const _DetailBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white54,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.88),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
