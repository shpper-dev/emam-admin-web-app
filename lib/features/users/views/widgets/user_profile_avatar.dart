import 'package:cached_network_image/cached_network_image.dart';
import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:emam_admin_web_app/core/utils/image_proxy.dart';
import 'package:flutter/material.dart';

/// Circular profile image; shows [CachedNetworkImage] when [photoUrl] is set.
class UserProfileAvatar extends StatefulWidget {
  const UserProfileAvatar({
    super.key,
    required this.photoUrl,
    required this.fallbackText,
    this.size = 56,
  });

  final String photoUrl;
  final String fallbackText;
  final double size;

  @override
  State<UserProfileAvatar> createState() => _UserProfileAvatarState();
}

class _UserProfileAvatarState extends State<UserProfileAvatar> {
  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final url = widget.photoUrl.trim();
    final fallback = _initialFallback(context, size);

    if (url.isEmpty) {
      return _framed(size, fallback);
    }

    // The photo URL is end-user supplied: only ever load it through the proxy
    // (or a trusted Google host), never fall back to fetching it directly.
    final imageUrl = proxiedImageUrl(
      url,
      width: (size * 2).toInt(),
      height: (size * 2).toInt(),
    );

    return _framed(
      size,
      CachedNetworkImage(
        key: ValueKey(imageUrl),
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        placeholder: (_, _) => Container(
          color: AppConstants.inputFillColor,
          alignment: Alignment.center,
          child: SizedBox(
            height: size * 0.32,
            width: size * 0.32,
            child: const CircularProgressIndicator(
              strokeWidth: 2,
              color: AppConstants.primary,
            ),
          ),
        ),
        errorWidget: (_, _, _) => fallback,
      ),
    );
  }

  Widget _framed(double size, Widget child) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 2),
      child: SizedBox(width: size, height: size, child: child),
    );
  }

  Widget _initialFallback(BuildContext context, double size) {
    final initial = widget.fallbackText.trim().isNotEmpty
        ? widget.fallbackText.trim()[0].toUpperCase()
        : '?';

    return Container(
      color: AppConstants.primary.withValues(alpha: 0.15),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: AppConstants.primary,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.4,
        ),
      ),
    );
  }
}
