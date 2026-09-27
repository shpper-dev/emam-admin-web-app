import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:emam_admin_web_app/core/utils/formatters.dart';
import 'package:emam_admin_web_app/core/widgets/detail_block.dart';
import 'package:emam_admin_web_app/core/widgets/inline_retry_error.dart';
import 'package:emam_admin_web_app/core/widgets/pill_action_button.dart';
import 'package:emam_admin_web_app/core/widgets/status_badge.dart';
import 'package:emam_admin_web_app/features/content/views/widgets/content_section_card.dart';
import 'package:emam_admin_web_app/features/devices/models/device_session_info.dart';
import 'package:emam_admin_web_app/features/devices/provider/device_session_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DevicesView extends ConsumerStatefulWidget {
  const DevicesView({super.key});

  @override
  ConsumerState<DevicesView> createState() => _DevicesViewState();
}

class _DevicesViewState extends ConsumerState<DevicesView> {
  bool _refreshing = false;

  Future<void> _onRefresh() async {
    setState(() => _refreshing = true);
    await ref.read(deviceSessionProvider.notifier).refresh();
    if (!mounted) return;
    setState(() => _refreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sessionAsync = ref.watch(deviceSessionProvider);

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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
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
                          "This browser's own admin session. Cross-device "
                          "history needs backend support and isn't tracked "
                          'yet.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: AppConstants.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_refreshing) ...[
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppConstants.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      PillActionButton(
                        icon: Icons.refresh_rounded,
                        label: 'Refresh',
                        color: AppConstants.primary,
                        onPressed: _refreshing ? null : () => _onRefresh(),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              sessionAsync.when(
                loading: () => const ContentSectionCard(
                  title: 'Current session',
                  subtitle: 'Loading device info…',
                  icon: Icons.devices_rounded,
                  child: SectionLoadingIndicator(),
                ),
                error: (error, _) => ContentSectionCard(
                  title: 'Current session',
                  subtitle: "Could not load this session's details",
                  icon: Icons.devices_rounded,
                  accentColor: AppConstants.danger,
                  child: InlineRetryError(
                    message: 'Failed to load device info.',
                    onRetry: () => ref.invalidate(deviceSessionProvider),
                  ),
                ),
                data: (data) => _DeviceCard(data: data),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({required this.data});

  final DeviceSessionInfo data;

  @override
  Widget build(BuildContext context) {
    return ContentSectionCard(
      title: data.label.title,
      subtitle: 'Signed in via this browser',
      icon: data.label.icon,
      trailing: const StatusBadge(
        label: 'Current session',
        color: AppConstants.success,
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
              value: data.ipAddress ?? 'Unavailable',
            ),
            DetailBlock(
              label: 'Started',
              value: formatAdminDate(
                data.startedAt,
                unknownLabel: 'Unknown',
                includeTime: true,
              ),
            ),
            DetailBlock(
              label: 'Last accessed',
              value: formatAdminDate(data.lastAccessedAt, includeTime: true),
            ),
            DetailBlock(
              label: 'Expires',
              value: formatAdminDate(
                data.expiresAt,
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
