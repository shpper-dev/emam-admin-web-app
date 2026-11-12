import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:emam_admin_web_app/core/utils/formatters.dart';
import 'package:emam_admin_web_app/core/widgets/inline_retry_error.dart';
import 'package:emam_admin_web_app/core/widgets/pill_action_button.dart';
import 'package:emam_admin_web_app/core/widgets/section_empty_message.dart';
import 'package:emam_admin_web_app/features/content/views/widgets/content_section_card.dart';
import 'package:emam_admin_web_app/features/units/models/device_unit.dart';
import 'package:emam_admin_web_app/features/units/models/unit_command.dart';
import 'package:emam_admin_web_app/features/units/provider/unit_detail_providers.dart';
import 'package:emam_admin_web_app/features/units/provider/units_provider.dart';
import 'package:emam_admin_web_app/features/units/utils/unit_display.dart';
import 'package:emam_admin_web_app/features/units/views/widgets/unit_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UnitCommandHistoryCard extends ConsumerWidget {
  const UnitCommandHistoryCard({super.key, required this.unit});

  final DeviceUnit unit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = unitCommandsProvider(unit.installId);
    return ContentSectionCard(
      title: 'Command history',
      subtitle:
          'Newest first. A waiting command can be cancelled until the unit '
          'fetches it.',
      icon: Icons.history_rounded,
      trailing: IconButton(
        tooltip: 'Refresh command history',
        onPressed: () => ref.read(provider.notifier).refresh(),
        icon: const Icon(Icons.refresh_rounded),
      ),
      child: ref
          .watch(provider)
          .when(
            skipLoadingOnReload: true,
            loading: () => const SectionLoadingIndicator(),
            error: (error, _) => InlineRetryError(
              message: unitErrorMessage(error),
              onRetry: () => ref.invalidate(provider),
            ),
            data: (commands) => commands.isEmpty
                ? const SectionEmptyMessage(
                    'No commands sent to this unit yet.',
                    icon: Icons.history_toggle_off_rounded,
                  )
                : Column(
                    children: [
                      for (final command in commands)
                        _CommandRow(unit: unit, command: command),
                    ],
                  ),
          ),
    );
  }
}

class _CommandRow extends ConsumerStatefulWidget {
  const _CommandRow({required this.unit, required this.command});

  final DeviceUnit unit;
  final UnitCommand command;

  @override
  ConsumerState<_CommandRow> createState() => _CommandRowState();
}

class _CommandRowState extends ConsumerState<_CommandRow> {
  bool _cancelling = false;

  Future<void> _cancel() async {
    setState(() => _cancelling = true);
    try {
      await ref
          .read(unitCommandsProvider(widget.unit.installId).notifier)
          .cancel(widget.command.id);
      ref.read(unitsProvider.notifier).refresh();
      if (mounted) {
        showUnitToast(
          context,
          '${commandLabel(widget.command.type)} cancelled.',
        );
      }
    } catch (error) {
      if (!mounted) return;
      showUnitToast(context, unitErrorMessage(error), error: true);
      ref.read(unitCommandsProvider(widget.unit.installId).notifier).refresh();
    }
    if (mounted) setState(() => _cancelling = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final command = widget.command;
    final now = DateTime.now();
    final (stateLabel, stateColor) = commandStateLabel(command.state);
    final args = describeCommandArgs(command.type, command.args);
    final result = command.result;
    final hint = switch (command.state) {
      UnitCommandState.pending => 'Waiting for the unit\'s next check-in.',
      UnitCommandState.sent =>
        'The unit has it. The result comes with its next check-in.',
      _ => null,
    };
    final times = [
      if (command.createdAt != null)
        'Queued ${relativeTime(command.createdAt!, now)}'
            '${command.createdBy == null ? '' : ' by ${command.createdBy}'}',
      if (command.sentAt != null)
        'fetched ${relativeTime(command.sentAt!, now)}',
      if (command.doneAt != null)
        'finished ${relativeTime(command.doneAt!, now)}',
    ];
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: AppConstants.textMuted,
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.space12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppConstants.dividerColor)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: stateColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(commandIcon(command.type), size: 18, color: stateColor),
          ),
          const SizedBox(width: AppConstants.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      commandLabel(command.type),
                      style: theme.textTheme.titleSmall,
                    ),
                    UnitBadge(label: stateLabel, color: stateColor),
                  ],
                ),
                if (args != null) ...[
                  const SizedBox(height: 4),
                  Text(args, style: muted),
                ],
                if (result != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    result,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: command.state == UnitCommandState.failed
                          ? AppConstants.danger
                          : AppConstants.textPrimary,
                    ),
                  ),
                ],
                if (hint != null) ...[
                  const SizedBox(height: 4),
                  Text(hint, style: muted),
                ],
                if (times.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Tooltip(
                    message: _tooltip(command),
                    child: Text(times.join(' · '), style: muted),
                  ),
                ],
              ],
            ),
          ),
          if (command.canCancel) ...[
            const SizedBox(width: AppConstants.space8),
            PillActionButton(
              icon: Icons.close_rounded,
              label: 'Cancel command',
              color: AppConstants.danger,
              onPressed: _cancelling ? null : _cancel,
            ),
          ],
        ],
      ),
    );
  }

  static String _tooltip(UnitCommand command) => [
    if (command.createdAt != null) 'Queued ${_stamp(command.createdAt)}',
    if (command.sentAt != null) 'Fetched ${_stamp(command.sentAt)}',
    if (command.doneAt != null) 'Finished ${_stamp(command.doneAt)}',
  ].join('\n');

  static String _stamp(DateTime? time) =>
      formatAdminDate(time, includeTime: true);
}
