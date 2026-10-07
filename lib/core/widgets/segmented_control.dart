import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:flutter/material.dart';

class SegmentOption<T> {
  const SegmentOption({
    required this.value,
    required this.label,
    required this.icon,
    this.count,
    this.countColor,
  });

  final T value;
  final String label;
  final IconData icon;

  /// Optional badge text (e.g. "12" or "50+"); hidden when null.
  final String? count;
  final Color? countColor;
}

/// Equal-width, single-select control for switching between views of the same
/// data. The selected segment is filled; counts show without switching.
class SegmentedControl<T> extends StatelessWidget {
  const SegmentedControl({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final List<SegmentOption<T>> options;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
            border: Border.all(color: AppConstants.borderColor),
          ),
          child: Row(
            children: [
              for (final option in options)
                Expanded(
                  child: _Segment<T>(
                    option: option,
                    selected: option.value == selected,
                    compact: compact,
                    textStyle: theme.textTheme.labelLarge,
                    onTap: () => onChanged(option.value),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Segment<T> extends StatelessWidget {
  const _Segment({
    required this.option,
    required this.selected,
    required this.compact,
    required this.textStyle,
    required this.onTap,
  });

  final SegmentOption<T> option;
  final bool selected;
  final bool compact;
  final TextStyle? textStyle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppConstants.primary : AppConstants.textSecondary;
    final badgeColor = option.countColor ?? AppConstants.primary;
    final count = option.count;

    return Semantics(
      button: true,
      selected: selected,
      label: count == null ? option.label : '${option.label}, $count',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppConstants.radiusSm),
          onTap: onTap,
          mouseCursor: SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? AppConstants.primary.withValues(alpha: 0.16)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppConstants.radiusSm),
              border: Border.all(
                color: selected
                    ? AppConstants.primary.withValues(alpha: 0.5)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!compact) ...[
                  Icon(option.icon, size: 18, color: fg),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    option.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textStyle?.copyWith(
                      color: fg,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                if (count != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(
                        alpha: selected ? 0.22 : 0.14,
                      ),
                      borderRadius: BorderRadius.circular(
                        AppConstants.radiusPill,
                      ),
                    ),
                    child: Text(
                      count,
                      style: textStyle?.copyWith(
                        color: badgeColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
