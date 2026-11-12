import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:emam_admin_web_app/core/widgets/pill_action_button.dart';
import 'package:emam_admin_web_app/features/content/views/widgets/content_section_card.dart';
import 'package:emam_admin_web_app/features/units/models/device_unit.dart';
import 'package:emam_admin_web_app/features/units/provider/fleet_settings_provider.dart';
import 'package:emam_admin_web_app/features/units/provider/unit_detail_providers.dart';
import 'package:emam_admin_web_app/features/units/provider/units_provider.dart';
import 'package:emam_admin_web_app/features/units/utils/unit_display.dart';
import 'package:emam_admin_web_app/features/units/views/widgets/unit_command_dialogs.dart';
import 'package:emam_admin_web_app/features/units/views/widgets/unit_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UnitActionsCard extends ConsumerStatefulWidget {
  const UnitActionsCard({super.key, required this.unit});

  final DeviceUnit unit;

  @override
  ConsumerState<UnitActionsCard> createState() => _UnitActionsCardState();
}

class _UnitActionsCardState extends ConsumerState<UnitActionsCard> {
  bool _busy = false;

  DeviceUnit get _unit => widget.unit;

  int? get _checkInMinutes =>
      checkInMinutes(_unit, ref.read(fleetSettingsProvider).value);

  Future<void> _queue(String type, [Map<String, Object?> args = const {}]) {
    return _run(() async {
      await ref
          .read(unitCommandsProvider(_unit.installId).notifier)
          .queue(type, args);
      ref.read(unitsProvider.notifier).refresh();
      if (mounted) {
        showUnitToast(
          context,
          queuedMessage(type, _unit, _checkInMinutes),
          duration: const Duration(seconds: 6),
        );
      }
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (error) {
      if (mounted) showUnitToast(context, unitErrorMessage(error), error: true);
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _confirmThenQueue(
    String type, {
    required String title,
    required String body,
    required String action,
    Color color = AppConstants.warning,
  }) async {
    final confirmed = await confirmUnitAction(
      context,
      title: title,
      body: body,
      action: action,
      icon: commandIcon(type),
      color: color,
    );
    if (confirmed && mounted) await _queue(type);
  }

  Future<void> _withArgs(
    String type,
    Future<Map<String, Object?>?> Function(BuildContext) dialog,
  ) async {
    final args = await dialog(context);
    if (args != null && mounted) await _queue(type, args);
  }

  Future<void> _setRevoked(bool revoked) async {
    final confirmed = await confirmUnitAction(
      context,
      title: revoked
          ? 'Revoke this unit\'s activation?'
          : 'Restore this unit\'s activation?',
      body: revoked
          ? 'The server refuses the unit from its next request on. The unit '
                'then forgets its activation and asks for an activation code, '
                'so restoring only helps until that happens.'
          : 'The server accepts the unit again. If it already asks for an '
                'activation code, enter its code on the unit as well.',
      action: revoked ? 'Revoke activation' : 'Restore activation',
      icon: revoked ? Icons.block_rounded : Icons.restore_rounded,
      color: revoked ? AppConstants.danger : AppConstants.success,
    );
    if (!confirmed || !mounted) return;
    await _run(() async {
      await ref
          .read(unitsProvider.notifier)
          .setRevoked(_unit.installId, revoked: revoked);
      if (mounted) {
        showUnitToast(
          context,
          revoked ? 'Activation revoked.' : 'Activation restored.',
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final minutes = checkInMinutes(
      _unit,
      ref.watch(fleetSettingsProvider).value,
    );
    final enabled = !_busy;

    PillActionButton button(
      String type,
      String label,
      VoidCallback onPressed, {
      Color color = AppConstants.primary,
    }) => PillActionButton(
      icon: commandIcon(type),
      label: label,
      color: color,
      onPressed: enabled ? onPressed : null,
    );

    return ContentSectionCard(
      title: 'Actions',
      subtitle:
          'Commands wait on the server until the unit checks in '
          '(${checkInHint(minutes)}).',
      icon: Icons.bolt_rounded,
      trailing: _busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_unit.revoked) ...[
            const UnitNotice(
              text:
                  'This unit\'s activation is revoked, so it can\'t check in '
                  'and won\'t receive commands until it is restored.',
              icon: Icons.block_rounded,
              color: AppConstants.danger,
            ),
            const SizedBox(height: AppConstants.space16),
          ],
          Wrap(
            spacing: AppConstants.space8,
            runSpacing: AppConstants.space8,
            children: [
              button(
                'ping',
                'Ping unit',
                () => _queue('ping'),
                color: AppConstants.info,
              ),
              button(
                'check_update',
                'Check for update',
                () => _queue('check_update'),
                color: AppConstants.info,
              ),
              button(
                'upload_crashes',
                'Upload crash reports',
                () => _queue('upload_crashes'),
                color: AppConstants.info,
              ),
              button(
                'add_wifi',
                'Add Wi-Fi network',
                () => _withArgs('add_wifi', showAddWifiDialog),
              ),
              button(
                'set_admin_pin',
                'Set admin PIN',
                () => _withArgs('set_admin_pin', showAdminPinDialog),
              ),
              button(
                'record_khutbah',
                'Record Khutbah sessions',
                () => _withArgs('record_khutbah', showRecordKhutbahDialog),
              ),
              button(
                'lock',
                'Lock unit',
                () => _withArgs('lock', showLockDialog),
                color: AppConstants.warning,
              ),
              button(
                'unlock',
                'Unlock unit',
                () => _queue('unlock'),
                color: AppConstants.success,
              ),
              button(
                'reboot',
                'Restart unit',
                () => _confirmThenQueue(
                  'reboot',
                  title: 'Restart this unit?',
                  body:
                      'The unit restarts when it picks this up at its next '
                      'check-in, and a session running then stops. Restarting '
                      'works only while the app is the device owner.',
                  action: 'Restart unit',
                ),
                color: AppConstants.warning,
              ),
              button(
                'reset_app',
                'Reset app',
                () => _confirmThenQueue(
                  'reset_app',
                  title: 'Reset the app on this unit?',
                  body:
                      'The app goes back to first-run setup and its saved '
                      'history is deleted. The unit stays activated.',
                  action: 'Reset app',
                  color: AppConstants.danger,
                ),
                color: AppConstants.danger,
              ),
              button(
                'clear_history',
                'Clear history',
                () => _confirmThenQueue(
                  'clear_history',
                  title: 'Clear this unit\'s history?',
                  body:
                      'Every past session saved on the unit is deleted. This '
                      'can\'t be undone.',
                  action: 'Clear history',
                  color: AppConstants.danger,
                ),
                color: AppConstants.danger,
              ),
            ],
          ),
          const SizedBox(height: AppConstants.space16),
          const Divider(height: 1, color: AppConstants.dividerColor),
          const SizedBox(height: AppConstants.space16),
          PillActionButton(
            icon: _unit.revoked ? Icons.restore_rounded : Icons.block_rounded,
            label: _unit.revoked ? 'Restore activation' : 'Revoke activation',
            color: _unit.revoked ? AppConstants.success : AppConstants.danger,
            onPressed: enabled ? () => _setRevoked(!_unit.revoked) : null,
          ),
        ],
      ),
    );
  }
}
