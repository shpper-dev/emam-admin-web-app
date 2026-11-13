import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:flutter/material.dart';

/// The one way to confirm an action or report a failure. Shows a status icon
/// (green check or red alert) so success and error read at a glance, and
/// replaces any snackbar already on screen instead of queueing behind it.
void showAppSnackBar(
  ScaffoldMessengerState messenger,
  String message, {
  bool error = false,
  Duration duration = const Duration(seconds: 4),
}) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: duration,
        content: Row(
          children: [
            Icon(
              error ? Icons.error_outline_rounded : Icons.check_circle_rounded,
              size: 20,
              color: error ? AppConstants.danger : AppConstants.success,
            ),
            const SizedBox(width: AppConstants.space12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
}
