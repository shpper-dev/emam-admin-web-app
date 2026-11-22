import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:emam_admin_web_app/core/utils/formatters.dart';
import 'package:emam_admin_web_app/core/widgets/app_snackbar.dart';
import 'package:emam_admin_web_app/core/widgets/filter_pill.dart';
import 'package:emam_admin_web_app/core/widgets/inline_retry_error.dart';
import 'package:emam_admin_web_app/core/widgets/pill_action_button.dart';
import 'package:emam_admin_web_app/core/widgets/section_empty_message.dart';
import 'package:emam_admin_web_app/core/widgets/skeleton.dart';
import 'package:emam_admin_web_app/core/widgets/status_badge.dart';
import 'package:emam_admin_web_app/features/content/views/widgets/content_section_card.dart';
import 'package:emam_admin_web_app/features/content_reports/models/content_report.dart';
import 'package:emam_admin_web_app/features/content_reports/provider/content_reports_provider.dart';
import 'package:emam_admin_web_app/features/content_reports/views/report_detail_dialog.dart';
import 'package:emam_admin_web_app/features/content_reports/views/report_display.dart';
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

  void _clearFilters() {
    _search.clear();
    ref
        .read(contentReportsProvider.notifier)
        .setFilters(status: null, contentType: null, query: '');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(contentReportsProvider);
    final n = ref.read(contentReportsProvider.notifier);
    final reports = state.currentResponse?.reports ?? const <ContentReport>[];
    final newCount = state.newCount;
    final filtered =
        state.status != null ||
        state.contentType != null ||
        state.query.isNotEmpty;

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
                          'users, newest first.',
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
              _Toolbar(
                search: _search,
                state: state,
                newCount: newCount,
                onSearch: n.setQuery,
                onStatus: n.setStatus,
                onType: n.setContentType,
              ),
              const SizedBox(height: 20),
              ContentSectionCard(
                title: 'Reports',
                subtitle: state.isLoading && reports.isEmpty
                    ? 'Loading…'
                    : 'Page ${state.currentPage}'
                          '${reports.isEmpty ? '' : ' · ${reports.length} shown'}'
                          '${filtered ? ' · filtered' : ''}',
                icon: Icons.spellcheck_rounded,
                trailing: filtered
                    ? TextButton.icon(
                        onPressed: _clearFilters,
                        icon: const Icon(
                          Icons.filter_alt_off_rounded,
                          size: 18,
                        ),
                        label: const Text('Clear filters'),
                      )
                    : null,
                child: _body(state, reports, n, filtered),
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
    bool filtered,
  ) {
    if (state.errorMessage != null && reports.isEmpty) {
      return InlineRetryError(message: state.errorMessage!, onRetry: n.refresh);
    }
    if (state.isLoading && reports.isEmpty) {
      return const SkeletonList(rows: 4, rowHeight: 96);
    }
    if (reports.isEmpty) {
      return SectionEmptyMessage(
        filtered ? 'No reports match these filters.' : 'All caught up.',
        icon: filtered ? Icons.search_off_rounded : Icons.task_alt_rounded,
        hint: filtered
            ? 'Try a different status or type, or clear the filters.'
            : 'New mistake reports from the app will show up here.',
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
        for (var i = 0; i < reports.length; i++) ...[
          if (i > 0) const SizedBox(height: AppConstants.space12),
          _ReportCard(report: reports[i], onTap: () => _open(reports[i])),
        ],
      ],
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.search,
    required this.state,
    required this.newCount,
    required this.onSearch,
    required this.onStatus,
    required this.onType,
  });

  final TextEditingController search;
  final ContentReportsState state;
  final int? newCount;
  final ValueChanged<String> onSearch;
  final ValueChanged<String?> onStatus;
  final ValueChanged<String?> onType;

  @override
  Widget build(BuildContext context) {
    final searchField = TextField(
      controller: search,
      textInputAction: TextInputAction.search,
      onSubmitted: onSearch,
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
                  search.clear();
                  onSearch('');
                },
              ),
      ),
    );

    final statusPills = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          FilterPill(
            label: 'All',
            selected: state.status == null,
            onTap: () => onStatus(null),
          ),
          for (final s in kReportStatuses) ...[
            const SizedBox(width: 8),
            FilterPill(
              label: s == 'new' && (newCount ?? 0) > 0
                  ? 'New · $newCount'
                  : reportStatusLabel(s),
              selected: state.status == s,
              onTap: () => onStatus(s),
            ),
          ],
        ],
      ),
    );

    final typeMenu = _TypeMenu(selected: state.contentType, onSelected: onType);

    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 760) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              searchField,
              const SizedBox(height: 12),
              statusPills,
              const SizedBox(height: 12),
              typeMenu,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: searchField),
                const SizedBox(width: 12),
                typeMenu,
              ],
            ),
            const SizedBox(height: 12),
            statusPills,
          ],
        );
      },
    );
  }
}

