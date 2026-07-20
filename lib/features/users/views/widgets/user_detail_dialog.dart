import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:emam_admin_web_app/core/network/api_error.dart';
import 'package:emam_admin_web_app/core/utils/image_proxy.dart';
import 'package:emam_admin_web_app/features/content/views/widgets/content_section_card.dart';
import 'package:emam_admin_web_app/features/users/models/user_detail.dart';
import 'package:emam_admin_web_app/features/users/provider/users_repository_provider.dart';
import 'package:emam_admin_web_app/features/users/views/widgets/users_pagination_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const int _kUserDetailPostsPageSize = 10;

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
  UserDetailResponse? _detail;
  final List<UserRecentPostsPage> _postPages = [];
  int _postCurrentPage = 1;
  bool _isLoading = true;
  bool _isPostsLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadInitial);
  }

  int get _discoveredPostPages => _postPages.length;

  bool get _hasNextPostToken =>
      _postPages.isNotEmpty && (_postPages.last.nextPageToken ?? '').isNotEmpty;

  UserRecentPostsPage? get _currentPostsPage {
    if (_postPages.isEmpty ||
        _postCurrentPage < 1 ||
        _postCurrentPage > _postPages.length) {
      return null;
    }
    return _postPages[_postCurrentPage - 1];
  }

  Future<void> _loadInitial() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final repo = ref.read(usersRepositoryProvider);
      final detail = await repo.fetchUserDetail(
        widget.userId,
        limit: _kUserDetailPostsPageSize,
      );
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _postPages
          ..clear()
          ..add(detail.recentPosts);
        _postCurrentPage = 1;
        _isLoading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = parseApiError(e);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load user details. Please try again.';
      });
    }
  }

  Future<void> _goToPostPage(int page) async {
    if (page < 1) return;
    if (page <= _postPages.length) {
      if (page != _postCurrentPage) {
        setState(() => _postCurrentPage = page);
      }
      return;
    }
    if (page == _postPages.length + 1 && _hasNextPostToken) {
      await _fetchNextPostPage();
    }
  }

  Future<void> _fetchNextPostPage() async {
    final token = _postPages.last.nextPageToken;
    setState(() {
      _isPostsLoading = true;
      _errorMessage = null;
    });
    try {
      final repo = ref.read(usersRepositoryProvider);
      final detail = await repo.fetchUserDetail(
        widget.userId,
        pageToken: token,
        limit: _kUserDetailPostsPageSize,
      );
      if (!mounted) return;
      setState(() {
        _postPages.add(detail.recentPosts);
        _postCurrentPage = _postPages.length;
        _isPostsLoading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _isPostsLoading = false;
        _errorMessage = parseApiError(e);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isPostsLoading = false;
        _errorMessage = 'Failed to load more posts. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.82;
    final maxWidth = MediaQuery.sizeOf(context).width * 0.92;

    return Dialog(
      backgroundColor: AppConstants.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth.clamp(320, 640),
          maxHeight: maxHeight,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
              child: Row(
                children: [
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
              child: _isLoading
                  ? const _DialogLoading()
                  : _errorMessage != null && _detail == null
                      ? _DialogError(
                          message: _errorMessage!,
                          onRetry: _loadInitial,
                        )
                      : _buildContent(context),
            ),
            const Divider(height: 1, color: Color(0xFF1E1E20)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final detail = _detail!;
    final user = detail.user;
    final displayName =
        user.displayName.isNotEmpty ? user.displayName : 'Unnamed user';
    final postsPage = _currentPostsPage;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!detail.found)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'User record was not found on the server.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFFFFB74D),
                    ),
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DialogAvatar(url: user.photoUrl, fallbackText: displayName),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email.isNotEmpty ? user.email : 'No email',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      user.id,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.white38,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
          const SizedBox(height: 8),
          Text(
            'Joined: ${_formatDetailDate(user.createdAt)} · '
            'Updated: ${_formatDetailDate(user.updatedAt)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white54,
                ),
          ),
          const SizedBox(height: 20),
          _SectionTitle('Moderation'),
          const SizedBox(height: 10),
          _InfoGrid(
            items: [
              _InfoItem(
                label: 'Posting restriction',
                value: _titleCaseLabel(detail.moderation.postingRestriction),
              ),
              _InfoItem(
                label: 'Can post',
                value: detail.moderation.canPost ? 'Yes' : 'No',
              ),
              _InfoItem(
                label: 'Active posts',
                value: '${detail.postCount}',
              ),
              _InfoItem(
                label: 'Hidden posts',
                value: '${detail.hiddenPostCount}',
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SectionTitle('Activity stats'),
          const SizedBox(height: 10),
          _InfoGrid(
            items: [
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
            ],
          ),
          const SizedBox(height: 20),
          _SectionTitle('Recitation'),
          const SizedBox(height: 10),
          _InfoGrid(
            items: [
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
            ],
          ),
          const SizedBox(height: 20),
          _SectionTitle('Recent posts'),
          if (_errorMessage != null && _detail != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFFE57373),
                  ),
            ),
          ],
          const SizedBox(height: 10),
          if (postsPage == null || postsPage.posts.isEmpty)
            Text(
              'No recent posts.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white54,
                  ),
            )
          else
            Column(
              children: [
                for (final post in postsPage.posts) ...[
                  _RecentPostTile(post: post),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          UsersPaginationBar(
            currentPage: _postCurrentPage,
            discoveredPages: _discoveredPostPages,
            hasNextToken: _hasNextPostToken,
            isLoading: _isPostsLoading,
            onPageTap: _goToPostPage,
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppConstants.primary,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

class _InfoItem {
  const _InfoItem({required this.label, required this.value});

  final String label;
  final String value;
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.items});

  final List<_InfoItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 480 ? 2 : 1;
        const spacing = 10.0;
        final tileWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final item in items)
              SizedBox(
                width: tileWidth,
                child: _DetailBlock(label: item.label, value: item.value),
              ),
          ],
        );
      },
    );
  }
}

class _DetailBlock extends StatelessWidget {
  const _DetailBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstants.bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white54,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.88),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstants.bgColor,
        borderRadius: BorderRadius.circular(10),
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

class _DialogAvatar extends StatelessWidget {
  const _DialogAvatar({required this.url, required this.fallbackText});

  final String url;
  final String fallbackText;

  static const double _size = 64;

  @override
  Widget build(BuildContext context) {
    final initial = fallbackText.trim().isNotEmpty
        ? fallbackText.trim()[0].toUpperCase()
        : '?';

    final fallback = Container(
      color: AppConstants.primary.withValues(alpha: 0.15),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppConstants.primary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(_size / 2),
      child: SizedBox(
        width: _size,
        height: _size,
        child: url.isEmpty
            ? fallback
            : CachedNetworkImage(
                imageUrl: proxiedImageUrl(
                  url,
                  width: (_size * 2).toInt(),
                  height: (_size * 2).toInt(),
                ),
                fit: BoxFit.cover,
                placeholder: (_, _) => Container(
                  color: AppConstants.inputFillColor,
                  alignment: Alignment.center,
                  child: const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppConstants.primary,
                    ),
                  ),
                ),
                errorWidget: (_, _, _) => fallback,
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
