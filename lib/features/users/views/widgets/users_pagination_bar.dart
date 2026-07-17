import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:flutter/material.dart';

/// Compact numbered pager rendered under the users grid.
///
/// - Shows `1 .. discoveredPages` as tappable numbers.
/// - Shows a trailing `…` button when the server reports another page
///   (`hasNextToken == true`); tapping it fetches page `discoveredPages + 1`.
/// - Prev/Next arrows do the same thing at the ends.
/// - The active page is highlighted; disabled buttons don't respond to taps.
class UsersPaginationBar extends StatelessWidget {
  const UsersPaginationBar({
    super.key,
    required this.currentPage,
    required this.discoveredPages,
    required this.hasNextToken,
    required this.isLoading,
    required this.onPageTap,
  });

  final int currentPage;
  final int discoveredPages;
  final bool hasNextToken;
  final bool isLoading;
  final void Function(int page) onPageTap;

  @override
  Widget build(BuildContext context) {
    if (discoveredPages <= 1 && !hasNextToken) {
      return const SizedBox.shrink();
    }

    final canGoPrev = !isLoading && currentPage > 1;
    final canGoNext =
        !isLoading && (currentPage < discoveredPages || hasNextToken);

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          _PagerButton.icon(
            icon: Icons.chevron_left_rounded,
            enabled: canGoPrev,
            onTap: () => onPageTap(currentPage - 1),
          ),
          for (int page = 1; page <= discoveredPages; page++)
            _PagerButton.number(
              label: '$page',
              selected: page == currentPage,
              enabled: !isLoading,
              onTap: () => onPageTap(page),
            ),
          if (hasNextToken)
            _PagerButton.number(
              label: '…',
              selected: false,
              enabled: !isLoading,
              onTap: () => onPageTap(discoveredPages + 1),
            ),
          _PagerButton.icon(
            icon: Icons.chevron_right_rounded,
            enabled: canGoNext,
            onTap: () => onPageTap(currentPage + 1),
          ),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppConstants.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PagerButton extends StatelessWidget {
  const _PagerButton._({
    required this.enabled,
    required this.onTap,
    required this.selected,
    this.label,
    this.icon,
  });

  factory _PagerButton.number({
    required String label,
    required bool selected,
    required bool enabled,
    required VoidCallback onTap,
  }) =>
      _PagerButton._(
        enabled: enabled,
        onTap: onTap,
        selected: selected,
        label: label,
      );

  factory _PagerButton.icon({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) =>
      _PagerButton._(
        enabled: enabled,
        onTap: onTap,
        selected: false,
        icon: icon,
      );

  final bool enabled;
  final bool selected;
  final VoidCallback onTap;
  final String? label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final Color background;
    final Color foreground;
    final Color borderColor;

    if (selected) {
      background = AppConstants.primary.withValues(alpha: 0.18);
      foreground = AppConstants.primary;
      borderColor = AppConstants.primary.withValues(alpha: 0.55);
    } else if (enabled) {
      background = Colors.white.withValues(alpha: 0.04);
      foreground = Colors.white.withValues(alpha: 0.85);
      borderColor = Colors.white.withValues(alpha: 0.12);
    } else {
      background = Colors.white.withValues(alpha: 0.02);
      foreground = Colors.white.withValues(alpha: 0.25);
      borderColor = Colors.white.withValues(alpha: 0.06);
    }

    final content = icon != null
        ? Icon(icon, size: 18, color: foreground)
        : Text(
            label!,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: foreground,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                ),
          );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: enabled ? onTap : null,
        child: Container(
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(10),
            border:
                Border.all(color: borderColor, width: selected ? 1.4 : 1),
          ),
          child: content,
        ),
      ),
    );
  }
}
