import 'package:cached_network_image/cached_network_image.dart';
import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:emam_admin_web_app/core/utils/image_proxy.dart';
import 'package:emam_admin_web_app/features/content/views/widgets/content_section_card.dart';
import 'package:emam_admin_web_app/features/users/models/restricted_user.dart';
import 'package:flutter/material.dart';

class RestrictedUserCard extends StatelessWidget {
  const RestrictedUserCard({super.key, required this.user});

  final RestrictedUser user;

  static const double _avatarSize = 56;
  static const Color _danger = Color(0xFFE57373);
  static const Color _warning = Color(0xFFFFB74D);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = user.profile;
    final moderation = user.moderation;
    final displayName =
        profile.displayName.isNotEmpty ? profile.displayName : 'Unnamed user';
    final restrictionColor =
        moderation.isPermanent ? _danger : _warning;
    final restrictionLabel = moderation.postingRestriction.isNotEmpty
        ? _titleCase(moderation.postingRestriction)
        : 'Restricted';

    return Container(
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
              _Avatar(url: profile.photoUrl, fallbackText: displayName),
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
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _RestrictionBadge(
                label: restrictionLabel,
                color: restrictionColor,
              ),
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
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reason',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white54,
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
                color: moderation.canPost ? AppConstants.primary : _danger,
              ),
              if (moderation.restrictedUntil != null)
                _StatusChip(
                  icon: Icons.schedule_rounded,
                  label: 'Until ${_formatDate(moderation.restrictedUntil!)}',
                  color: restrictionColor,
                ),
              if ((profile.gender ?? '').isNotEmpty)
                ContentMetaChip(label: profile.gender!),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Updated ${_formatDate(user.updatedAt)}',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white54),
          ),
        ],
      ),
    );
  }

  static String _titleCase(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }

  static String _formatDate(DateTime? date) {
    if (date == null) return 'unknown';
    final local = date.toLocal();
    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }
}

class _RestrictionBadge extends StatelessWidget {
  const _RestrictionBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url, required this.fallbackText});

  final String url;
  final String fallbackText;

  @override
  Widget build(BuildContext context) {
    final size = RestrictedUserCard._avatarSize;
    final initial = fallbackText.trim().isNotEmpty
        ? fallbackText.trim()[0].toUpperCase()
        : '?';

    final fallback = Container(
      color: RestrictedUserCard._danger.withValues(alpha: 0.15),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: RestrictedUserCard._danger,
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
