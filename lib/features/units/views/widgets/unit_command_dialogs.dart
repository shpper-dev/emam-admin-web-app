import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:emam_admin_web_app/core/widgets/admin_alert_dialog.dart';
import 'package:emam_admin_web_app/core/widgets/dialog_submit_button.dart';
import 'package:emam_admin_web_app/features/units/views/widgets/unit_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Each dialog resolves to the command's arguments, or null when cancelled.
// The checks mirror the server's, so a queued command isn't refused.

Future<Map<String, Object?>?> showAdminPinDialog(BuildContext context) =>
    showDialog(context: context, builder: (_) => const _AdminPinDialog());

Future<Map<String, Object?>?> showAddWifiDialog(BuildContext context) =>
    showDialog(context: context, builder: (_) => const _AddWifiDialog());

Future<Map<String, Object?>?> showLockDialog(BuildContext context) =>
    showDialog(context: context, builder: (_) => const _LockDialog());

Future<Map<String, Object?>?> showRecordKhutbahDialog(BuildContext context) =>
    showDialog(context: context, builder: (_) => const _RecordKhutbahDialog());

Widget _intro(BuildContext context, String text) => Text(
  text,
  style: Theme.of(
    context,
  ).textTheme.bodyMedium?.copyWith(color: AppConstants.textSecondary),
);

Widget _cancel(BuildContext context) => TextButton(
  onPressed: () => Navigator.of(context).pop(),
  child: const Text('Cancel'),
);

class _AdminPinDialog extends StatefulWidget {
  const _AdminPinDialog();

  @override
  State<_AdminPinDialog> createState() => _AdminPinDialogState();
}

class _AdminPinDialogState extends State<_AdminPinDialog> {
  final _pin = TextEditingController();
  bool _visible = false;

  bool get _valid => RegExp(r'^\d{6,12}$').hasMatch(_pin.text);

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  void _submit() {
    if (_valid) Navigator.of(context).pop({'pin': _pin.text});
  }

  @override
  Widget build(BuildContext context) {
    return AdminAlertDialog(
      title: 'Set admin PIN',
      icon: Icons.pin_rounded,
      contentWidth: 400,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _intro(
            context,
            'The PIN guards service mode and Android settings on the unit. '
            'It replaces the current one.',
          ),
          const SizedBox(height: AppConstants.space16),
          TextField(
            controller: _pin,
            autofocus: true,
            obscureText: !_visible,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(12),
            ],
            style: const TextStyle(color: AppConstants.textPrimary),
            cursorColor: AppConstants.primary,
            decoration: unitInputDecoration(
              'New admin PIN',
              helper: '6 to 12 digits',
              suffix: IconButton(
                tooltip: _visible ? 'Hide PIN' : 'Show PIN',
                onPressed: () => setState(() => _visible = !_visible),
                icon: Icon(
                  _visible
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                ),
              ),
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        _cancel(context),
        DialogSubmitButton(
          label: 'Set PIN',
          color: AppConstants.primary,
          enabled: _valid,
          isSubmitting: false,
          onPressed: _submit,
        ),
      ],
    );
  }
}

class _AddWifiDialog extends StatefulWidget {
  const _AddWifiDialog();

  @override
  State<_AddWifiDialog> createState() => _AddWifiDialogState();
}

class _AddWifiDialogState extends State<_AddWifiDialog> {
  final _ssid = TextEditingController();
  final _password = TextEditingController();
  String _security = 'wpa2';
  bool _visible = false;

  bool get _open => _security == 'open';

  bool get _passwordValid =>
      _open || (_password.text.length >= 8 && _password.text.length <= 63);

  bool get _valid => _ssid.text.trim().isNotEmpty && _passwordValid;

