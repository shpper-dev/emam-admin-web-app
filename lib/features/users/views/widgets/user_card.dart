import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:emam_admin_web_app/features/users/models/app_user.dart';
import 'package:emam_admin_web_app/features/users/models/user_detail.dart';
import 'package:emam_admin_web_app/features/users/models/restricted_user.dart';
import 'package:emam_admin_web_app/features/users/provider/restricted_users_provider.dart';
import 'package:emam_admin_web_app/features/users/provider/user_detail_cache_provider.dart';
import 'package:emam_admin_web_app/features/users/utils/user_moderation_display.dart';
import 'package:emam_admin_web_app/features/users/views/widgets/block_user_dialog.dart';
import 'package:emam_admin_web_app/features/users/views/widgets/unblock_user_dialog.dart';
import 'package:emam_admin_web_app/features/users/views/widgets/user_profile_avatar.dart';
import 'package:emam_admin_web_app/features/users/views/widgets/user_restriction_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserCard extends ConsumerWidget {
  const UserCard({super.key, required this.user, this.onTap});

  final AppUser user;
  final VoidCallback? onTap;

  static const double _avatarSize = 56;
  static const Color _danger = Color(0xFFE57373);
  static const Color _unblockGreen = Color(0xFF66BB6A);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final listPhotoUrl = user.photoUrl.trim();
    final cachedDetail = ref.watch(
      userDetailCacheProvider.select(
        (state) => state.entryFor(user.id).detail,
      ),
    );
    final listModeration =
        ref.watch(restrictedModerationByUserIdProvider)[user.id];
    final cachedDetailPhoto = cachedDetail?.user.photoUrl ?? '';
    final photoUrl = listPhotoUrl.isNotEmpty
        ? listPhotoUrl
        : cachedDetailPhoto.trim();
    final displayName = user.displayName.isNotEmpty
        ? user.displayName
        : 'Unnamed user';
    final isRestricted =
        _resolveIsRestricted(user, cachedDetail, listModeration);
    final restrictedUntil =
        _resolveRestrictedUntil(user, cachedDetail, listModeration);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppConstants.bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UserProfileAvatar(
                    photoUrl: photoUrl,
                    fallbackText: displayName,
                    size: _avatarSize,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email.isNotEmpty ? user.email : 'No email',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _updatedLabel(user.updatedAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white54,
                      ),
                    ),
                  ),
                  if (isRestricted)
                    TextButton.icon(
                      onPressed: () => _onUnblockPressed(
                        context,
                        ref,
                        displayName: displayName,
                        restrictedUntil: restrictedUntil,
                      ),
                      icon: const Icon(Icons.lock_open_rounded, size: 18),
                      label: const Text('Unblock'),
                      style: TextButton.styleFrom(
                        foregroundColor: _unblockGreen,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 12,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        side: BorderSide(
                          color: _unblockGreen.withValues(alpha: 0.55),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    )
                  else
                    TextButton.icon(
                      onPressed: () => _onBlockPressed(
                        context,
                        ref,
                        displayName: displayName,
                      ),
                      icon: const Icon(Icons.block_rounded, size: 18),
                      label: const Text('Block'),
                      style: TextButton.styleFrom(
                        foregroundColor: _danger,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 12,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        side: BorderSide(color: _danger.withValues(alpha: 0.55)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _resolveIsRestricted(
    AppUser user,
    UserDetailResponse? detail,
    UserModeration? listModeration,
  ) {
    if (listModeration != null &&
        isUserPostingRestricted(
          canPost: listModeration.canPost,
          postingRestriction: listModeration.postingRestriction,
        )) {
      return true;
    }
    if (isUserPostingRestricted(
      canPost: user.canPost,
      postingRestriction: user.postingRestriction,
    )) {
      return true;
    }
    final moderation = detail?.moderation;
    if (moderation == null) return false;
    return isUserPostingRestricted(
      canPost: moderation.canPost,
      postingRestriction: moderation.postingRestriction,
    );
  }

  DateTime? _resolveRestrictedUntil(
    AppUser user,
    UserDetailResponse? detail,
    UserModeration? listModeration,
  ) {
    if (listModeration?.restrictedUntil != null) {
      return listModeration!.restrictedUntil;
    }
    if (user.restrictedUntil != null) return user.restrictedUntil;
    return detail?.moderation.restrictedUntil;
  }

  Future<void> _onBlockPressed(
    BuildContext context,
    WidgetRef ref, {
    required String displayName,
  }) async {
    final blocked = await showBlockUserDialog(
      context,
      userId: user.id,
      displayName: displayName,
    );
    if (blocked != true || !context.mounted) return;

    showRestrictionSnackBar(
      context,
      displayName: displayName,
      blocked: true,
    );
    await refreshAfterUserRestrictionChange(ref, userId: user.id);
  }

  Future<void> _onUnblockPressed(
    BuildContext context,
    WidgetRef ref, {
    required String displayName,
    required DateTime? restrictedUntil,
  }) async {
    final unblocked = await showUnblockUserDialog(
      context,
      userId: user.id,
      displayName: displayName,
      restrictedUntil: restrictedUntil,
    );
    if (unblocked != true || !context.mounted) return;

    showRestrictionSnackBar(
      context,
      displayName: displayName,
      blocked: false,
    );
    await refreshAfterUserRestrictionChange(ref, userId: user.id);
  }

  String _updatedLabel(DateTime? updatedAt) {
    if (updatedAt == null) return 'Last active: unknown';
    final local = updatedAt.toLocal();
    final date =
        '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
    return 'Last active: $date';
  }
}
