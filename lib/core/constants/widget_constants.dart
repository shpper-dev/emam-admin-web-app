import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:emam_admin_web_app/core/router/route_paths.dart';
import 'package:emam_admin_web_app/features/auth/provider/auth_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
          Container(
            height: 180,
            padding: const EdgeInsets.only(top: 24),
            child: Image.asset(AppConstants.emamLogo),
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
              await ref.read(authProvider.notifier).signOut();
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
