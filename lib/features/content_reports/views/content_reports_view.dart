import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:emam_admin_web_app/core/utils/formatters.dart';
import 'package:emam_admin_web_app/core/widgets/app_snackbar.dart';
import 'package:emam_admin_web_app/core/widgets/inline_retry_error.dart';
import 'package:emam_admin_web_app/core/widgets/pill_action_button.dart';
import 'package:emam_admin_web_app/core/widgets/section_empty_message.dart';
import 'package:emam_admin_web_app/core/widgets/status_badge.dart';
import 'package:emam_admin_web_app/features/content/views/widgets/content_section_card.dart';
import 'package:emam_admin_web_app/features/content_reports/models/content_report.dart';
import 'package:emam_admin_web_app/features/content_reports/provider/content_reports_provider.dart';
import 'package:emam_admin_web_app/features/content_reports/views/report_detail_dialog.dart';
import 'package:emam_admin_web_app/features/users/views/widgets/users_pagination_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ContentReportsView extends ConsumerStatefulWidget {
  const ContentReportsView({super.key});

  @override
  ConsumerState<ContentReportsView> createState() => _ContentReportsViewState();
}

class _ContentReportsViewState extends ConsumerState<ContentReportsView> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _open(ContentReport report) async {
    final messenger = ScaffoldMessenger.of(context);
    final saved = await showReportDetailDialog(context, report: report);
    if (saved == true) showAppSnackBar(messenger, 'Report updated');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(contentReportsProvider);
    final n = ref.read(contentReportsProvider.notifier);
    final reports = state.currentResponse?.reports ?? const <ContentReport>[];
    final newCount = state.newCount;

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
                          'Mistake Reports',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: AppConstants.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Spelling and diacritics issues reported by app '
                          'users, newest first.'
                          '${newCount == null ? '' : ' $newCount new.'}',
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
                    onPressed: state.isLoading ? null : n.refresh,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: TextField(
                  controller: _search,
                  textInputAction: TextInputAction.search,
                  onSubmitted: n.setQuery,
                  style: const TextStyle(color: AppConstants.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search reference or content ID',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: state.query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () {
                              _search.clear();
                              n.setQuery('');
                            },
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Chip(
                    label: 'All statuses',
                    selected: state.status == null,
                    onTap: () => n.setStatus(null),
                  ),
                  for (final s in kReportStatuses)
                    _Chip(
                      label: reportStatusLabel(s),
                      selected: state.status == s,
                      onTap: () => n.setStatus(s),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Chip(
                    label: 'All types',
                    selected: state.contentType == null,
                    onTap: () => n.setContentType(null),
                  ),
                  for (final e in kReportContentTypes.entries)
                    _Chip(
                      label: e.value,
                      selected: state.contentType == e.key,
                      onTap: () => n.setContentType(e.key),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              ContentSectionCard(
                title: 'Reports',
                subtitle:
                    'Page ${state.currentPage}'
                    '${reports.isEmpty ? '' : ' · ${reports.length} reports'}',
                icon: Icons.spellcheck_rounded,
                child: _body(state, reports, n),
              ),
              UsersPaginationBar(
                currentPage: state.currentPage,
                discoveredPages: state.discoveredPages,
                hasNextToken: state.hasNextToken,
                isLoading: state.isLoading,
                onPageTap: n.goToPage,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _body(
    ContentReportsState state,
    List<ContentReport> reports,
    ContentReportsNotifier n,
  ) {
    if (state.errorMessage != null && reports.isEmpty) {
      return InlineRetryError(message: state.errorMessage!, onRetry: n.refresh);
    }
    if (state.isLoading && reports.isEmpty) {
      return const SectionLoadingIndicator();
    }
    if (reports.isEmpty) {
      return const SectionEmptyMessage(
        'No reports match these filters.',
        icon: Icons.task_alt_rounded,
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
        for (final r in reports) _ReportRow(report: r, onTap: () => _open(r)),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
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
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  const _ReportRow({required this.report, required this.onTap});

  final ContentReport report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(AppConstants.radiusMd),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppConstants.dividerColor)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.readableReference,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${reportTypeLabel(report.contentType)} · '
                    '${report.lang} · ${report.userNote}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppConstants.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StatusBadge(
                  label: reportStatusLabel(report.status),
                  color: reportStatusColor(report.status),
                ),
                const SizedBox(height: 4),
                Text(
                  formatAdminDate(report.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppConstants.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