  @override
  void dispose() {
    _ssid.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_valid) return;
    Navigator.of(context).pop({
      'ssid': _ssid.text.trim(),
      'security': _security,
      if (!_open) 'password': _password.text,
    });
  }

  @override
  Widget build(BuildContext context) {
    final showPasswordError = _password.text.isNotEmpty && !_passwordValid;
    return AdminAlertDialog(
      title: 'Add Wi-Fi network',
      icon: Icons.wifi_rounded,
      contentWidth: 420,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _intro(
            context,
            'The unit saves this network and joins it. Its other saved '
            'networks stay.',
          ),
          const SizedBox(height: AppConstants.space16),
          TextField(
            controller: _ssid,
            autofocus: true,
            style: const TextStyle(color: AppConstants.textPrimary),
            cursorColor: AppConstants.primary,
            decoration: unitInputDecoration('Network name (SSID)'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppConstants.space16),
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 'wpa2', label: Text('WPA2')),
              ButtonSegment(value: 'wpa3', label: Text('WPA3')),
              ButtonSegment(value: 'open', label: Text('Open')),
            ],
            selected: {_security},
            onSelectionChanged: (value) =>
                setState(() => _security = value.first),
          ),
          if (!_open) ...[
            const SizedBox(height: AppConstants.space16),
            TextField(
              controller: _password,
              obscureText: !_visible,
              style: const TextStyle(color: AppConstants.textPrimary),
              cursorColor: AppConstants.primary,
              decoration: unitInputDecoration(
                'Password',
                helper: showPasswordError ? null : '8 to 63 characters',
                error: showPasswordError ? 'Use 8 to 63 characters' : null,
                suffix: IconButton(
                  tooltip: _visible ? 'Hide password' : 'Show password',
                  onPressed: () => setState(() => _visible = !_visible),
                  icon: Icon(
                    _visible
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                  ),
                ),
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _submit(),
            ),
          ],
        ],
      ),
      actions: [
        _cancel(context),
        DialogSubmitButton(
          label: 'Add network',
          color: AppConstants.primary,
          enabled: _valid,
          isSubmitting: false,
          onPressed: _submit,
        ),
      ],
    );
  }
}

class _LockDialog extends StatefulWidget {
  const _LockDialog();

  @override
  State<_LockDialog> createState() => _LockDialogState();
}

class _LockDialogState extends State<_LockDialog> {
  final _message = TextEditingController();

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminAlertDialog(
      title: 'Lock unit',
      icon: Icons.lock_rounded,
      accentColor: AppConstants.warning,
      contentWidth: 420,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _intro(
            context,
            'The unit shows this message and can\'t be used until you unlock '
            'it.',
          ),
          const SizedBox(height: AppConstants.space16),
          TextField(
            controller: _message,
            autofocus: true,
            maxLines: 3,
            maxLength: 200,
            style: const TextStyle(color: AppConstants.textPrimary),
            cursorColor: AppConstants.primary,
            decoration: unitInputDecoration(
              'Message (optional)',
              helper:
                  'Leave empty for "This unit has been locked by its '
                  'administrator."',
            ),
          ),
        ],
      ),
      actions: [
        _cancel(context),
        DialogSubmitButton(
          label: 'Lock unit',
          color: AppConstants.warning,
          enabled: true,
          isSubmitting: false,
          onPressed: () =>
              Navigator.of(context).pop({'message': _message.text.trim()}),
        ),
      ],
    );
  }
}

class _RecordKhutbahDialog extends StatefulWidget {
  const _RecordKhutbahDialog();

  @override
  State<_RecordKhutbahDialog> createState() => _RecordKhutbahDialogState();
}

class _RecordKhutbahDialogState extends State<_RecordKhutbahDialog> {
  int _sessions = 1;

  @override
  Widget build(BuildContext context) {
    final count = _sessions == 1 ? 'session' : '$_sessions sessions';
    return AdminAlertDialog(
      title: 'Record Khutbah sessions',
      icon: Icons.mic_rounded,
      contentWidth: 420,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _intro(
            context,
            'The unit records its next Khutbah sessions and uploads them. '
            'They appear under Recordings.',
          ),
          const SizedBox(height: AppConstants.space16),
          Text(
            'Number of sessions',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: AppConstants.space8),
          SegmentedButton<int>(
            showSelectedIcon: false,
            segments: [
              for (var i = 1; i <= 5; i++)
                ButtonSegment(value: i, label: Text('$i')),
            ],
            selected: {_sessions},
            onSelectionChanged: (value) =>
                setState(() => _sessions = value.first),
          ),
        ],
      ),
      actions: [
        _cancel(context),
        DialogSubmitButton(
          label: 'Record next $count',
          color: AppConstants.primary,
          enabled: true,
          isSubmitting: false,
          onPressed: () => Navigator.of(context).pop({'sessions': _sessions}),
        ),
      ],
    );
  }
}
