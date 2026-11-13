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
    this.hint,
  });

  final String message;
  final TextStyle? style;
  final IconData icon;

  /// Optional second line telling the admin what to do or what appears here.
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppConstants.primary.withValues(alpha: 0.06),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppConstants.primary.withValues(alpha: 0.16),
                ),
              ),
              child: Icon(
                icon,
                size: 26,
                color: AppConstants.primary.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: AppConstants.space16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: style ?? const TextStyle(color: AppConstants.textMuted),
            ),
            if (hint != null) ...[
              const SizedBox(height: AppConstants.space8),
              Text(
                hint!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
