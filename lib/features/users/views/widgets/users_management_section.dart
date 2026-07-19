import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:emam_admin_web_app/features/content/views/widgets/content_section_card.dart';
import 'package:emam_admin_web_app/features/moderation/models/hidden_post.dart';
import 'package:emam_admin_web_app/features/moderation/models/moderation_report.dart';
import 'package:emam_admin_web_app/features/moderation/provider/hidden_posts_provider.dart';
import 'package:emam_admin_web_app/features/moderation/provider/reported_duas_provider.dart';
import 'package:emam_admin_web_app/features/moderation/views/widgets/hidden_post_card.dart';
import 'package:emam_admin_web_app/features/moderation/views/widgets/reported_dua_card.dart';
import 'package:emam_admin_web_app/features/users/models/app_user.dart';
import 'package:emam_admin_web_app/features/users/models/restricted_user.dart';
import 'package:emam_admin_web_app/features/users/provider/restricted_users_provider.dart';
import 'package:emam_admin_web_app/features/users/provider/users_provider.dart';
import 'package:emam_admin_web_app/features/users/views/widgets/restricted_user_card.dart';
import 'package:emam_admin_web_app/features/users/views/widgets/user_card.dart';
import 'package:emam_admin_web_app/features/users/views/widgets/users_pagination_bar.dart';
import 'package:flutter/material.dart';

enum UsersTab { all, blocked, reportedDuas, hiddenPosts }

class UsersManagementSection extends StatelessWidget {
  const UsersManagementSection({
    super.key,
    required this.selectedTab,
    required this.usersState,
    required this.restrictedState,
    required this.reportedDuasState,
    required this.hiddenPostsState,
    required this.onUsersRetry,
    required this.onUsersPageTap,
    required this.onRestrictedRetry,
    required this.onRestrictedPageTap,
    required this.onReportedDuasRetry,
    required this.onHiddenPostsRetry,
    required this.onHiddenPostsPageTap,
  });

  final UsersTab selectedTab;
  final UsersPageState usersState;
  final RestrictedUsersPageState restrictedState;
  final ReportedDuasState reportedDuasState;
  final HiddenPostsPageState hiddenPostsState;
  final Future<void> Function() onUsersRetry;
  final void Function(int page) onUsersPageTap;
  final Future<void> Function() onRestrictedRetry;
  final void Function(int page) onRestrictedPageTap;
  final Future<void> Function() onReportedDuasRetry;
  final Future<void> Function() onHiddenPostsRetry;
  final void Function(int page) onHiddenPostsPageTap;

  bool get _showAll => selectedTab == UsersTab.all;
  bool get _showReportedDuas => selectedTab == UsersTab.reportedDuas;
  bool get _showHiddenPosts => selectedTab == UsersTab.hiddenPosts;

  @override
  Widget build(BuildContext context) {
    final isAll = _showAll;
    final isReportedDuas = _showReportedDuas;
    final isHiddenPosts = _showHiddenPosts;
    final usersResponse = usersState.currentResponse;
    final restrictedResponse = restrictedState.currentResponse;
    final hiddenPostsResponse = hiddenPostsState.currentResponse;
    final isLoading = isAll
        ? usersState.isLoading && usersResponse == null
        : isReportedDuas
            ? reportedDuasState.isLoading && reportedDuasState.reports.isEmpty
            : isHiddenPosts
                ? hiddenPostsState.isLoading && hiddenPostsResponse == null
                : restrictedState.isLoading && restrictedResponse == null;
    final errorMessage = isAll
        ? usersState.errorMessage
        : isReportedDuas
            ? reportedDuasState.errorMessage
            : isHiddenPosts
                ? hiddenPostsState.errorMessage
                : restrictedState.errorMessage;

    return ContentSectionCard(
      title: isAll
          ? 'All Users'
          : isReportedDuas
              ? "Reported Dua's"
              : isHiddenPosts
                  ? 'Hidden Posts'
                  : 'Blocked Users',
      subtitle: _subtitle(
        isAll: isAll,
        isReportedDuas: isReportedDuas,
        isHiddenPosts: isHiddenPosts,
        usersResponse: usersResponse,
        restrictedResponse: restrictedResponse,
        hiddenPostsResponse: hiddenPostsResponse,
        reports: reportedDuasState.reports,
      ),
      icon: isAll
          ? Icons.people_alt_rounded
          : isReportedDuas
              ? Icons.flag_rounded
              : isHiddenPosts
                  ? Icons.visibility_off_rounded
                  : Icons.block_rounded,
      trailing: _trailingChip(
        isAll: isAll,
        isReportedDuas: isReportedDuas,
        isHiddenPosts: isHiddenPosts,
        usersResponse: usersResponse,
        restrictedResponse: restrictedResponse,
        hiddenPostsResponse: hiddenPostsResponse,
        reportCount: reportedDuasState.reports.length,
      ),
      child: _buildBody(
        context,
        isAll: isAll,
        isReportedDuas: isReportedDuas,
        isHiddenPosts: isHiddenPosts,
        isLoading: isLoading,
        errorMessage: errorMessage,
        usersResponse: usersResponse,
        restrictedResponse: restrictedResponse,
        hiddenPostsResponse: hiddenPostsResponse,
        reports: reportedDuasState.reports,
      ),
    );
  }

