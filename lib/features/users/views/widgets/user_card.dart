import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:emam_admin_web_app/features/users/models/app_user.dart';
import 'package:emam_admin_web_app/features/users/provider/user_detail_cache_provider.dart';
import 'package:emam_admin_web_app/features/users/views/widgets/user_profile_avatar.dart';
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
    final cachedDetailPhoto = ref.watch(
      userDetailCacheProvider.select(
        (state) => state.entryFor(user.id).detail?.user.photoUrl ?? '',
      ),
    );
    final photoUrl = listPhotoUrl.isNotEmpty
        ? listPhotoUrl
        : cachedDetailPhoto.trim();
    final displayName =
        user.displayName.isNotEmpty ? user.displayName : 'Unnamed user';

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
              Text(
                _updatedLabel(user.updatedAt),
                style:
                    theme.textTheme.bodySmall?.copyWith(color: Colors.white54),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _updatedLabel(DateTime? updatedAt) {
    if (updatedAt == null) return 'Last active: unknown';
    final local = updatedAt.toLocal();
    final date = '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
    return 'Last active: $date';
  }
}
