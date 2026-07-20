import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:emam_admin_web_app/features/content/views/widgets/content_section_card.dart';
import 'package:emam_admin_web_app/features/users/models/app_user.dart';
import 'package:emam_admin_web_app/features/users/models/user_detail.dart';
import 'package:emam_admin_web_app/features/users/provider/user_detail_cache_provider.dart';
import 'package:emam_admin_web_app/features/users/views/widgets/user_profile_avatar.dart';
import 'package:emam_admin_web_app/features/users/views/widgets/users_pagination_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

String _formatDetailDate(DateTime? date) {
  if (date == null) return 'unknown';
  final local = date.toLocal();
  return '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')} '
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}

String _titleCaseLabel(String value) {
  if (value.isEmpty) return '—';
  return value[0].toUpperCase() + value.substring(1).toLowerCase();
}

double _dialogMaxWidth(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width >= 1280) return 1000;
  if (width >= 960) return 880;
  if (width >= 720) return (width * 0.9).clamp(560, 820);
  return (width * 0.92).clamp(320, 640);
}

EdgeInsets _dialogInsetPadding(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  final horizontal = width >= 960 ? 40.0 : 20.0;
  return EdgeInsets.symmetric(horizontal: horizontal, vertical: 24);
}

Future<void> showUserDetailDialog(
  BuildContext context, {
  required String userId,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.65),
    builder: (context) => UserDetailDialog(userId: userId),
  );
}

class UserDetailDialog extends ConsumerStatefulWidget {
  const UserDetailDialog({super.key, required this.userId});

  final String userId;

  @override
  ConsumerState<UserDetailDialog> createState() => _UserDetailDialogState();
}

