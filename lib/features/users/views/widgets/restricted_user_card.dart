import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:emam_admin_web_app/core/utils/formatters.dart';
import 'package:emam_admin_web_app/core/widgets/pill_action_button.dart';
import 'package:emam_admin_web_app/core/widgets/status_badge.dart';
import 'package:emam_admin_web_app/features/content/views/widgets/content_section_card.dart';
import 'package:emam_admin_web_app/features/users/models/restricted_user.dart';
import 'package:emam_admin_web_app/features/users/provider/user_detail_cache_provider.dart';
import 'package:emam_admin_web_app/features/users/views/widgets/unblock_user_dialog.dart';
import 'package:emam_admin_web_app/features/users/views/widgets/user_profile_avatar.dart';
import 'package:emam_admin_web_app/features/users/views/widgets/user_restriction_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RestrictedUserCard extends ConsumerWidget {
  const RestrictedUserCard({super.key, required this.user, this.onTap});

  final RestrictedUser user;
  final VoidCallback? onTap;

  static const double _avatarSize = 56;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profile = user.profile;
    final cacheUserId = user.userId.isNotEmpty ? user.userId : profile.id;
    final listPhotoUrl = profile.photoUrl.trim();
    final cachedDetailPhoto = ref.watch(
      userDetailCacheProvider.select(
        (state) => state.entryFor(cacheUserId).detail?.user.photoUrl ?? '',
      ),
    );
    final photoUrl = listPhotoUrl.isNotEmpty
        ? listPhotoUrl
        : cachedDetailPhoto.trim();
    final moderation = user.moderation;
    final displayName = profile.displayName.isNotEmpty
        ? profile.displayName
        : 'Unnamed user';
    final restrictionColor = moderation.isPermanent
        ? AppConstants.danger
        : AppConstants.warning;
    final restrictionLabel = moderation.postingRestriction.isNotEmpty
        ? titleCase(moderation.postingRestriction)
        : 'Restricted';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: AppConstants.cardDecoration,
          child: Column(
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
                          profile.email.isNotEmpty ? profile.email : 'No email',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppConstants.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(label: restrictionLabel, color: restrictionColor),
                ],
              ),
              if (moderation.reason.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reason',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppConstants.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        moderation.reason,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.88),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _StatusChip(
                    icon: moderation.canPost
                        ? Icons.check_circle_outline_rounded
                        : Icons.block_rounded,
                    label: moderation.canPost ? 'Can post' : 'Cannot post',
                    color: moderation.canPost
                        ? AppConstants.primary
                        : AppConstants.danger,
                  ),
                  if (moderation.restrictedUntil != null)
                    _StatusChip(
                      icon: Icons.schedule_rounded,
                      label:
                          'Until ${formatAdminDate(moderation.restrictedUntil)}',
                      color: restrictionColor,
                    ),
                  if ((profile.gender ?? '').isNotEmpty)
                    ContentMetaChip(label: profile.gender!),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Updated ${formatAdminDate(user.updatedAt)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppConstants.textMuted,
                      ),
                    ),
                  ),
                  PillActionButton(
                    icon: Icons.lock_open_rounded,
                    label: 'Unblock',
                    color: AppConstants.success,
                    onPressed: () => _onUnblockPressed(
                      context,
                      ref,
                      userId: cacheUserId,
                      displayName: displayName,
                      restrictedUntil: moderation.restrictedUntil,
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

  Future<void> _onUnblockPressed(
    BuildContext context,
    WidgetRef ref, {
    required String userId,
    required String displayName,
    required DateTime? restrictedUntil,
  }) async {
    if (userId.isEmpty) return;

    final unblocked = await showUnblockUserDialog(
      context,
      userId: userId,
      displayName: displayName,
      restrictedUntil: restrictedUntil,
    );
    if (unblocked != true || !context.mounted) return;

    showRestrictionSnackBar(context, displayName: displayName, blocked: false);
    await refreshAfterUserRestrictionChange(ref, userId: userId);
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
