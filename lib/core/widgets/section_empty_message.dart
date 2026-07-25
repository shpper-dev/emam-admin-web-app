import 'package:flutter/material.dart';

/// Centered placeholder text shown in place of a list/grid when it has no
/// items to display. Defaults to the app's standard muted style; pass
/// [style] to match a specific section's typography.
class SectionEmptyMessage extends StatelessWidget {
  const SectionEmptyMessage(this.message, {super.key, this.style});

  final String message;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          message,
          style: style ?? const TextStyle(color: Colors.white54),
        ),
      ),
    );
  }
}
