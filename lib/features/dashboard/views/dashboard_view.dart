import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:emam_admin_web_app/features/content/views/widgets/content_section_card.dart';
import 'package:emam_admin_web_app/features/dashboard/provider/selected_users_tab_provider.dart';
import 'package:emam_admin_web_app/features/moderation/provider/hidden_posts_provider.dart';
import 'package:emam_admin_web_app/features/moderation/provider/reported_duas_provider.dart';
import 'package:emam_admin_web_app/features/users/provider/restricted_users_provider.dart';
import 'package:emam_admin_web_app/features/users/provider/users_provider.dart';
import 'package:emam_admin_web_app/features/users/views/widgets/user_search_dialog.dart';
import 'package:emam_admin_web_app/features/users/views/widgets/users_management_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTab = ref.watch(selectedUsersTabProvider);
    final usersState = ref.watch(usersPaginationProvider);
    final usersNotifier = ref.read(usersPaginationProvider.notifier);
    final restrictedState = ref.watch(restrictedUsersPaginationProvider);
    final restrictedNotifier = ref.read(
      restrictedUsersPaginationProvider.notifier,
    );
    final reportedDuasState = ref.watch(reportedDuasProvider);
    final reportedDuasNotifier = ref.read(reportedDuasProvider.notifier);
    final hiddenPostsState = ref.watch(hiddenPostsPaginationProvider);
    final hiddenPostsNotifier = ref.read(
      hiddenPostsPaginationProvider.notifier,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = contentHorizontalPadding(
          constraints.maxWidth,
        );

        return RefreshIndicator(
          color: AppConstants.primary,
          backgroundColor: AppConstants.surfaceColor,
          onRefresh: () async {
            switch (selectedTab) {
              case UsersTab.all:
                await usersNotifier.refresh();
              case UsersTab.blocked:
                await restrictedNotifier.refresh();
              case UsersTab.reportedDuas:
                await reportedDuasNotifier.refresh();
              case UsersTab.hiddenPosts:
                await hiddenPostsNotifier.refresh();
            }
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              24,
              horizontalPadding,
              32,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DashboardHeader(
                  onSearch: () => showUserSearchDialog(context),
                  onRefresh: () => Future.wait([
                    usersNotifier.refresh(),
                    restrictedNotifier.refresh(),
                    reportedDuasNotifier.refresh(),
                    hiddenPostsNotifier.refresh(),
                  ]),
                ),
                const SizedBox(height: 24),
                _DashboardStatsRow(
                  selectedTab: selectedTab,
                  onTabSelected: ref
                      .read(selectedUsersTabProvider.notifier)
                      .select,
                  usersState: usersState,
                  restrictedState: restrictedState,
                  reportedDuasState: reportedDuasState,
                  hiddenPostsState: hiddenPostsState,
                ),
                const SizedBox(height: 24),
                UsersManagementSection(
                  selectedTab: selectedTab,
                  usersState: usersState,
                  restrictedState: restrictedState,
                  reportedDuasState: reportedDuasState,
                  hiddenPostsState: hiddenPostsState,
                  onUsersRetry: usersNotifier.refresh,
                  onUsersPageTap: usersNotifier.goToPage,
                  onRestrictedRetry: restrictedNotifier.refresh,
                  onRestrictedPageTap: restrictedNotifier.goToPage,
                  onReportedDuasRetry: reportedDuasNotifier.refresh,
                  onHiddenPostsRetry: hiddenPostsNotifier.refresh,
                  onHiddenPostsPageTap: hiddenPostsNotifier.goToPage,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.onSearch, required this.onRefresh});

  final VoidCallback onSearch;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dashboard',
          style: textTheme.headlineMedium?.copyWith(
            color: AppConstants.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Pick a card to manage users, reports and posts. '
          'Pull down or tap refresh to update.',
          style: textTheme.bodyMedium?.copyWith(
            color: AppConstants.textSecondary,
          ),
        ),
      ],
    );

    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Refresh all',
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh_rounded),
          style: IconButton.styleFrom(
            side: BorderSide(color: AppConstants.borderColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusSm),
            ),
            padding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(width: AppConstants.space8),
        FilledButton.icon(
          onPressed: onSearch,
          icon: const Icon(Icons.search_rounded, size: 20),
          label: const Text('Find a user'),
          style: FilledButton.styleFrom(
            backgroundColor: AppConstants.primary,
            foregroundColor: AppConstants.black,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusSm),
            ),
          ),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 640) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [title, const SizedBox(height: 16), actions],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: title),
            const SizedBox(width: 16),
            actions,
          ],
        );
      },
    );
  }
}

class _DashboardStatsRow extends StatelessWidget {
  const _DashboardStatsRow({
    required this.selectedTab,
    required this.onTabSelected,
    required this.usersState,
    required this.restrictedState,
    required this.reportedDuasState,
    required this.hiddenPostsState,
  });

  final UsersTab selectedTab;
  final ValueChanged<UsersTab> onTabSelected;
  final UsersPageState usersState;
  final RestrictedUsersPageState restrictedState;
  final ReportedDuasState reportedDuasState;
  final HiddenPostsPageState hiddenPostsState;

