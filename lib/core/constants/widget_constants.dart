import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:emam_admin_web_app/core/router/route_paths.dart';
import 'package:emam_admin_web_app/features/auth/provider/auth_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

Future<void> _confirmAndSignOut(BuildContext context, WidgetRef ref) async {
  final theme = Theme.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: AppConstants.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        title: Text(
          'Log out',
          style: theme.textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
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
          ListTile(
            leading: const Icon(Icons.feedback),
            title: const Text('F E E D B A C K'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(CupertinoIcons.arrow_left_square_fill),
            title: const Text('L O G O U T'),
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
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      selected: selected,
      selectedTileColor: AppConstants.primary.withValues(alpha: 0.12),
      onTap: onTap,
    );
  }
}
