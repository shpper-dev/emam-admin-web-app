import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:emam_admin_web_app/core/widgets/detail_block.dart';
import 'package:emam_admin_web_app/core/widgets/inline_retry_error.dart';
import 'package:emam_admin_web_app/core/widgets/pill_action_button.dart';
import 'package:emam_admin_web_app/core/widgets/section_empty_message.dart';
import 'package:emam_admin_web_app/features/content/views/widgets/content_section_card.dart';
import 'package:emam_admin_web_app/features/units/models/device_unit.dart';
import 'package:emam_admin_web_app/features/units/provider/units_provider.dart';
import 'package:emam_admin_web_app/features/units/utils/unit_display.dart';
import 'package:emam_admin_web_app/features/units/views/widgets/unit_actions_card.dart';
import 'package:emam_admin_web_app/features/units/views/widgets/unit_command_history.dart';
import 'package:emam_admin_web_app/features/units/views/widgets/unit_crash_reports.dart';
import 'package:emam_admin_web_app/features/units/views/widgets/unit_settings_card.dart';
import 'package:emam_admin_web_app/features/units/views/widgets/unit_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Everything about one unit: shown beside the list on wide screens and as
/// its own page on narrow ones.
class UnitDetailPanel extends ConsumerWidget {
  const UnitDetailPanel({super.key, required this.installId, this.onClose});

  final String installId;

  /// Shows a close button in the header when set.
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unitsAsync = ref.watch(unitsProvider);
    final unit = unitsAsync.value?.byId(installId);
    if (unit == null) {
      if (unitsAsync.isLoading) return const SectionLoadingIndicator();
      if (unitsAsync.hasError) {
        return InlineRetryError(
          message: unitErrorMessage(unitsAsync.error!),
          onRetry: () => ref.invalidate(unitsProvider),
        );
      }
      return ContentSectionCard(
        title: 'Unit not found',
        subtitle: 'It is not in the units list any more.',
        icon: Icons.phone_android_rounded,
        trailing: _closeButton(),
        child: const SectionEmptyMessage(
          'This unit is not in the list. Go back to the units and pick '
          'another one.',
          icon: Icons.search_off_rounded,
        ),
      );
    }

    final now = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _UnitHeaderCard(unit: unit, now: now, closeButton: _closeButton()),
        const SizedBox(height: AppConstants.space16),
        UnitActionsCard(unit: unit),
        const SizedBox(height: AppConstants.space16),
        _UnitStatusCard(unit: unit, now: now),
        const SizedBox(height: AppConstants.space16),
        UnitSettingsCard(unit: unit),
        const SizedBox(height: AppConstants.space16),
        UnitCommandHistoryCard(unit: unit),
        const SizedBox(height: AppConstants.space16),
        UnitCrashReportsCard(unit: unit),
      ],
    );
  }

  Widget? _closeButton() => onClose == null
      ? null
      : IconButton(
          tooltip: 'Close',
          onPressed: onClose,
          icon: const Icon(Icons.close_rounded),
        );
}

class _UnitHeaderCard extends StatelessWidget {
  const _UnitHeaderCard({
    required this.unit,
    required this.now,
    required this.closeButton,
  });

  final DeviceUnit unit;
  final DateTime now;
  final Widget? closeButton;

  @override
  Widget build(BuildContext context) {
    final online = unit.isOnline(now);
    final flags = unitFlags(unit);
    final details = [
      if (unit.serial != null) 'Serial ${unit.serial}',
      if (unit.model != null) unit.model!,
      if (unit.appVersion != null) 'App ${unit.appVersion}',
    ];
    return ContentSectionCard(
      title: unit.displayName,
      subtitle: details.isEmpty
          ? 'No details reported yet'
          : details.join(' · '),
      icon: Icons.phone_android_rounded,
      accentColor: online ? AppConstants.success : AppConstants.primary,
      trailing: closeButton,
      headerExtra: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          UnitBadge(
            label: presenceLabel(unit, now),
            color: online ? AppConstants.success : AppConstants.textMuted,
          ),
          for (final flag in flags) UnitFlagBadge(flag: flag),
        ],
      ),
      child: _RenameField(unit: unit),
    );
  }
}

class _RenameField extends ConsumerStatefulWidget {
  const _RenameField({required this.unit});

  final DeviceUnit unit;

  @override
  ConsumerState<_RenameField> createState() => _RenameFieldState();
}

class _RenameFieldState extends ConsumerState<_RenameField> {
  late final _controller = TextEditingController(text: widget.unit.name);
  bool _saving = false;

  bool get _changed => _controller.text.trim() != widget.unit.name;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_changed || _saving) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(unitsProvider.notifier)
          .rename(widget.unit.installId, _controller.text);
      if (mounted) showUnitToast(context, 'Name saved.');
    } catch (error) {
      if (mounted) showUnitToast(context, unitErrorMessage(error), error: true);
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      controller: _controller,
      enabled: !_saving,
      maxLength: 60,
      style: const TextStyle(color: AppConstants.textPrimary),
      cursorColor: AppConstants.primary,
      decoration: unitInputDecoration(
        'Name in the admin panel',
        hint: 'e.g. Muscat mosque 1',
        helper: 'Leave empty to show its install ID instead.',
      ),
      onChanged: (_) => setState(() {}),
      onSubmitted: (_) => _save(),
    );
    final button = PillActionButton(
      icon: Icons.save_rounded,
      label: 'Save name',
      color: AppConstants.primary,
      onPressed: _changed && !_saving ? _save : null,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 380) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [field, const SizedBox(height: 8), button],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: field),
            const SizedBox(width: AppConstants.space12),
            Padding(padding: const EdgeInsets.only(top: 4), child: button),
          ],
        );
      },
    );
  }
}

class _UnitStatusCard extends StatelessWidget {
  const _UnitStatusCard({required this.unit, required this.now});

  final DeviceUnit unit;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final statusAt = unit.statusAt;
    final groups = describeStatus(unit, now);
    return ContentSectionCard(
      title: 'Status',
      subtitle: statusAt == null
          ? 'The unit has not checked in yet, so only its activation details '
                'are known.'
          : 'As the unit reported it at its last check-in, '
                '${relativeTime(statusAt, now)}.',
      icon: Icons.monitor_heart_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < groups.length; i++) ...[
            if (i > 0) const SizedBox(height: AppConstants.space20),
            UnitGroupLabel(groups[i].title),
            const SizedBox(height: AppConstants.space8),
            UnitDetailGrid(
              children: [
                for (final entry in groups[i].entries)
                  DetailBlock(label: entry.label, value: entry.value),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
