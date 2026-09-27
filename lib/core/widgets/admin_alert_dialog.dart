import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:flutter/material.dart';

/// Shared [AlertDialog] chrome (background, border, title style) used by
/// every confirmation/detail dialog in the admin panel. Pass [contentWidth]
/// to constrain [content] to a fixed width, as the confirmation dialogs do.
class AdminAlertDialog extends StatelessWidget {
  const AdminAlertDialog({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
    this.contentWidth,
    this.icon,
    this.accentColor = AppConstants.primary,
  });

  final String title;
  final Widget content;
  final List<Widget> actions;
  final double? contentWidth;

  /// Optional icon shown in a tinted badge beside the title, giving the
  /// dialog the same "what kind of action is this" cue as a section header.
  /// Leave unset for a plain title (the previous look).
  final IconData? icon;

  /// Tint for [icon]'s badge when [icon] is set. Pick a semantic color
  /// (danger for destructive actions, success for restorative ones, warning
  /// for cautionary ones) so the dialog reads at a glance.
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = contentWidth;
    final body = width == null
        ? content
        : SizedBox(width: width, child: content);
    final leadingIcon = icon;

    return AlertDialog(
      backgroundColor: AppConstants.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        side: BorderSide(color: AppConstants.borderColor),
      ),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      title: leadingIcon == null
          ? Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppConstants.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            )
          : Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(leadingIcon, color: accentColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: AppConstants.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
      content: body,
      actions: actions,
    );
  }
}