  @override
  Widget build(BuildContext context) {
    final hasUsers = usersState.pages.isNotEmpty;
    final hasRestricted = restrictedState.currentResponse != null;
    final hasReports =
        !reportedDuasState.isLoading || reportedDuasState.reports.isNotEmpty;
    final hasHiddenPosts = hiddenPostsState.currentResponse != null;

    // The users API is paginated with no total, so show what has been loaded
    // and a "+" while the server still has more pages, never a page size
    // masquerading as the total.
    final loadedUsers = usersState.pages.fold<int>(
      0,
      (sum, page) => sum + page.users.length,
    );
    final usersMore = usersState.hasNextToken;
    final openReports = reportedDuasState.reports
        .where((report) => report.isOpen)
        .length;
    final hiddenMore = hiddenPostsState.hasNextToken;

    String value(int count, {required bool ready, bool more = false}) =>
        ready ? '$count${more ? '+' : ''}' : '—';

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1000
            ? 4
            : constraints.maxWidth >= 600
            ? 2
            : 1;
        const spacing = 16.0;
        final totalSpacing = spacing * (columns - 1);
        final tileWidth = (constraints.maxWidth - totalSpacing) / columns;

        Widget tile(_StatCard card) => SizedBox(width: tileWidth, child: card);

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            tile(
              _StatCard(
                label: 'All users',
                value: value(loadedUsers, ready: hasUsers, more: usersMore),
                caption: !hasUsers
                    ? 'Loading…'
                    : usersMore
                    ? 'Loaded so far · more available'
                    : 'Everyone registered',
                icon: Icons.people_alt_rounded,
                baseColor: AppConstants.primary,
                selected: selectedTab == UsersTab.all,
                onTap: () => onTabSelected(UsersTab.all),
              ),
            ),
            tile(
              _StatCard(
                label: 'Blocked users',
                value: value(
                  restrictedState.totalRestricted ?? 0,
                  ready: hasRestricted,
                ),
                caption: hasRestricted ? 'Restricted from posting' : 'Loading…',
                icon: Icons.block_rounded,
                baseColor: AppConstants.danger,
                selected: selectedTab == UsersTab.blocked,
                onTap: () => onTabSelected(UsersTab.blocked),
              ),
            ),
            tile(
              _StatCard(
                label: "Reported Dua's",
                value: value(
                  reportedDuasState.reports.length,
                  ready: hasReports,
                ),
                caption: !hasReports
                    ? 'Loading…'
                    : openReports > 0
                    ? '$openReports need review'
                    : 'All caught up',
                attention: hasReports && openReports > 0,
                icon: Icons.flag_rounded,
                baseColor: AppConstants.warning,
                selected: selectedTab == UsersTab.reportedDuas,
                onTap: () => onTabSelected(UsersTab.reportedDuas),
              ),
            ),
            tile(
              _StatCard(
                label: 'Hidden posts',
                value: value(
                  hiddenPostsState.totalLoadedPosts,
                  ready: hasHiddenPosts,
                  more: hiddenMore,
                ),
                caption: !hasHiddenPosts
                    ? 'Loading…'
                    : hiddenMore
                    ? 'Loaded so far · more available'
                    : 'Removed by moderation',
                icon: Icons.visibility_off_rounded,
                baseColor: AppConstants.info,
                selected: selectedTab == UsersTab.hiddenPosts,
                onTap: () => onTabSelected(UsersTab.hiddenPosts),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.caption,
    required this.icon,
    required this.baseColor,
    required this.selected,
    required this.onTap,
    this.attention = false,
  });

  final String label;
  final String value;

  /// One-line context under the number, so the tile explains itself.
  final String caption;
  final IconData icon;

  /// Distinct hue per metric (gold/danger/warning/info) so the four tiles
  /// are scannable at a glance instead of all sharing the brand accent.
  final Color baseColor;
  final bool selected;
  final bool attention;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final borderColor = selected
        ? baseColor.withValues(alpha: 0.7)
        : AppConstants.borderColor;
    final background = selected
        ? baseColor.withValues(alpha: 0.08)
        : AppConstants.surfaceColor;

    return Semantics(
      button: true,
      selected: selected,
      label: '$label, $value. $caption',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            padding: const EdgeInsets.all(AppConstants.space20),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(AppConstants.radiusLg),
              border: Border.all(color: borderColor, width: selected ? 1.4 : 1),
              boxShadow: [
                BoxShadow(
                  color: selected
                      ? baseColor.withValues(alpha: 0.16)
                      : Colors.black.withValues(alpha: 0.2),
                  blurRadius: selected ? 20 : 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppConstants.space8),
                      decoration: BoxDecoration(
                        color: baseColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusSm,
                        ),
                      ),
                      child: Icon(icon, color: baseColor, size: 20),
                    ),
                    const SizedBox(width: AppConstants.space12),
                    Expanded(
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleSmall?.copyWith(
                          color: AppConstants.textSecondary,
                        ),
                      ),
                    ),
                    if (selected)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: baseColor.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(
                            AppConstants.radiusPill,
                          ),
                        ),
                        child: Text(
                          'Viewing',
                          style: textTheme.labelSmall?.copyWith(
                            color: baseColor,
                          ),
                        ),
                      )
                    else
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: AppConstants.textFaint,
                      ),
                  ],
                ),
                const SizedBox(height: AppConstants.space16),
                Text(
                  value,
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (attention) ...[
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: baseColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: Text(
                        caption,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: attention ? baseColor : AppConstants.textMuted,
                          fontWeight: attention
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
