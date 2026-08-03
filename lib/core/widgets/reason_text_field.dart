import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:flutter/material.dart';

/// Multiline "Reason" text field used by moderation confirmation dialogs
/// (block user, hide post) that require the admin to justify the action.
class ReasonTextField extends StatelessWidget {
  const ReasonTextField({
    super.key,
    required this.controller,
    required this.enabled,
    this.onChanged,
  });

  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      maxLines: 3,
      style: const TextStyle(color: AppConstants.textPrimary),
      cursorColor: AppConstants.primary,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: 'Reason',
        labelStyle: const TextStyle(color: AppConstants.textSecondary),
        filled: true,
        fillColor: AppConstants.inputFillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          borderSide: BorderSide(color: AppConstants.borderColorStrong),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          borderSide: BorderSide(color: AppConstants.borderColorStrong),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          borderSide: const BorderSide(color: AppConstants.primary, width: 1.5),
        ),
      ),
    );
  }
}
