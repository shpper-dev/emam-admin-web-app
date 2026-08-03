import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:emam_admin_web_app/core/router/route_paths.dart';
import 'package:emam_admin_web_app/core/widgets/admin_alert_dialog.dart';
import 'package:emam_admin_web_app/features/auth/provider/auth_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> _confirmAndSignOut(BuildContext context, WidgetRef ref) async {
  final theme = Theme.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AdminAlertDialog(
        title: 'Log out',
        content: Text(
          'Are you sure you want to log out?',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppConstants.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Log out'),
          ),
        ],
      );
    },
  );

  if (confirmed == true && context.mounted) {
    await ref.read(authProvider.notifier).signOut();
  }
}

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  void _navigate(BuildContext context, String path) {
    if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
    context.go(path);
  }

  Future<void> _openFeedback(BuildContext context) async {
    if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
    final uri = Uri.parse(AppConstants.feedbackUrl);
    try {
      final launched = await launchUrl(uri, webOnlyWindowName: '_blank');
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open feedback link')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open feedback link')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPath = GoRouterState.of(context).matchedLocation;

    return Drawer(
      backgroundColor: AppConstants.bgColor,
      elevation: 0,
      shape: const RoundedRectangleBorder(),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          GestureDetector(
            onTap: () => _navigate(context, RoutePaths.dashboard),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                height: 164,
                alignment: Alignment.center,
                padding: const EdgeInsets.only(top: 20),
                child: Image.asset(AppConstants.emamLogo),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Divider(height: 1, color: AppConstants.dividerColor),
          ),
          const SizedBox(height: AppConstants.space16),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.space24,
            ),
            child: Text(
              'MENU',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppConstants.textFaint,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: AppConstants.space8),
          _DrawerTile(
            icon: Icons.dashboard_rounded,
            label: 'Dashboard',
            selected: currentPath == RoutePaths.dashboard,
            onTap: () => _navigate(context, RoutePaths.dashboard),
          ),
          _DrawerTile(
            icon: CupertinoIcons.globe,
            label: 'Contents',
            selected: currentPath == RoutePaths.content,
            onTap: () => _navigate(context, RoutePaths.content),
          ),
          const SizedBox(height: AppConstants.space16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Divider(height: 1, color: AppConstants.dividerColor),
          ),
          const SizedBox(height: AppConstants.space8),
          _DrawerTile(
            icon: Icons.feedback_rounded,
            label: 'Feedback',
            selected: false,
            onTap: () => _openFeedback(context),
          ),
          _DrawerTile(
            icon: CupertinoIcons.arrow_left_square_fill,
            label: 'Logout',
            selected: false,
            danger: true,
            onTap: () async {
              if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
                Navigator.of(context).pop();
              }
              await _confirmAndSignOut(context, ref);
            },
          ),
        ],
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool danger;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? AppConstants.primary
        : danger
        ? AppConstants.danger
        : AppConstants.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.space12,
        vertical: 3,
      ),
      child: Material(
        color: selected
            ? AppConstants.primary.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AppConstants.radiusSm),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppConstants.radiusSm),
          onTap: onTap,
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.space12,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppConstants.radiusSm),
              border: selected
                  ? Border(
                      left: BorderSide(color: AppConstants.primary, width: 3),
                    )
                  : null,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: selected ? 13 : 16,
                  child: Icon(icon, size: 19, color: color),
                ),
                const SizedBox(width: AppConstants.space12),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
