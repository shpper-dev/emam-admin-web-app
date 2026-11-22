import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:flutter/material.dart';

/// Labeled value block used in moderation cards to show a single field
/// (report reason, post content, etc.) inside a subtle bordered container.
class DetailBlock extends StatelessWidget {
  const DetailBlock({
    super.key,
    required this.label,
    required this.value,
    this.selectable = false,
    this.textDirection,
    this.large = false,
  });

  final String label;
  final String value;
  final bool selectable;
  final TextDirection? textDirection;

  /// Larger type, for Arabic text where diacritics need room to read.
  final bool large;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.space12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(AppConstants.radiusSm),
        border: Border.all(color: AppConstants.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppConstants.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Builder(
            builder: (_) {
              final style =
                  (large
                          ? theme.textTheme.titleLarge
                          : theme.textTheme.bodyMedium)
                      ?.copyWith(
                        color: AppConstants.textPrimary.withValues(alpha: 0.92),
                        height: large ? 1.8 : null,
                      );
              return selectable
                  ? SelectableText(
                      value,
                      style: style,
                      textDirection: textDirection,
                    )
                  : Text(value, style: style, textDirection: textDirection);
            },
          ),
        ],
      ),
    );
  }
}
