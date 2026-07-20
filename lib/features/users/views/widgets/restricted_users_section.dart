import 'package:emam_admin_web_app/features/content/views/widgets/content_section_card.dart';
import 'package:emam_admin_web_app/features/users/models/restricted_user.dart';
import 'package:emam_admin_web_app/features/users/views/widgets/restricted_user_card.dart';
import 'package:emam_admin_web_app/features/users/views/widgets/users_pagination_bar.dart';
import 'package:flutter/material.dart';

class RestrictedUsersSection extends StatelessWidget {
  const RestrictedUsersSection({
    super.key,
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
    final temporaryCount =
        users.where((u) => u.moderation.isTemporary).length;
    final permanentCount =
        users.where((u) => u.moderation.isPermanent).length;
    final pageLabel = hasNextToken || discoveredPages > 1
        ? 'Page $currentPage · '
        : '';

    return ContentSectionCard(
      title: 'Blocked Users',
      subtitle:
          '$pageLabel${users.length} on this page · '
          '${response.totalRestricted} total restricted · '
          '$temporaryCount temporary · $permanentCount permanent',
      icon: Icons.block_rounded,
      trailing: ContentMetaChip(label: '${response.totalRestricted}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (users.isEmpty)
            const _EmptyRestrictedUsers()
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = _gridColumns(constraints.maxWidth);
                const spacing = 16.0;
                final totalSpacing = spacing * (columns - 1);
                final tileWidth =
                    (constraints.maxWidth - totalSpacing) / columns;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    for (final user in users)
                      SizedBox(
                        width: tileWidth,
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: RestrictedUserCard(user: user),
                        ),
                      ),
                  ],
                );
              },
            ),
          UsersPaginationBar(
            currentPage: currentPage,
            discoveredPages: discoveredPages,
            hasNextToken: hasNextToken,
            isLoading: isLoading,
            onPageTap: onPageTap,
          ),
        ],
      ),
    );
  }
}

class _EmptyRestrictedUsers extends StatelessWidget {
  const _EmptyRestrictedUsers();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Text(
          'No blocked users found.',
          style: TextStyle(color: Colors.white54),
        ),
      ),
    );
  }
}

int _gridColumns(double width) {
  if (width >= 720) return 2;
  return 1;
}
