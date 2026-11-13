import 'package:emam_admin_web_app/core/widgets/section_empty_message.dart';
import 'package:emam_admin_web_app/features/content/views/widgets/content_section_card.dart';
import 'package:emam_admin_web_app/features/users/models/app_user.dart';
import 'package:emam_admin_web_app/features/users/views/widgets/user_card.dart';
import 'package:emam_admin_web_app/features/users/views/widgets/users_pagination_bar.dart';
import 'package:flutter/material.dart';

class UsersSection extends StatelessWidget {
  const UsersSection({
    super.key,
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
    final pageLabel = hasNextToken || discoveredPages > 1
        ? 'Page $currentPage · '
        : '';

    return ContentSectionCard(
      title: 'All Users',
      subtitle: '$pageLabel${users.length} on this page',
      icon: Icons.people_alt_rounded,
      trailing: ContentMetaChip(label: '${users.length}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (users.isEmpty)
            const SectionEmptyMessage(
              'No users found.',
              hint: 'Try refreshing, or search by name or email.',
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = _userGridColumns(constraints.maxWidth);
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
                          child: UserCard(user: user),
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

int _userGridColumns(double width) {
  if (width >= 720) return 2;
  return 1;
}
