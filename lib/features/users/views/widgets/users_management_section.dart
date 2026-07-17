import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:emam_admin_web_app/features/content/views/widgets/content_section_card.dart';
import 'package:emam_admin_web_app/features/users/models/app_user.dart';
import 'package:emam_admin_web_app/features/users/models/restricted_user.dart';
import 'package:emam_admin_web_app/features/users/provider/restricted_users_provider.dart';
import 'package:emam_admin_web_app/features/users/provider/users_provider.dart';
import 'package:emam_admin_web_app/features/users/views/widgets/restricted_user_card.dart';
import 'package:emam_admin_web_app/features/users/views/widgets/user_card.dart';
import 'package:emam_admin_web_app/features/users/views/widgets/users_pagination_bar.dart';
import 'package:flutter/material.dart';

enum UsersTab { all, blocked }

class UsersManagementSection extends StatelessWidget {
  const UsersManagementSection({
    super.key,
    required this.selectedTab,
    required this.usersState,
    required this.restrictedState,
    required this.onUsersRetry,
    required this.onUsersPageTap,
    required this.onRestrictedRetry,
    required this.onRestrictedPageTap,
  });

  final UsersTab selectedTab;
  final UsersPageState usersState;
  final RestrictedUsersPageState restrictedState;
  final Future<void> Function() onUsersRetry;
  final void Function(int page) onUsersPageTap;
  final Future<void> Function() onRestrictedRetry;
  final void Function(int page) onRestrictedPageTap;

  bool get _showAll => selectedTab == UsersTab.all;

  @override
  Widget build(BuildContext context) {
    final isAll = _showAll;
    final usersResponse = usersState.currentResponse;
    final restrictedResponse = restrictedState.currentResponse;
    final isLoading = isAll
        ? usersState.isLoading && usersResponse == null
        : restrictedState.isLoading && restrictedResponse == null;
    final errorMessage = isAll
        ? usersState.errorMessage
        : restrictedState.errorMessage;

    return ContentSectionCard(
      title: isAll ? 'All Users' : 'Blocked Users',
      subtitle: _subtitle(
        isAll: isAll,
        usersResponse: usersResponse,
        restrictedResponse: restrictedResponse,
      ),
      icon: isAll ? Icons.people_alt_rounded : Icons.block_rounded,
      trailing: _trailingChip(
        isAll: isAll,
        usersResponse: usersResponse,
        restrictedResponse: restrictedResponse,
      ),
      child: _buildBody(
        context,
        isAll: isAll,
        isLoading: isLoading,
        errorMessage: errorMessage,
        usersResponse: usersResponse,
        restrictedResponse: restrictedResponse,
      ),
    );
  }

  String _subtitle({
    required bool isAll,
    required UsersResponse? usersResponse,
    required RestrictedUsersResponse? restrictedResponse,
  }) {
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
    required UsersResponse? usersResponse,
    required RestrictedUsersResponse? restrictedResponse,
  }) {
    if (isAll && usersResponse != null) {
      return ContentMetaChip(label: '${usersResponse.users.length}');
    }
    if (!isAll && restrictedResponse != null) {
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
    required bool isLoading,
    required String? errorMessage,
    required UsersResponse? usersResponse,
    required RestrictedUsersResponse? restrictedResponse,
  }) {
    if (isLoading) {
      return const _PanelLoading();
    }
    if (errorMessage != null) {
      return _PanelError(
        message: errorMessage,
        onRetry: isAll ? onUsersRetry : onRestrictedRetry,
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
