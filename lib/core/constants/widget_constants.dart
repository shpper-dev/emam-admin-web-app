import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:emam_admin_web_app/features/auth/provider/auth_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

var myAppBar = AppBar(
  title: const Text('Admin Panel'),
);

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      backgroundColor: AppConstants.bgColor,
      child: ListView(
        children: [
          Container(
            height: 180,
            padding: const EdgeInsets.only(top: 24),
            child: Image.asset(AppConstants.emamLogo),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard_rounded),
            title: const Text('D A S H B O A R D'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(CupertinoIcons.globe),
            title: const Text('C O N T A N T S'),
            onTap: () {},
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
