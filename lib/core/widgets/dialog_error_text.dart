import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:flutter/material.dart';

/// Inline error message shown inside a dialog's content, in the app's
/// standard danger color.
class DialogErrorText extends StatelessWidget {
  const DialogErrorText(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: AppConstants.danger),
    );
  }
}
