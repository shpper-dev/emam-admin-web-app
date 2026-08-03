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
  });

  final String title;
  final Widget content;
  final List<Widget> actions;
  final double? contentWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = contentWidth;
    final body = width == null
        ? content
        : SizedBox(width: width, child: content);

    return AlertDialog(
      backgroundColor: AppConstants.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        side: BorderSide(color: AppConstants.borderColor),
      ),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      title: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          color: AppConstants.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: body,
      actions: actions,
    );
  }
}
