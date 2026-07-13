import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:flutter/material.dart';

class ContentSectionCard extends StatelessWidget {
  const ContentSectionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppConstants.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppConstants.primary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppConstants.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                            ),
                      ),
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF1E1E20)),
          Padding(
            padding: const EdgeInsets.all(20),
            child: child,
          ),
        ],
      ),
    );
  }
}

class ContentMetaChip extends StatelessWidget {
  const ContentMetaChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppConstants.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppConstants.primary.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppConstants.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

int contentGridColumns(double width) {
  if (width >= 1400) return 3;
  if (width >= 900) return 2;
  return 1;
}

double contentHorizontalPadding(double width) {
  if (width >= 1200) return 32;
  if (width >= 600) return 24;
  return 16;
}
