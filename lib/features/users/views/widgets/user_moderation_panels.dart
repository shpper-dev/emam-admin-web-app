import 'package:dio/dio.dart';
import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:emam_admin_web_app/core/network/api_error.dart';
import 'package:emam_admin_web_app/core/utils/formatters.dart';
import 'package:emam_admin_web_app/core/widgets/admin_alert_dialog.dart';
import 'package:emam_admin_web_app/core/widgets/inline_retry_error.dart';
import 'package:emam_admin_web_app/core/widgets/status_badge.dart';
import 'package:emam_admin_web_app/features/moderation/models/moderation_report.dart';
import 'package:emam_admin_web_app/features/users/provider/restricted_users_provider.dart';
import 'package:emam_admin_web_app/features/users/provider/user_detail_cache_provider.dart';
import 'package:emam_admin_web_app/features/users/provider/user_moderation_providers.dart';
import 'package:emam_admin_web_app/features/users/provider/users_provider.dart';
import 'package:emam_admin_web_app/features/users/provider/users_repository_provider.dart';
import 'package:emam_admin_web_app/features/users/utils/user_moderation_display.dart';
import 'package:emam_admin_web_app/features/users/views/widgets/block_user_dialog.dart';
import 'package:emam_admin_web_app/features/users/views/widgets/user_restriction_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Moderation status banner plus the admin's actions for this user:
/// block (30 days / permanent), clear restriction and reset post quota.
class UserRestrictionPanel extends ConsumerStatefulWidget {
  const UserRestrictionPanel({
    super.key,
    required this.userId,
    required this.displayName,
  });

  final String userId;
  final String displayName;

  @override
  ConsumerState<UserRestrictionPanel> createState() =>
      _UserRestrictionPanelState();
}

class _UserRestrictionPanelState extends ConsumerState<UserRestrictionPanel> {
  bool _isBusy = false;

