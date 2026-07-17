import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:emam_admin_web_app/features/content/views/widgets/content_section_card.dart';
import 'package:emam_admin_web_app/features/users/provider/restricted_users_provider.dart';
import 'package:emam_admin_web_app/features/users/provider/users_provider.dart';
import 'package:emam_admin_web_app/features/users/views/widgets/users_management_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardView extends ConsumerStatefulWidget {
  const DashboardView({super.key});

  @override
  ConsumerState<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends ConsumerState<DashboardView> {
  UsersTab _selectedTab = UsersTab.all;

  @override
  Widget build(BuildContext context) {
    final usersState = ref.watch(usersPaginationProvider);
    final usersNotifier = ref.read(usersPaginationProvider.notifier);
    final restrictedState = ref.watch(restrictedUsersPaginationProvider);
    final restrictedNotifier =
        ref.read(restrictedUsersPaginationProvider.notifier);

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding =
            contentHorizontalPadding(constraints.maxWidth);

        return RefreshIndicator(
          color: AppConstants.primary,
          backgroundColor: AppConstants.surfaceColor,
          onRefresh: () async {
            if (_selectedTab == UsersTab.all) {
              await usersNotifier.refresh();
            } else {
              await restrictedNotifier.refresh();
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
                Text(
                  'Dashboard',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppConstants.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Overview of everyone using Emam.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 24),
                _DashboardStatsRow(
                  selectedTab: _selectedTab,
                  onTabSelected: (tab) => setState(() => _selectedTab = tab),
                  usersState: usersState,
                  restrictedState: restrictedState,
                ),
                const SizedBox(height: 24),
                UsersManagementSection(
                  selectedTab: _selectedTab,
                  usersState: usersState,
                  restrictedState: restrictedState,
                  onUsersRetry: usersNotifier.refresh,
                  onUsersPageTap: usersNotifier.goToPage,
                  onRestrictedRetry: restrictedNotifier.refresh,
                  onRestrictedPageTap: restrictedNotifier.goToPage,
                ),
              ],
            ),
          ),
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
  });

  final UsersTab selectedTab;
  final ValueChanged<UsersTab> onTabSelected;
  final UsersPageState usersState;
  final RestrictedUsersPageState restrictedState;

  @override
  Widget build(BuildContext context) {
    final hasUsers = usersState.currentResponse != null;
    final hasRestricted = restrictedState.currentResponse != null;

    String value(int count, {required bool ready}) => ready ? '$count' : '—';

    final allUsers = value(
      usersState.currentResponse?.users.length ?? 0,
      ready: hasUsers,
    );
    final blocked = value(
      restrictedState.totalRestricted ?? 0,
      ready: hasRestricted,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 700 ? 2 : 1;
        const spacing = 16.0;
        final totalSpacing = spacing * (columns - 1);
        final tileWidth = (constraints.maxWidth - totalSpacing) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: tileWidth,
              child: _StatCard(
                label: 'All users',
                value: allUsers,
                icon: Icons.people_alt_rounded,
                selected: selectedTab == UsersTab.all,
                onTap: () => onTabSelected(UsersTab.all),
              ),
            ),
            SizedBox(
              width: tileWidth,
              child: _StatCard(
                label: 'Blocked users',
                value: blocked,
                icon: Icons.block_rounded,
                selected: selectedTab == UsersTab.blocked,
                onTap: () => onTabSelected(UsersTab.blocked),
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
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? AppConstants.primary.withValues(alpha: 0.55)
        : Colors.white.withValues(alpha: 0.08);
    final background = selected
        ? AppConstants.primary.withValues(alpha: 0.08)
        : AppConstants.surfaceColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: selected ? 1.4 : 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppConstants.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppConstants.primary, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: AppConstants.primary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