class _UserDetailDialogState extends ConsumerState<UserDetailDialog> {
  int _postCurrentPage = 1;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(userDetailCacheProvider.notifier).ensureLoaded(widget.userId),
    );
  }

  UserDetailCacheEntry _entry(WidgetRef ref) =>
      ref.watch(userDetailCacheProvider).entryFor(widget.userId);

  int _discoveredPostPages(UserDetailCacheEntry entry) => entry.postPages.length;

  UserRecentPostsPage? _currentPostsPage(UserDetailCacheEntry entry) {
    final pages = entry.postPages;
    if (pages.isEmpty) return null;
    final pageIndex = _postCurrentPage.clamp(1, pages.length);
    return pages[pageIndex - 1];
  }

  Future<void> _goToPostPage(UserDetailCacheEntry entry, int page) async {
    if (page < 1) return;
    if (page <= entry.postPages.length) {
      if (page != _postCurrentPage) {
        setState(() => _postCurrentPage = page);
      }
      return;
    }
    if (page == entry.postPages.length + 1 && entry.hasNextPostToken) {
      await ref
          .read(userDetailCacheProvider.notifier)
          .fetchNextPostPage(widget.userId);
      if (!mounted) return;
      final updated = ref.read(userDetailCacheProvider).entryFor(widget.userId);
      setState(() => _postCurrentPage = updated.postPages.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    final entry = _entry(ref);
    final theme = Theme.of(context);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.88;
    final dialogWidth = _dialogMaxWidth(context);
    final isLoading = entry.isLoading && !entry.hasDetail;
    final errorMessage = entry.errorMessage;
    final detail = entry.detail;

    return Dialog(
      backgroundColor: AppConstants.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      insetPadding: _dialogInsetPadding(context),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: maxHeight,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppConstants.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person_outline_rounded,
                      color: AppConstants.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'User details',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: AppConstants.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFF1E1E20)),
            Flexible(
              child: isLoading
                  ? const _DialogLoading()
                  : errorMessage != null && detail == null
                      ? _DialogError(
                          message: errorMessage,
                          onRetry: () => ref
                              .read(userDetailCacheProvider.notifier)
                              .retry(widget.userId),
                        )
                      : _buildContent(context, entry, detail!),
            ),
            const Divider(height: 1, color: Color(0xFF1E1E20)),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    UserDetailCacheEntry entry,
    UserDetailResponse detail,
  ) {
    final user = detail.user;
    final displayName =
        user.displayName.isNotEmpty ? user.displayName : 'Unnamed user';
    final postsPage = _currentPostsPage(entry);
    final errorMessage = entry.errorMessage;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 760;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!detail.found)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB74D).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFFFB74D).withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      'User record was not found on the server.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFFFFB74D),
                          ),
                    ),
                  ),
                ),
              _ProfileHeader(user: user, displayName: displayName, isWide: isWide),
              const SizedBox(height: 24),
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _DetailSectionCard(
                        icon: Icons.shield_outlined,
                        title: 'Moderation',
                        child: _InfoGrid(
                          maxWidth: (constraints.maxWidth - 32) / 3,
                          items: _moderationItems(detail),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _DetailSectionCard(
                        icon: Icons.insights_outlined,
                        title: 'Activity stats',
                        child: _InfoGrid(
                          maxWidth: (constraints.maxWidth - 32) / 3,
                          items: _activityItems(detail),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _DetailSectionCard(
                        icon: Icons.menu_book_outlined,
                        title: 'Recitation',
                        child: _InfoGrid(
                          maxWidth: (constraints.maxWidth - 32) / 3,
                          items: _recitationItems(detail),
                        ),
                      ),
                    ),
                  ],
                )
              else ...[
                _DetailSectionCard(
                  icon: Icons.shield_outlined,
                  title: 'Moderation',
                  child: _InfoGrid(
                    maxWidth: constraints.maxWidth,
                    items: _moderationItems(detail),
                  ),
                ),
                const SizedBox(height: 16),
                _DetailSectionCard(
                  icon: Icons.insights_outlined,
                  title: 'Activity stats',
                  child: _InfoGrid(
                    maxWidth: constraints.maxWidth,
                    items: _activityItems(detail),
                  ),
                ),
                const SizedBox(height: 16),
                _DetailSectionCard(
                  icon: Icons.menu_book_outlined,
                  title: 'Recitation',
                  child: _InfoGrid(
                    maxWidth: constraints.maxWidth,
                    items: _recitationItems(detail),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              _DetailSectionCard(
                icon: Icons.forum_outlined,
                title: 'Recent posts',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (errorMessage != null) ...[
                      Text(
                        errorMessage,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFFE57373),
                            ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (postsPage == null || postsPage.posts.isEmpty)
                      Text(
                        'No recent posts.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white54,
                            ),
                      )
                    else
                      _RecentPostsList(
                        posts: postsPage.posts,
                        isWide: isWide,
                      ),
                    const SizedBox(height: 8),
                    UsersPaginationBar(
                      currentPage: _postCurrentPage,
                      discoveredPages: _discoveredPostPages(entry),
                      hasNextToken: entry.hasNextPostToken,
                      isLoading: entry.isLoadingMorePosts,
                      onPageTap: (page) => _goToPostPage(entry, page),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<_InfoItem> _moderationItems(UserDetailResponse detail) => [
        _InfoItem(
          label: 'Posting restriction',
          value: _titleCaseLabel(detail.moderation.postingRestriction),
        ),
        _InfoItem(
          label: 'Can post',
          value: detail.moderation.canPost ? 'Yes' : 'No',
          highlight: detail.moderation.canPost,
        ),
        _InfoItem(
          label: 'Active posts',
          value: '${detail.postCount}',
        ),
        _InfoItem(
          label: 'Hidden posts',
          value: '${detail.hiddenPostCount}',
        ),
      ];

  List<_InfoItem> _activityItems(UserDetailResponse detail) => [
        _InfoItem(
          label: 'Prayers tracked',
          value: '${detail.stats.prayersTracked}',
        ),
        _InfoItem(
          label: 'Khutbahs (AI)',
          value: '${detail.stats.khutbahsAi}',
        ),
        _InfoItem(
          label: 'Tajweed score',
          value: detail.stats.tajweedScore.toStringAsFixed(1),
        ),
        _InfoItem(
          label: 'Qari recitations',
          value: '${detail.stats.qariRecitationCount}',
        ),
      ];

  List<_InfoItem> _recitationItems(UserDetailResponse detail) => [
        _InfoItem(
          label: 'Ayahs read',
          value: '${detail.recitation.totalAyahsRead}',
        ),
        _InfoItem(
          label: 'Overall progress',
          value:
              '${(detail.recitation.overallPercent * 100).toStringAsFixed(2)}%',
        ),
        _InfoItem(
          label: 'Surahs started',
          value: '${detail.recitation.surahsStarted}',
        ),
        _InfoItem(
          label: 'Surahs completed',
          value: '${detail.recitation.surahsCompleted}',
        ),
      ];
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.user,
    required this.displayName,
    required this.isWide,
  });

  final AppUser user;
  final String displayName;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avatarSize = isWide ? 88.0 : 72.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isWide ? 20 : 16),
      decoration: BoxDecoration(
        color: AppConstants.bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UserProfileAvatar(
                  photoUrl: user.photoUrl,
                  fallbackText: displayName,
                  size: avatarSize,
                ),
                const SizedBox(width: 20),
                Expanded(child: _profileText(context, theme)),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    UserProfileAvatar(
                      photoUrl: user.photoUrl,
                      fallbackText: displayName,
                      size: avatarSize,
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: _profileText(context, theme)),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _profileText(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          displayName,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(
              Icons.mail_outline_rounded,
              size: 16,
              color: Colors.white.withValues(alpha: 0.45),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                user.email.isNotEmpty ? user.email : 'No email',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SelectableText(
          user.id,
          style: theme.textTheme.labelSmall?.copyWith(
            color: Colors.white38,
            fontFamily: 'monospace',
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (user.location.isNotEmpty &&
                user.location.toUpperCase() != 'UNKNOWN')
              ContentMetaChip(label: user.location),
            if (user.age != null) ContentMetaChip(label: 'Age ${user.age}'),
            if ((user.gender ?? '').isNotEmpty)
              ContentMetaChip(label: user.gender!),
            ContentMetaChip(
              label: user.hasVoice ? 'Has voice' : 'No voice profile',
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 6,
          children: [
            _MetaLine(
              icon: Icons.event_available_outlined,
              label: 'Joined ${_formatDetailDate(user.createdAt)}',
            ),
            _MetaLine(
              icon: Icons.update_rounded,
              label: 'Updated ${_formatDetailDate(user.updatedAt)}',
            ),
          ],
        ),
      ],
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white38),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white54,
              ),
        ),
      ],
    );
  }
}

