import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:emam_admin_web_app/core/utils/formatters.dart';
import 'package:emam_admin_web_app/core/widgets/pill_action_button.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final listPhotoUrl = user.photoUrl.trim();
    final cachedDetail = ref.watch(
      userDetailCacheProvider.select((state) => state.entryFor(user.id).detail),
    );
    final listModeration = ref.watch(
      restrictedModerationByUserIdProvider,
    )[user.id];
    final cachedDetailPhoto = cachedDetail?.user.photoUrl ?? '';
    final photoUrl = listPhotoUrl.isNotEmpty
        ? listPhotoUrl
        : cachedDetailPhoto.trim();
    final displayName = user.displayName.isNotEmpty
        ? user.displayName
        : 'Unnamed user';
    final isRestricted = _resolveIsRestricted(
      user,
      cachedDetail,
      listModeration,
    );
    final restrictedUntil = _resolveRestrictedUntil(
      user,
      cachedDetail,
      listModeration,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: AppConstants.cardDecoration,
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
                            color: AppConstants.textSecondary,
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
                        color: AppConstants.textMuted,
                      ),
                    ),
                  ),
                  if (isRestricted)
                    PillActionButton(
                      icon: Icons.lock_open_rounded,
                      label: 'Unblock',
                      color: AppConstants.success,
                      onPressed: () => _onUnblockPressed(
                        context,
                        ref,
                        displayName: displayName,
                        restrictedUntil: restrictedUntil,
                      ),
                    )
                  else
                    PillActionButton(
                      icon: Icons.block_rounded,
                      label: 'Block',
                      color: AppConstants.danger,
                      onPressed: () => _onBlockPressed(
                        context,
                        ref,
                        displayName: displayName,
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

    showRestrictionSnackBar(context, displayName: displayName, blocked: true);
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

    showRestrictionSnackBar(context, displayName: displayName, blocked: false);
    await refreshAfterUserRestrictionChange(ref, userId: user.id);
  }

  String _updatedLabel(DateTime? updatedAt) =>
      'Last active: ${formatAdminDate(updatedAt)}';
}
