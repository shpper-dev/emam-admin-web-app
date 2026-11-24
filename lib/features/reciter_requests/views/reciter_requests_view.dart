import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:emam_admin_web_app/core/widgets/app_snackbar.dart';
import 'package:emam_admin_web_app/core/widgets/filter_pill.dart';
import 'package:emam_admin_web_app/core/widgets/inline_retry_error.dart';
import 'package:emam_admin_web_app/core/widgets/pill_action_button.dart';
import 'package:emam_admin_web_app/core/widgets/section_empty_message.dart';
import 'package:emam_admin_web_app/core/widgets/skeleton.dart';
import 'package:emam_admin_web_app/core/widgets/status_badge.dart';
import 'package:emam_admin_web_app/features/content/views/widgets/content_section_card.dart';
import 'package:emam_admin_web_app/features/content_reports/views/report_display.dart';
import 'package:emam_admin_web_app/features/reciter_requests/models/reciter_request.dart';
import 'package:emam_admin_web_app/features/reciter_requests/provider/reciter_requests_provider.dart';
import 'package:emam_admin_web_app/features/reciter_requests/views/reciter_request_dialog.dart';
import 'package:emam_admin_web_app/features/users/views/widgets/users_pagination_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Color reciterStatusColor(String status) => switch (status) {
  'new' => AppConstants.warning,
  'planned' => AppConstants.info,
  'added' => AppConstants.success,
  'not_possible' => AppConstants.danger,
  _ => AppConstants.textMuted,
};

class ReciterRequestsView extends ConsumerStatefulWidget {
  const ReciterRequestsView({super.key});

  @override
  ConsumerState<ReciterRequestsView> createState() =>
      _ReciterRequestsViewState();
}

class _ReciterRequestsViewState extends ConsumerState<ReciterRequestsView> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _open(ReciterRequest request) async {
    final messenger = ScaffoldMessenger.of(context);
    final saved = await showReciterRequestDialog(context, request: request);
    if (saved == true) showAppSnackBar(messenger, 'Request updated');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(reciterRequestsProvider);
    final n = ref.read(reciterRequestsProvider.notifier);
    final items = state.currentResponse?.items ?? const <ReciterRequest>[];
    final newCount = state.newCount;
    final filtered = state.status != null || state.query.isNotEmpty;

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
                          'Reciter Requests',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: AppConstants.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Reciters users asked for, highest demand first.',
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
              TextField(
                controller: _search,
                textInputAction: TextInputAction.search,
                onSubmitted: n.setQuery,
                style: const TextStyle(color: AppConstants.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search reciter name',
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
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterPill(
                      label: 'All',
                      selected: state.status == null,
                      onTap: () => n.setStatus(null),
                    ),
                    for (final s in kReciterStatuses) ...[
                      const SizedBox(width: 8),
                      FilterPill(
                        label: s == 'new' && (newCount ?? 0) > 0
                            ? 'New · $newCount'
                            : reciterStatusLabel(s),
                        selected: state.status == s,
                        onTap: () => n.setStatus(s),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ContentSectionCard(
                title: 'Requests',
                subtitle: state.isLoading && items.isEmpty
                    ? 'Loading…'
                    : 'Page ${state.currentPage}'
                          '${items.isEmpty ? '' : ' · ${items.length} shown'}'
                          '${filtered ? ' · filtered' : ''}',
                icon: Icons.mic_external_on_rounded,
                trailing: filtered
                    ? TextButton.icon(
                        onPressed: () {
                          _search.clear();
                          n.clearFilters();
                        },
                        icon: const Icon(
                          Icons.filter_alt_off_rounded,
                          size: 18,
                        ),
                        label: const Text('Clear filters'),
                      )
                    : null,
                child: _body(state, items, n, filtered),
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
    ReciterRequestsState state,
    List<ReciterRequest> items,
    ReciterRequestsNotifier n,
    bool filtered,
  ) {
    if (state.errorMessage != null && items.isEmpty) {
      return InlineRetryError(message: state.errorMessage!, onRetry: n.refresh);
    }
    if (state.isLoading && items.isEmpty) {
      return const SkeletonList(rows: 4, rowHeight: 72);
    }
    if (items.isEmpty) {
      return SectionEmptyMessage(
        filtered ? 'No requests match these filters.' : 'No requests yet.',
        icon: filtered ? Icons.search_off_rounded : Icons.task_alt_rounded,
        hint: filtered
            ? 'Try a different status or name, or clear the filters.'
            : 'Reciter requests from the app will show up here.',
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
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: AppConstants.space12),
          _RequestCard(request: items[i], onTap: () => _open(items[i])),
        ],
      ],
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request, required this.onTap});

  final ReciterRequest request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = request;
    final color = reciterStatusColor(r.status);
    final langs =
        (r.langCounts.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
            .map((e) => '${e.key.toUpperCase()} ${e.value}')
            .join(' · ');

    return Semantics(
      button: true,
      label:
          '${r.displayName}, ${r.requestCount} requests, '
          '${reciterStatusLabel(r.status)}',
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
                Container(width: 4, color: color),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.space16),
                    child: Row(
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${r.requestCount}',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: AppConstants.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'requests',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppConstants.textMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                [
                                  if (langs.isNotEmpty) langs,
                                  'last ${relativeTime(r.lastRequestedAt)}',
                                ].join(' · '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppConstants.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        StatusBadge(
                          label: reciterStatusLabel(r.status),
                          color: color,
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: AppConstants.textFaint,
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
