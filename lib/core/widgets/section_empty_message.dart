import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:flutter/material.dart';

/// Centered placeholder shown in place of a list/grid when it has no items
/// to display. Defaults to the app's standard muted style and icon; pass
/// [style] to match a specific section's typography or [icon] to swap the
/// glyph for something more specific.
class SectionEmptyMessage extends StatelessWidget {
  const SectionEmptyMessage(
    this.message, {
    super.key,
    this.style,
    this.icon = Icons.inbox_rounded,
  });

  final String message;
  final TextStyle? style;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Icon(
                icon,
                size: 26,
                color: AppConstants.primary.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: style ?? const TextStyle(color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }
}
