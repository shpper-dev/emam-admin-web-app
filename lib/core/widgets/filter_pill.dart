import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:flutter/material.dart';

/// Selectable pill used for list filters.
class FilterPill extends StatelessWidget {
  const FilterPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppConstants.primary : AppConstants.textSecondary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppConstants.radiusPill),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? AppConstants.primary.withValues(alpha: 0.14)
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(AppConstants.radiusPill),
            border: Border.all(
              color: selected
                  ? AppConstants.primary.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
