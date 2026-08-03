import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:flutter/material.dart';

/// Small outlined icon+label button used for card-level moderation actions
/// (block/unblock, hide/restore). Pass `onPressed: null` to disable it.
class PillActionButton extends StatelessWidget {
  const PillActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 17),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      style: TextButton.styleFrom(
        foregroundColor: color,
        backgroundColor: color.withValues(alpha: 0.08),
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.space12,
          vertical: AppConstants.space12,
        ),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        side: BorderSide(color: color.withValues(alpha: 0.4)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusSm),
        ),
      ),
    );
  }
}