class _DetailSectionCard extends StatelessWidget {
  const _DetailSectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: AppConstants.bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppConstants.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppConstants.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _RecentPostsList extends StatelessWidget {
  const _RecentPostsList({required this.posts, required this.isWide});

  final List<UserRecentPost> posts;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    if (!isWide || posts.length == 1) {
      return Column(
        children: [
          for (var i = 0; i < posts.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _RecentPostTile(post: posts[i]),
          ],
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final tileWidth = (constraints.maxWidth - spacing) / 2;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final post in posts)
              SizedBox(
                width: tileWidth,
                child: _RecentPostTile(post: post),
              ),
          ],
        );
      },
    );
  }
}

class _InfoItem {
  const _InfoItem({
    required this.label,
    required this.value,
    this.highlight,
  });

  final String label;
  final String value;
  final bool? highlight;
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.items, required this.maxWidth});

  final List<_InfoItem> items;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final columns = _columnCount(maxWidth);
    const spacing = 10.0;
    final tileWidth = (maxWidth - spacing * (columns - 1)) / columns;

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: [
        for (final item in items)
          SizedBox(
            width: tileWidth,
            child: _DetailBlock(
              label: item.label,
              value: item.value,
              highlight: item.highlight,
            ),
          ),
      ],
    );
  }

  int _columnCount(double width) {
    if (width >= 520) return 2;
    return 1;
  }
}

class _DetailBlock extends StatelessWidget {
  const _DetailBlock({
    required this.label,
    required this.value,
    this.highlight,
  });

  final String label;
  final String value;
  final bool? highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valueColor = highlight == true
        ? AppConstants.primary
        : highlight == false
            ? const Color(0xFFE57373)
            : Colors.white.withValues(alpha: 0.9);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white54,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentPostTile extends StatelessWidget {
  const _RecentPostTile({required this.post});

  final UserRecentPost post;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = post.status.toLowerCase() == 'active'
        ? AppConstants.primary
        : const Color(0xFFE57373);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  post.location.isNotEmpty ? post.location : 'Unknown location',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _StatusBadge(
                label: _titleCaseLabel(post.status),
                color: statusColor,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            post.content.isNotEmpty ? post.content : 'No content',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ContentMetaChip(label: 'Ameen ${post.ameenCount}'),
              ContentMetaChip(label: 'Reports ${post.reportCount}'),
              ContentMetaChip(
                label: _formatDetailDate(post.createdAt),
              ),
            ],
          ),
          if ((post.hiddenReason ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Hidden: ${post.hiddenReason}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFFE57373),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _DialogLoading extends StatelessWidget {
  const _DialogLoading();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 200,
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

class _DialogError extends StatelessWidget {
  const _DialogError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