  /// Refetches in place; invalidating the cache entry would drop the detail
  /// and leave the open dialog on its loading state.
  Future<void> _refreshAll() async {
    ref.invalidate(userRestrictionProvider(widget.userId));
    await Future.wait([
      ref.read(userDetailCacheProvider.notifier).retry(widget.userId),
      ref.read(usersPaginationProvider.notifier).refresh(),
      ref.read(restrictedUsersPaginationProvider.notifier).refresh(),
    ]);
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
    required Color color,
    required IconData icon,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AdminAlertDialog(
        title: title,
        icon: icon,
        accentColor: color,
        contentWidth: 380,
        content: Text(
          message,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppConstants.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: color),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _run(
    Future<void> Function() action,
    String successMessage, {
    bool restrictionChanged = false,
  }) async {
    setState(() => _isBusy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      messenger.showSnackBar(SnackBar(content: Text(successMessage)));
      if (restrictionChanged) await _refreshAll();
    } on DioException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(parseApiError(e))));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Something went wrong. Try again.')),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _block() async {
    final duration = await showBlockUserDialog(
      context,
      userId: widget.userId,
      displayName: widget.displayName,
    );
    if (duration == null || !mounted) return;
    showRestrictionSnackBar(
      context,
      displayName: widget.displayName,
      blocked: true,
      permanent: duration == kRestrictionPermanent,
    );
    setState(() => _isBusy = true);
    try {
      await _refreshAll();
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _clear() async {
    final ok = await _confirm(
      title: 'Clear restriction',
      message: '${widget.displayName} will be able to post again immediately.',
      confirmLabel: 'Clear restriction',
      color: AppConstants.success,
      icon: Icons.lock_open_rounded,
    );
    if (!ok || !mounted) return;
    await _run(
      () =>
          ref.read(usersRepositoryProvider).clearUserRestriction(widget.userId),
      'Restriction cleared for ${widget.displayName}.',
      restrictionChanged: true,
    );
  }

  Future<void> _resetQuota() async {
    final ok = await _confirm(
      title: 'Reset post quota',
      message:
          'Clears the rolling 24-hour post limit so ${widget.displayName} can post again right away.',
      confirmLabel: 'Reset quota',
      color: AppConstants.info,
      icon: Icons.restart_alt_rounded,
    );
    if (!ok || !mounted) return;
    await _run(
      () => ref.read(usersRepositoryProvider).resetUserQuota(widget.userId),
      'Post quota reset for ${widget.displayName}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final restriction = ref.watch(userRestrictionProvider(widget.userId));

    return restriction.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(minHeight: 2),
      ),
      error: (e, _) => InlineRetryError(
        message: e is DioException
            ? parseApiError(e)
            : 'Failed to load restriction.',
        onRetry: () => ref.invalidate(userRestrictionProvider(widget.userId)),
      ),
      data: (m) {
        final restricted = isUserPostingRestricted(
          canPost: m.canPost,
          postingRestriction: m.postingRestriction,
        );
        final permanent = m.postingRestriction.toLowerCase() == 'permanent';
        final remaining = restrictionRemainingLabel(m.restrictedUntil);
        final color = !restricted
            ? AppConstants.success
            : (permanent ? AppConstants.danger : AppConstants.warning);
        final headline = !restricted
            ? 'Can post normally'
            : (permanent
                  ? 'Permanently blocked from posting'
                  : 'Temporarily blocked from posting');
        final sub = restricted && !permanent && remaining != null
            ? 'Restriction lifts in $remaining'
            : null;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Wrap(
            spacing: 16,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    restricted
                        ? Icons.block_rounded
                        : Icons.check_circle_outline_rounded,
                    color: color,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        headline,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (sub != null)
                        Text(
                          sub,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppConstants.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _isBusy ? null : _resetQuota,
                    icon: const Icon(Icons.restart_alt_rounded, size: 18),
                    label: const Text('Reset quota'),
                  ),
                  if (restricted)
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppConstants.success,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: _isBusy ? null : _clear,
                      icon: const Icon(Icons.lock_open_rounded, size: 18),
                      label: const Text('Clear restriction'),
                    )
                  else
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppConstants.danger,
                      ),
                      onPressed: _isBusy ? null : _block,
                      icon: const Icon(Icons.block_rounded, size: 18),
                      label: const Text('Block user'),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A list of reports filed by, or against, a user.
class UserReportsList extends ConsumerWidget {
  const UserReportsList({
    super.key,
    required this.reports,
    required this.received,
    required this.onRetry,
  });

  final AsyncValue<List<ModerationReport>> reports;

  /// True for reports against the user (shows the reporter, not the author).
  final bool received;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return reports.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(8),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (e, _) => InlineRetryError(
        message: e is DioException
            ? parseApiError(e)
            : 'Failed to load reports.',
        onRetry: onRetry,
      ),
      data: (items) {
        if (items.isEmpty) {
          return Text(
            'No reports.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppConstants.textMuted),
          );
        }
        return Column(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              _ReportTile(report: items[i], received: received),
            ],
          ],
        );
      },
    );
  }
}

class _ReportTile extends StatelessWidget {
  const _ReportTile({required this.report, required this.received});

  final ModerationReport report;
  final bool received;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: AppConstants.textMuted,
    );
    final who = received
        ? 'Reporter: ${report.reporterUserId.isEmpty ? '—' : report.reporterUserId}'
        : 'Post by ${report.postUserDisplayName.isEmpty ? '—' : report.postUserDisplayName}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  report.reason.isEmpty ? 'No reason given' : report.reason,
                  style: theme.textTheme.titleSmall,
                ),
              ),
              StatusBadge(
                label: report.status.isEmpty ? 'unknown' : report.status,
                color: report.isOpen
                    ? AppConstants.warning
                    : AppConstants.success,
              ),
            ],
          ),
          if (report.details.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(report.details, style: theme.textTheme.bodySmall),
          ],
          if (report.postContent.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              report.postContent,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppConstants.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            '$who · ${formatAdminDate(report.createdAt, includeTime: true)}',
            style: muted,
          ),
        ],
      ),
    );
  }
}
