import 'package:flutter/material.dart';

/// Submit action for a confirmation dialog: shows [label] normally, and a
/// small spinner in its place while [isSubmitting] is true. Disabled
/// (grayed out, no tap) whenever [enabled] is false. Filled with a tint of
/// [color] so it reads as the primary action next to a plain "Cancel".
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
      style: TextButton.styleFrom(
        foregroundColor: color,
        backgroundColor: color.withValues(alpha: 0.12),
        disabledBackgroundColor: color.withValues(alpha: 0.04),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
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