  String _subtitle({
    required bool isAll,
    required bool isReportedDuas,
    required bool isHiddenPosts,
    required UsersResponse? usersResponse,
    required RestrictedUsersResponse? restrictedResponse,
    required HiddenPostsResponse? hiddenPostsResponse,
    required List<ModerationReport> reports,
  }) {
    if (isReportedDuas) {
      if (reportedDuasState.isLoading && reports.isEmpty) {
        return 'Community reports on dua posts';
      }
      final openCount = reports.where((report) => report.isOpen).length;
      return '${reports.length} total · $openCount open';
    }

    if (isHiddenPosts) {
      if (hiddenPostsResponse == null) {
        return 'Dua posts hidden by moderation';
      }
      final pageLabel = _pageLabel(
        hiddenPostsState.currentPage,
        hiddenPostsState.discoveredPages,
        hiddenPostsState.hasNextToken,
      );
      return '$pageLabel${hiddenPostsResponse.posts.length} on this page · '
          '${hiddenPostsState.totalLoadedPosts} loaded';
    }

    if (isAll) {
      if (usersResponse == null) return 'Everyone registered on Emam';
      final pageLabel = _pageLabel(
        usersState.currentPage,
        usersState.discoveredPages,
        usersState.hasNextToken,
      );
      return '$pageLabel${usersResponse.users.length} on this page';
    }

    if (restrictedResponse == null) return 'Users with posting restrictions';
    final users = restrictedResponse.users;
    final temporaryCount =
        users.where((u) => u.moderation.isTemporary).length;
    final permanentCount =
        users.where((u) => u.moderation.isPermanent).length;
    final pageLabel = _pageLabel(
      restrictedState.currentPage,
      restrictedState.discoveredPages,
      restrictedState.hasNextToken,
    );
    return '$pageLabel${users.length} on this page · '
        '${restrictedResponse.totalRestricted} total restricted · '
        '$temporaryCount temporary · $permanentCount permanent';
  }

  Widget? _trailingChip({
    required bool isAll,
    required bool isReportedDuas,
    required bool isHiddenPosts,
    required UsersResponse? usersResponse,
    required RestrictedUsersResponse? restrictedResponse,
    required HiddenPostsResponse? hiddenPostsResponse,
    required int reportCount,
  }) {
    if (isAll && usersResponse != null) {
      return ContentMetaChip(label: '${usersResponse.users.length}');
    }
    if (isReportedDuas && reportCount > 0) {
      return ContentMetaChip(label: '$reportCount');
    }
    if (isHiddenPosts && hiddenPostsResponse != null) {
      return ContentMetaChip(label: '${hiddenPostsResponse.posts.length}');
    }
    if (!isAll && !isReportedDuas && !isHiddenPosts && restrictedResponse != null) {
      return ContentMetaChip(label: '${restrictedResponse.totalRestricted}');
    }
    return null;
  }

  String _pageLabel(int currentPage, int discoveredPages, bool hasNextToken) {
    if (!hasNextToken && discoveredPages <= 1) return '';
    return 'Page $currentPage · ';
  }

  Widget _buildBody(
    BuildContext context, {
    required bool isAll,
    required bool isReportedDuas,
    required bool isHiddenPosts,
    required bool isLoading,
    required String? errorMessage,
    required UsersResponse? usersResponse,
    required RestrictedUsersResponse? restrictedResponse,
    required HiddenPostsResponse? hiddenPostsResponse,
    required List<ModerationReport> reports,
  }) {
    if (isLoading) {
      return const _PanelLoading();
    }
    if (errorMessage != null) {
      return _PanelError(
        message: errorMessage,
        onRetry: isAll
            ? onUsersRetry
            : isReportedDuas
                ? onReportedDuasRetry
                : isHiddenPosts
                    ? onHiddenPostsRetry
                    : onRestrictedRetry,
      );
    }

    if (isAll) {
      return _AllUsersBody(
        response: usersResponse!,
        currentPage: usersState.currentPage,
        discoveredPages: usersState.discoveredPages,
        hasNextToken: usersState.hasNextToken,
        isLoading: usersState.isLoading,
        onPageTap: onUsersPageTap,
      );
    }

    if (isReportedDuas) {
      return _ReportedDuasBody(reports: reports);
    }

    if (isHiddenPosts) {
      return _HiddenPostsBody(
        response: hiddenPostsResponse!,
        currentPage: hiddenPostsState.currentPage,
        discoveredPages: hiddenPostsState.discoveredPages,
        hasNextToken: hiddenPostsState.hasNextToken,
        isLoading: hiddenPostsState.isLoading,
        onPageTap: onHiddenPostsPageTap,
      );
    }

    return _BlockedUsersBody(
      response: restrictedResponse!,
      currentPage: restrictedState.currentPage,
      discoveredPages: restrictedState.discoveredPages,
      hasNextToken: restrictedState.hasNextToken,
      isLoading: restrictedState.isLoading,
      onPageTap: onRestrictedPageTap,
    );
  }
}

