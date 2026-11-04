import 'package:dio/dio.dart';
import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:emam_admin_web_app/core/network/api_error.dart';
import 'package:emam_admin_web_app/core/utils/formatters.dart';
import 'package:emam_admin_web_app/core/widgets/admin_alert_dialog.dart';
import 'package:emam_admin_web_app/core/widgets/detail_block.dart';
import 'package:emam_admin_web_app/core/widgets/inline_retry_error.dart';
import 'package:emam_admin_web_app/core/widgets/pill_action_button.dart';
import 'package:emam_admin_web_app/core/widgets/section_empty_message.dart';
import 'package:emam_admin_web_app/core/widgets/status_badge.dart';
import 'package:emam_admin_web_app/features/auth/provider/auth_provider.dart';
import 'package:emam_admin_web_app/features/content/views/widgets/content_section_card.dart';
import 'package:emam_admin_web_app/features/devices/models/signed_in_session.dart';
import 'package:emam_admin_web_app/features/devices/provider/sessions_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DevicesView extends ConsumerStatefulWidget {
  const DevicesView({super.key});

  @override
  ConsumerState<DevicesView> createState() => _DevicesViewState();
}

class _DevicesViewState extends ConsumerState<DevicesView> {
  bool _busy = false;

  void _toast(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppConstants.danger : null,
      ),
    );
  }

  Future<bool> _confirm({
    required String title,
    required String body,
    required String action,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AdminAlertDialog(
        title: title,
        icon: Icons.logout_rounded,
        accentColor: AppConstants.danger,
        content: Text(
          body,
          style: Theme.of(
            dialogContext,
          ).textTheme.bodyMedium?.copyWith(color: AppConstants.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(action),
          ),
        ],
      ),
    );
    return result == true && mounted;
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } on DioException catch (error) {
      if (mounted) _toast(parseApiError(error), error: true);
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _signOut(SignedInSession session) async {
    final ok = await _confirm(
      title: session.isCurrent ? 'Sign out this device?' : 'Sign out device?',
      body: session.isCurrent
          ? 'This is the browser you are using. You will be signed out '
                'immediately.'
          : '${session.deviceName} will be signed out and must sign in again.',
      action: 'Sign out',
    );
    if (!ok) return;
    var revoked = false;
    await _run(() async {
      await ref.read(sessionsProvider.notifier).revoke(session.id);
      revoked = true;
    });
    if (!revoked || !mounted) return;
    if (session.isCurrent) {
      await ref.read(authProvider.notifier).signOut();
    } else {
      _toast('Device signed out.');
    }
  }

  Future<void> _signOutOthers() async {
    final ok = await _confirm(
      title: 'Sign out other devices?',
      body: 'Every session except this browser will be signed out.',
      action: 'Sign out others',
    );
    if (!ok) return;
    await _run(() async {
      final count = await ref.read(sessionsProvider.notifier).revokeOthers();
      if (mounted) _toast('Signed out $count other device(s).');
    });
  }

  Future<void> _refresh() => _run(ref.read(sessionsProvider.notifier).refresh);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sessionsAsync = ref.watch(sessionsProvider);
    final sessions = sessionsAsync.value;
    final hasCurrent = sessions?.sessions.any((s) => s.isCurrent) ?? false;
    final hasOthers = sessions != null && sessions.others.isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = contentHorizontalPadding(
          constraints.maxWidth,
        );

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            24,
            horizontalPadding,
            32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Signed-in Devices',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: AppConstants.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Browsers and devices currently signed in to your account. '
                'Sign out any you do not recognise.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppConstants.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  PillActionButton(
                    icon: Icons.refresh_rounded,
                    label: 'Refresh',
                    color: AppConstants.primary,
                    onPressed: _busy ? null : _refresh,
                  ),
                  if (hasCurrent && hasOthers)
                    PillActionButton(
                      icon: Icons.logout_rounded,
                      label: 'Sign out other devices',
                      color: AppConstants.danger,
                      onPressed: _busy ? null : _signOutOthers,
                    ),
                  if (_busy)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppConstants.primary,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              sessionsAsync.when(
                skipLoadingOnReload: true,
                loading: () => const ContentSectionCard(
                  title: 'Sessions',
                  subtitle: 'Loading signed-in devices…',
                  icon: Icons.devices_rounded,
                  child: SectionLoadingIndicator(),
                ),
                error: (error, _) => ContentSectionCard(
                  title: 'Sessions',
                  subtitle: 'Could not load signed-in devices',
                  icon: Icons.devices_rounded,
                  accentColor: AppConstants.danger,
                  child: InlineRetryError(
                    message: _errorMessage(error),
                    onRetry: () => ref.invalidate(sessionsProvider),
                  ),
                ),
                data: (data) => data.sessions.isEmpty
                    ? const ContentSectionCard(
                        title: 'Sessions',
                        subtitle: 'No active sessions',
                        icon: Icons.devices_rounded,
                        child: SectionEmptyMessage(
                          'No signed-in devices found.',
                        ),
                      )
                    : Column(
                        children: [
                          for (final session in data.sessions) ...[
                            _DeviceCard(
                              session: session,
                              onSignOut: _busy ? null : () => _signOut(session),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _errorMessage(Object error) {
    if (error is DioException) {
      if (error.response?.statusCode == 503) {
        return 'Device tracking is unavailable right now. Please try again '
            'later.';
      }
      return parseApiError(error);
    }
    return 'Failed to load signed-in devices.';
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({required this.session, required this.onSignOut});

  final SignedInSession session;
  final VoidCallback? onSignOut;

  static IconData _icon(String name) {
    final n = name.toLowerCase();
    return n.contains('android') || n.contains('ios') || n.contains('iphone')
        ? Icons.smartphone_rounded
        : Icons.computer_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return ContentSectionCard(
      title: session.deviceName,
      subtitle: session.isCurrent ? 'This browser' : 'Other device',
      icon: _icon(session.deviceName),
      trailing: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (session.isCurrent)
            const StatusBadge(
              label: 'Current session',
              color: AppConstants.success,
            ),
          PillActionButton(
            icon: Icons.logout_rounded,
            label: 'Sign out',
            color: AppConstants.danger,
            onPressed: onSignOut,
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 640
              ? 4
              : constraints.maxWidth >= 420
              ? 2
              : 1;
          const spacing = 12.0;
          final tileWidth =
              (constraints.maxWidth - spacing * (columns - 1)) / columns;

          final fields = [
            DetailBlock(
              label: 'IP address',
              value: session.ipAddress ?? 'Unavailable',
            ),
            DetailBlock(
              label: 'Started',
              value: formatAdminDate(
                session.startedAt,
                unknownLabel: 'Unknown',
                includeTime: true,
              ),
            ),
            DetailBlock(
              label: 'Last accessed',
              value: formatAdminDate(
                session.lastAccessedAt,
                unknownLabel: 'Unknown',
                includeTime: true,
              ),
            ),
            DetailBlock(
              label: 'Expires',
              value: formatAdminDate(
                session.expiresAt,
                unknownLabel: 'Unknown',
                includeTime: true,
              ),
            ),
          ];

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              for (final field in fields)
                SizedBox(width: tileWidth, child: field),
            ],
          );
        },
      ),
    );
  }
}
