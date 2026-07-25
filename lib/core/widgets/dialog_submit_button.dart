import 'package:flutter/material.dart';

/// Submit action for a confirmation dialog: shows [label] normally, and a
/// small spinner in its place while [isSubmitting] is true. Disabled
/// (grayed out, no tap) whenever [enabled] is false.
class DialogSubmitButton extends StatelessWidget {
  const DialogSubmitButton({
    super.key,
    required this.label,
    required this.color,
    required this.enabled,
    required this.isSubmitting,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final bool enabled;
  final bool isSubmitting;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: enabled ? onPressed : null,
      style: TextButton.styleFrom(foregroundColor: color),
      child: isSubmitting
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label),
    );
  }
}
