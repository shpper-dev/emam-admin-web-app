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
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
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
      final launched = await launchUrl(
        uri,
        webOnlyWindowName: '_blank',
      );
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
      child: ListView(
        children: [
          GestureDetector(
            onTap: () => _navigate(context, RoutePaths.dashboard),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                height: 180,
                padding: const EdgeInsets.only(top: 24),
                child: Image.asset(AppConstants.emamLogo),
              ),
            ),
          ),
          Divider(
            height: 1,
            indent: 20,
            endIndent: 20,
            color: Colors.white.withValues(alpha: 0.08),
          ),
          const SizedBox(height: 12),
          _DrawerTile(
            icon: Icons.dashboard_rounded,
            label: 'D A S H B O A R D',
            selected: currentPath == RoutePaths.dashboard,
            onTap: () => _navigate(context, RoutePaths.dashboard),
          ),
          _DrawerTile(
            icon: CupertinoIcons.globe,
            label: 'C O N T E N T S',
            selected: currentPath == RoutePaths.content,
            onTap: () => _navigate(context, RoutePaths.content),
          ),
          _DrawerTile(
            icon: Icons.feedback,
            label: 'F E E D B A C K',
            selected: false,
            onTap: () => _openFeedback(context),
          ),
          _DrawerTile(
            icon: CupertinoIcons.arrow_left_square_fill,
            label: 'L O G O U T',
            selected: false,
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
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppConstants.primary : Colors.white70;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(label, style: TextStyle(color: color)),
        selected: selected,
        selectedTileColor: AppConstants.primary.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        onTap: onTap,
      ),
    );
  }
}
