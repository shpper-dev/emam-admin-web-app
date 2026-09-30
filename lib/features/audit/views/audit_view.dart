import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:emam_admin_web_app/core/utils/formatters.dart';
import 'package:emam_admin_web_app/core/widgets/inline_retry_error.dart';
import 'package:emam_admin_web_app/core/widgets/pill_action_button.dart';
import 'package:emam_admin_web_app/core/widgets/section_empty_message.dart';
import 'package:emam_admin_web_app/features/audit/models/audit_entry.dart';
import 'package:emam_admin_web_app/features/audit/provider/audit_provider.dart';
import 'package:emam_admin_web_app/features/audit/utils/audit_display.dart';
import 'package:emam_admin_web_app/features/content/views/widgets/content_section_card.dart';
import 'package:emam_admin_web_app/features/users/views/widgets/users_pagination_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuditView extends ConsumerWidget {
  const AuditView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(auditProvider);
    final notifier = ref.read(auditProvider.notifier);
    final entries = state.currentResponse?.entries ?? const <AuditEntry>[];

    return LayoutBuilder(
      builder: (context, constraints) {
        final pad = contentHorizontalPadding(constraints.maxWidth);
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(pad, 24, pad, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Audit Log',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: AppConstants.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Actions taken by admins, newest first.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: AppConstants.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  PillActionButton(
                    icon: Icons.refresh_rounded,
                    label: 'Refresh',
                    color: AppConstants.primary,
                    onPressed: state.isLoading ? null : notifier.refresh,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _FilterChip(
                    label: 'All activity',
                    icon: Icons.list_alt_rounded,
                    selected: state.actionFilter == null,
                    onTap: () => notifier.setActionFilter(null),
                  ),
                  for (final e in kAuditFilters.entries)
                    _FilterChip(
                      label: e.value.$1,
                      icon: e.value.$2,
                      selected: state.actionFilter == e.key,
                      onTap: () => notifier.setActionFilter(e.key),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              ContentSectionCard(
                title: 'Activity',
                subtitle:
                    'Page ${state.currentPage}'
                    '${entries.isEmpty ? '' : ' · ${entries.length} entries'}',
                icon: Icons.history_rounded,
                child: _body(state, entries, notifier),
              ),
              UsersPaginationBar(
                currentPage: state.currentPage,
                discoveredPages: state.discoveredPages,
                hasNextToken: state.hasNextToken,
                isLoading: state.isLoading,
                onPageTap: notifier.goToPage,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _body(
    AuditPageState state,
    List<AuditEntry> entries,
    AuditNotifier n,
  ) {
    if (state.errorMessage != null && entries.isEmpty) {
      return InlineRetryError(message: state.errorMessage!, onRetry: n.refresh);
    }
    if (state.isLoading && entries.isEmpty) {
      return const SectionLoadingIndicator();
    }
    if (entries.isEmpty) {
      return SectionEmptyMessage(
        state.actionFilter == null
            ? 'No admin activity recorded yet.'
            : 'No matching activity. Try another filter.',
        icon: Icons.history_toggle_off_rounded,
      );
    }
    return Column(
      children: [
        if (state.errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InlineRetryError(
              message: state.errorMessage!,
              onRetry: n.refresh,
            ),
          ),
        for (var i = 0; i < entries.length; i++) ...[
          if (i == 0 ||
              !sameDay(entries[i - 1].createdAt, entries[i].createdAt))
            _DayHeader(dayHeading(entries[i].createdAt), first: i == 0),
          _AuditRow(entry: entries[i]),
        ],
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppConstants.primary : AppConstants.textSecondary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppConstants.radiusPill),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? AppConstants.primary.withValues(alpha: 0.14)
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(AppConstants.radiusPill),
            border: Border.all(
              color: selected
                  ? AppConstants.primary.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: color,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader(this.label, {required this.first});

  final String label;
  final bool first;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: first ? 0 : 20, bottom: 4),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppConstants.textSecondary,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class _AuditRow extends StatelessWidget {
  const _AuditRow({required this.entry});

  final AuditEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final info = describeAudit(entry);
    final fullTime = formatAdminDate(entry.createdAt, includeTime: true);

    return InkWell(
      borderRadius: BorderRadius.circular(AppConstants.radiusMd),
      onTap: entry.targetId.isEmpty || entry.targetId == 'all'
          ? null
          : () {
              Clipboard.setData(ClipboardData(text: entry.targetId));
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(content: Text('Target ID copied')),
                );
            },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppConstants.dividerColor)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: info.color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(info.icon, size: 20, color: info.color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    info.title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (info.detail != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      info.detail!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppConstants.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Tooltip(
              message: '$fullTime\nAdmin ${shortId(entry.adminUserId)}',
              child: Text(
                timeOfDay(entry.createdAt),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppConstants.textSecondary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