class _AllUsersBody extends StatelessWidget {
  const _AllUsersBody({
    required this.response,
    required this.currentPage,
    required this.discoveredPages,
    required this.hasNextToken,
    required this.isLoading,
    required this.onPageTap,
  });

  final UsersResponse response;
  final int currentPage;
  final int discoveredPages;
  final bool hasNextToken;
  final bool isLoading;
  final void Function(int page) onPageTap;

  @override
  Widget build(BuildContext context) {
    final users = response.users;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (users.isEmpty)
          const _EmptyMessage('No users found.')
        else
          _UserGrid(
            itemCount: users.length,
            itemBuilder: (index) => UserCard(user: users[index]),
          ),
        UsersPaginationBar(
          currentPage: currentPage,
          discoveredPages: discoveredPages,
          hasNextToken: hasNextToken,
          isLoading: isLoading,
          onPageTap: onPageTap,
        ),
      ],
    );
  }
}

class _ReportedDuasBody extends StatelessWidget {
  const _ReportedDuasBody({required this.reports});

  final List<ModerationReport> reports;

  @override
  Widget build(BuildContext context) {
    if (reports.isEmpty) {
      return const _EmptyMessage('No reported duas found.');
    }

    return _UserGrid(
      itemCount: reports.length,
      itemBuilder: (index) => ReportedDuaCard(report: reports[index]),
    );
  }
}

class _HiddenPostsBody extends StatelessWidget {
  const _HiddenPostsBody({
    required this.response,
    required this.currentPage,
    required this.discoveredPages,
    required this.hasNextToken,
    required this.isLoading,
    required this.onPageTap,
  });

  final HiddenPostsResponse response;
  final int currentPage;
  final int discoveredPages;
  final bool hasNextToken;
  final bool isLoading;
  final void Function(int page) onPageTap;

  @override
  Widget build(BuildContext context) {
    final posts = response.posts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (posts.isEmpty)
          const _EmptyMessage('No hidden posts found.')
        else
          _UserGrid(
            itemCount: posts.length,
            itemBuilder: (index) => HiddenPostCard(post: posts[index]),
          ),
        UsersPaginationBar(
          currentPage: currentPage,
          discoveredPages: discoveredPages,
          hasNextToken: hasNextToken,
          isLoading: isLoading,
          onPageTap: onPageTap,
        ),
      ],
    );
  }
}

class _BlockedUsersBody extends StatelessWidget {
  const _BlockedUsersBody({
    required this.response,
    required this.currentPage,
    required this.discoveredPages,
    required this.hasNextToken,
    required this.isLoading,
    required this.onPageTap,
  });

  final RestrictedUsersResponse response;
  final int currentPage;
  final int discoveredPages;
  final bool hasNextToken;
  final bool isLoading;
  final void Function(int page) onPageTap;

  @override
  Widget build(BuildContext context) {
    final users = response.users;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (users.isEmpty)
          const _EmptyMessage('No blocked users found.')
        else
          _UserGrid(
            itemCount: users.length,
            itemBuilder: (index) => RestrictedUserCard(user: users[index]),
          ),
        UsersPaginationBar(
          currentPage: currentPage,
          discoveredPages: discoveredPages,
          hasNextToken: hasNextToken,
          isLoading: isLoading,
          onPageTap: onPageTap,
        ),
      ],
    );
  }
}

class _UserGrid extends StatelessWidget {
  const _UserGrid({
    required this.itemCount,
    required this.itemBuilder,
  });

  final int itemCount;
  final Widget Function(int index) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _gridColumns(constraints.maxWidth);
        const spacing = 16.0;
        final totalSpacing = spacing * (columns - 1);
        final tileWidth = (constraints.maxWidth - totalSpacing) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (var index = 0; index < itemCount; index++)
              SizedBox(
                width: tileWidth,
                child: itemBuilder(index),
              ),
          ],
        );
      },
    );
  }
}

int _gridColumns(double width) {
  if (width >= 1400) return 3;
  if (width >= 900) return 2;
  return 1;
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          message,
          style: const TextStyle(color: Colors.white54),
        ),
      ),
    );
  }
}

class _PanelLoading extends StatelessWidget {
  const _PanelLoading();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 120,
      child: Center(
        child: SizedBox(
          height: 28,
          width: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            color: AppConstants.primary,
          ),
        ),
      ),
    );
  }
}

class _PanelError extends StatelessWidget {
  const _PanelError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.white54),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.white70),
            ),
          ),
          const SizedBox(width: 12),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
