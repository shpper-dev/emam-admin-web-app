import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:flutter/material.dart';

/// Modern pill-style pager shared by the users grid and the audit log.
///
/// A single rounded track holds `Previous`, a windowed run of page numbers
/// (first, last and the neighbours of the current page, with `…` gaps) and
/// `Next`. `Next` fetches the next undiscovered page when the server reports
/// another `next_page_token` (`hasNextToken`). Labels collapse to icons on
/// narrow widths.
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

  /// Page numbers to render; `null` marks a `…` gap.
  List<int?> _window() {
    if (discoveredPages <= 7) {
      return [for (var p = 1; p <= discoveredPages; p++) p];
    }
    final pages = <int>{
      1,
      discoveredPages,
      for (var p = currentPage - 1; p <= currentPage + 1; p++)
        if (p >= 1 && p <= discoveredPages) p,
    }.toList()..sort();
    final out = <int?>[];
    for (var i = 0; i < pages.length; i++) {
      if (i > 0 && pages[i] - pages[i - 1] > 1) out.add(null);
      out.add(pages[i]);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    if (discoveredPages <= 1 && !hasNextToken) {
      return const SizedBox.shrink();
    }

    final canGoPrev = !isLoading && currentPage > 1;
    final canGoNext =
        !isLoading && (currentPage < discoveredPages || hasNextToken);

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 520;
          return Center(
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppConstants.surfaceColor,
                borderRadius: BorderRadius.circular(AppConstants.radiusPill),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.22),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _NavButton(
                    icon: Icons.arrow_back_rounded,
                    label: compact ? null : 'Previous',
                    iconFirst: true,
                    enabled: canGoPrev,
                    onTap: () => onPageTap(currentPage - 1),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final p in _window())
                            p == null
                                ? const _Gap()
                                : _PageButton(
                                    page: p,
                                    selected: p == currentPage,
                                    enabled: !isLoading,
                                    onTap: () => onPageTap(p),
                                  ),
                          if (isLoading)
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppConstants.primary,
                                ),
                              ),
                            )
                          else if (hasNextToken)
                            const _Gap(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  _NavButton(
                    icon: Icons.arrow_forward_rounded,
                    label: compact ? null : 'Next',
                    iconFirst: false,
                    enabled: canGoNext,
                    onTap: () => onPageTap(currentPage + 1),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Gap extends StatelessWidget {
  const _Gap();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      child: Text(
        '···',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: AppConstants.textSecondary,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _PageButton extends StatelessWidget {
  const _PageButton({
    required this.page,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final int page;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: selected ? AppConstants.primary : Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          hoverColor: Colors.white.withValues(alpha: 0.06),
          onTap: enabled && !selected ? onTap : null,
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            child: Text(
              '$page',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected
                    ? AppConstants.bgColor
                    : Colors.white.withValues(alpha: enabled ? 0.85 : 0.35),
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.label,
    required this.iconFirst,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String? label;
  final bool iconFirst;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = enabled
        ? AppConstants.primary
        : Colors.white.withValues(alpha: 0.25);
    final children = <Widget>[
      Icon(icon, size: 18, color: color),
      if (label != null) ...[
        const SizedBox(width: 6),
        Text(
          label!,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ];
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppConstants.radiusPill),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppConstants.radiusPill),
        hoverColor: AppConstants.primary.withValues(alpha: 0.1),
        onTap: enabled ? onTap : null,
        child: Container(
          height: 36,
          constraints: const BoxConstraints(minWidth: 36),
          padding: EdgeInsets.symmetric(horizontal: label == null ? 9 : 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: iconFirst ? children : children.reversed.toList(),
          ),
        ),
      ),
    );
  }
}
