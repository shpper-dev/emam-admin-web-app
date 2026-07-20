import 'package:cached_network_image/cached_network_image.dart';
import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:emam_admin_web_app/core/utils/image_proxy.dart';
import 'package:emam_admin_web_app/features/content/views/widgets/content_section_card.dart';
import 'package:emam_admin_web_app/features/users/models/app_user.dart';
import 'package:flutter/material.dart';

class UserCard extends StatelessWidget {
  const UserCard({super.key, required this.user, this.onTap});

  final AppUser user;
  final VoidCallback? onTap;

  static const double _avatarSize = 56;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName =
        user.displayName.isNotEmpty ? user.displayName : 'Unnamed user';
    final hasLocation =
        user.location.isNotEmpty && user.location.toUpperCase() != 'UNKNOWN';

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Avatar(url: user.photoUrl, fallbackText: displayName),
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
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (hasLocation)
                    _UserStatusChip(
                      icon: Icons.place_outlined,
                      label: user.location,
                      active: true,
                    ),
                  if (user.age != null)
                    ContentMetaChip(label: 'Age ${user.age}'),
                  if ((user.gender ?? '').isNotEmpty)
                    ContentMetaChip(label: user.gender!),
                ],
              ),
              const SizedBox(height: 12),
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

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url, required this.fallbackText});

  final String url;
  final String fallbackText;

  @override
  Widget build(BuildContext context) {
    final size = UserCard._avatarSize;
    final initial = fallbackText.trim().isNotEmpty
        ? fallbackText.trim()[0].toUpperCase()
        : '?';

    final fallback = Container(
      color: AppConstants.primary.withValues(alpha: 0.15),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppConstants.primary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 2),
      child: SizedBox(
        width: size,
        height: size,
        child: url.isEmpty
            ? fallback
            : CachedNetworkImage(
                imageUrl: proxiedImageUrl(
                  url,
                  width: (size * 2).toInt(),
                  height: (size * 2).toInt(),
                ),
                fit: BoxFit.cover,
                placeholder: (_, _) => Container(
                  color: AppConstants.inputFillColor,
                  alignment: Alignment.center,
                  child: const SizedBox(
                    height: 18,
                    width: 18,
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

class _UserStatusChip extends StatelessWidget {
  const _UserStatusChip({
    required this.icon,
    required this.label,
    required this.active,
  });

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color =
        active ? AppConstants.primary : Colors.white.withValues(alpha: 0.55);
    final background = active
        ? AppConstants.primary.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.05);
    final borderColor = active
        ? AppConstants.primary.withValues(alpha: 0.25)
        : Colors.white.withValues(alpha: 0.12);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
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
