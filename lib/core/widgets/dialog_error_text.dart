import 'package:flutter/material.dart';

/// Inline error message shown inside a dialog's content, in the app's
/// standard danger color.
class DialogErrorText extends StatelessWidget {
  const DialogErrorText(this.message, {super.key});

  final String message;

  static const Color _danger = Color(0xFFE57373);

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: _danger),
    );
  }
}
