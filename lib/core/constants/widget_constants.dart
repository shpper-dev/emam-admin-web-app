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
        icon: Icons.logout_rounded,
        accentColor: AppConstants.danger,
        content: Text(
          'Are you sure you want to log out?',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppConstants.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            autofocus: true,
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

  void _closeDrawer(BuildContext context) {
    if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  void _navigate(BuildContext context, String path) {
    _closeDrawer(context);
    context.go(path);
  }

  Future<void> _openExternal(
    BuildContext context,
    String url,
    String label,
  ) async {
    _closeDrawer(context);
    final messenger = ScaffoldMessenger.of(context);
    var launched = false;
    try {
      launched = await launchUrl(Uri.parse(url), webOnlyWindowName: '_blank');
    } catch (_) {}
    if (!launched) {
      messenger.showSnackBar(SnackBar(content: Text('Could not open $label')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPath = GoRouterState.of(context).matchedLocation;
    final email = ref.watch(authProvider).value?.email;

    bool on(String path) =>
        currentPath == path || currentPath.startsWith('$path/');

    Widget tile(IconData icon, String label, String path) => _DrawerTile(
      icon: icon,
      label: label,
      selected: on(path),
      onTap: () => _navigate(context, path),
    );

    return Drawer(
      backgroundColor: AppConstants.bgColor,
      elevation: 0,
      shape: const RoundedRectangleBorder(),
      child: Column(
        children: [
          Expanded(
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
                const _DrawerDivider(),
                const _DrawerSectionLabel('Overview'),
                tile(
                  Icons.dashboard_rounded,
                  'Users & Moderation',
                  RoutePaths.dashboard,
                ),
                const _DrawerSectionLabel('Content'),
                tile(CupertinoIcons.globe, 'Contents', RoutePaths.content),
                tile(
                  Icons.notifications_active_rounded,
                  'Notifications',
                  RoutePaths.notifications,
                ),
                const _DrawerSectionLabel('Operations'),
                tile(Icons.phone_android_rounded, 'Units', RoutePaths.units),
                tile(Icons.devices_rounded, 'Devices', RoutePaths.devices),
                tile(
                  Icons.record_voice_over_rounded,
                  'Voice Demo',
                  RoutePaths.voiceDemo,
                ),
                const _DrawerSectionLabel('Monitoring'),
                tile(Icons.history_rounded, 'Audit Log', RoutePaths.audit),
                tile(
                  Icons.build_circle_outlined,
                  'System Tools',
                  RoutePaths.systemTools,
                ),
              ],
            ),
          ),
          const _DrawerDivider(),
          const SizedBox(height: AppConstants.space8),
          _DrawerTile(
            icon: Icons.feedback_rounded,
            label: 'Feedback',
            selected: false,
            external: true,
            onTap: () => _openExternal(
              context,
              AppConstants.feedbackUrl,
              'feedback link',
            ),
          ),
          _DrawerTile(
            icon: Icons.insights_rounded,
            label: 'Analytics',
            selected: false,
            external: true,
            onTap: () => _openExternal(
              context,
              AppConstants.firebaseAnalyticsUrl,
              'Firebase Analytics',
            ),
          ),
          _DrawerTile(
            icon: CupertinoIcons.arrow_left_square_fill,
            label: 'Log out',
            selected: false,
            danger: true,
            onTap: () async {
              _closeDrawer(context);
              await _confirmAndSignOut(context, ref);
            },
          ),
          if (email != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppConstants.space24,
                4,
                AppConstants.space24,
                AppConstants.space16,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.account_circle_outlined,
                    size: 16,
                    color: AppConstants.textMuted,
                  ),
                  const SizedBox(width: AppConstants.space8),
                  Expanded(
                    child: Tooltip(
                      message: email,
                      child: Text(
                        email,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppConstants.textMuted,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            const SizedBox(height: AppConstants.space16),
        ],
      ),
    );
  }
}

class _DrawerDivider extends StatelessWidget {
  const _DrawerDivider();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 20),
    child: Divider(height: 1, color: AppConstants.dividerColor),
  );
}

class _DrawerSectionLabel extends StatelessWidget {
  const _DrawerSectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppConstants.space24,
      AppConstants.space16,
      AppConstants.space24,
      AppConstants.space8,
    ),
    child: Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: AppConstants.textFaint,
        letterSpacing: 1.2,
      ),
    ),
  );
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.danger = false,
    this.external = false,
  });

  final bool external;
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
                if (external) ...[
                  const Spacer(),
                  const Icon(
                    Icons.open_in_new_rounded,
                    size: 14,
                    color: AppConstants.textFaint,
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