class _TypeMenu extends StatelessWidget {
  const _TypeMenu({required this.selected, required this.onSelected});

  final String? selected;
  final ValueChanged<String?> onSelected;

  static const _all = '';

  @override
  Widget build(BuildContext context) {
    final active = selected != null;
    final color = active ? AppConstants.primary : AppConstants.textSecondary;
    return PopupMenuButton<String>(
      tooltip: 'Filter by content type',
      color: AppConstants.surfaceElevated,
      onSelected: (v) => onSelected(v == _all ? null : v),
      itemBuilder: (_) => [
        const PopupMenuItem(value: _all, child: Text('All types')),
        for (final e in kReportContentTypes.entries)
          PopupMenuItem(
            value: e.key,
            child: Row(
              children: [
                Icon(reportTypeIcon(e.key), size: 18),
                const SizedBox(width: 10),
                Text(e.value),
              ],
            ),
          ),
      ],
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: active
              ? AppConstants.primary.withValues(alpha: 0.14)
              : AppConstants.inputFillColor,
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          border: Border.all(
            color: active
                ? AppConstants.primary.withValues(alpha: 0.5)
                : AppConstants.borderColorStrong,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              active ? reportTypeIcon(selected!) : Icons.category_outlined,
              size: 18,
              color: color,
            ),
            const SizedBox(width: 8),
            Text(
              active ? reportTypeLabel(selected!) : 'All types',
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down_rounded, color: color),
          ],
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report, required this.onTap});

  final ContentReport report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = report;
    final statusColor = reportStatusColor(r.status);
    final rtl = isRtlLang(r.lang);
    final reporter = r.userId != null
        ? 'User ${shortId(r.userId!)}'
        : r.deviceId != null
        ? 'Guest ${shortId(r.deviceId!)}'
        : 'Unknown reporter';
    final meta = [
      reporter,
      if (r.platform != null) r.platform!,
      r.lang.toUpperCase(),
    ].join(' · ');

    return Semantics(
      button: true,
      label: '${r.readableReference}, ${reportStatusLabel(r.status)}',
      child: Material(
        color: AppConstants.inputFillColor,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          side: BorderSide(color: AppConstants.borderColor),
        ),
        child: InkWell(
          onTap: onTap,
          hoverColor: Colors.white.withValues(alpha: 0.03),
          mouseCursor: SystemMouseCursors.click,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: statusColor),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.space16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppConstants.primary.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                reportTypeIcon(r.contentType),
                                size: 18,
                                color: AppConstants.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    r.readableReference,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    reportTypeLabel(r.contentType),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppConstants.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            StatusBadge(
                              label: reportStatusLabel(r.status),
                              color: statusColor,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 2, right: 8),
                              child: Icon(
                                Icons.format_quote_rounded,
                                size: 16,
                                color: AppConstants.textFaint,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                r.userNote,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppConstants.textPrimary.withValues(
                                    alpha: 0.92,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (r.originalText.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(
                                AppConstants.radiusSm,
                              ),
                            ),
                            child: Text(
                              r.originalText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textDirection: rtl ? TextDirection.rtl : null,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppConstants.textSecondary,
                                height: rtl ? 1.7 : null,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                meta,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppConstants.textMuted,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Tooltip(
                              message: formatAdminDate(
                                r.createdAt,
                                includeTime: true,
                              ),
                              child: Text(
                                relativeTime(r.createdAt),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppConstants.textMuted,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: AppConstants.textFaint,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
