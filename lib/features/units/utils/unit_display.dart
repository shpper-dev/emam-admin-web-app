import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:emam_admin_web_app/core/utils/formatters.dart';
import 'package:emam_admin_web_app/features/units/models/device_unit.dart';
import 'package:emam_admin_web_app/features/units/models/unit_command.dart';
import 'package:emam_admin_web_app/features/units/models/unit_json.dart';
import 'package:emam_admin_web_app/features/units/models/unit_settings.dart';
import 'package:flutter/material.dart';

/// The unit app reports Wi-Fi strength as 0 to this many bars.
const kUnitWifiMaxBars = 4;

/// "just now", "5 min ago", "3 h ago", "2 days ago", or the date after a month.
String relativeTime(DateTime then, DateTime now) {
  final diff = now.difference(then);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inHours < 1) return '${diff.inMinutes} min ago';
  if (diff.inDays < 1) return '${diff.inHours} h ago';
  if (diff.inDays < 30) {
    return diff.inDays == 1 ? '1 day ago' : '${diff.inDays} days ago';
  }
  return 'on ${formatAdminDate(then)}';
}

/// Local time as `HH:MM:SS`.
String clockTime(DateTime time) {
  final local = time.toLocal();
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(local.hour)}:${two(local.minute)}:${two(local.second)}';
}

/// "Online", or when the unit was last heard from.
String presenceLabel(DeviceUnit unit, DateTime now) {
  if (unit.isOnline(now)) return 'Online';
  final last = unit.lastContactAt;
  if (last == null) return 'Not checked in yet';
  return 'Last seen ${relativeTime(last, now)}';
}

String formatFileSize(int bytes) {
  if (bytes < 1000) return '$bytes B';
  if (bytes < 1000000) return '${(bytes / 1000).toStringAsFixed(0)} KB';
  if (bytes < 1000000000) return '${(bytes / 1e6).toStringAsFixed(1)} MB';
  return '${(bytes / 1e9).toStringAsFixed(2)} GB';
}

String formatMegabytes(int megabytes) => megabytes < 1000
    ? '$megabytes MB'
    : '${(megabytes / 1000).toStringAsFixed(1)} GB';

String formatUptime(int minutes) {
  if (minutes < 60) return '$minutes min';
  final hours = minutes ~/ 60;
  if (hours < 24) {
    final rest = minutes % 60;
    return rest == 0 ? '$hours h' : '$hours h $rest min';
  }
  final days = hours ~/ 24;
  final restHours = hours % 24;
  final dayText = days == 1 ? '1 day' : '$days days';
  return restHours == 0 ? dayText : '$dayText $restHours h';
}

/// Interface languages of the unit app.
const kUnitLanguageNames = <String, String>{
  'en': 'English',
  'ar': 'Arabic',
  'bn': 'Bengali',
  'ur': 'Urdu',
  'hi': 'Hindi',
  'id': 'Indonesian',
  'ms': 'Malay',
  'tr': 'Turkish',
  'fr': 'French',
  'de': 'German',
  'es': 'Spanish',
  'it': 'Italian',
  'pt': 'Portuguese',
  'nl': 'Dutch',
  'pl': 'Polish',
  'ru': 'Russian',
  'fil': 'Filipino',
  'th': 'Thai',
  'vi': 'Vietnamese',
  'zh': 'Chinese',
  'ja': 'Japanese',
  'ko': 'Korean',
};

String languageName(String code) => kUnitLanguageNames[code] ?? code;

/// "free_storage_mb" -> "Free storage mb", for keys this panel doesn't know.
String humanizeKey(String key) => titleCase(key.replaceAll('_', ' ').trim());

String choiceLabel(String choice) => titleCase(choice.replaceAll('_', ' '));

String settingValueLabel(UnitSettingSpec spec, Object? value) {
  if (value == null) return 'Not set';
  return switch (spec.type) {
    UnitSettingType.choice => choiceLabel(value.toString()),
    UnitSettingType.boolean => value == true ? 'On' : 'Off',
    _ => value.toString(),
  };
}

String batterySummary(DeviceUnit unit) {
  final level = unit.battery;
  if (level == null) return 'Battery unknown';
  return unit.charging ? '$level%, charging' : '$level%';
}

String wifiSummary(DeviceUnit unit) {
  if (unit.wifiOn == false) return 'Wi-Fi off';
  final ssid = unit.wifiSsid;
  if (ssid == null) return 'No Wi-Fi network';
  final bars = unit.wifiBars;
  return bars == null ? ssid : '$ssid · $bars/$kUnitWifiMaxBars';
}

/// How often the unit checks in, from its own setting or the fleet's.
int? checkInMinutes(DeviceUnit unit, FleetSettings? fleet) => readInt(
  unit.settings['checkin_minutes'] ?? fleet?.fleetValue('checkin_minutes'),
);

String checkInHint(int? minutes) {
  if (minutes == null) return 'every few minutes';
  return minutes == 1 ? 'every minute' : 'every $minutes minutes';
}

String queuedMessage(String type, DeviceUnit unit, int? minutes) =>
    '${commandLabel(type)} queued. ${unit.displayName} picks it up at its '
    'next check-in (${checkInHint(minutes)}).';

const kUnitCommandLabels = <String, String>{
  'ping': 'Ping',
  'reboot': 'Restart',
  'check_update': 'Check for update',
  'set_admin_pin': 'Set admin PIN',
  'add_wifi': 'Add Wi-Fi network',
  'lock': 'Lock',
  'unlock': 'Unlock',
  'reset_app': 'Reset app',
  'clear_history': 'Clear history',
  'record_khutbah': 'Record Khutbah',
  'upload_crashes': 'Upload crash reports',
};

String commandLabel(String type) =>
    kUnitCommandLabels[type] ?? humanizeKey(type);

IconData commandIcon(String type) => switch (type) {
  'ping' => Icons.network_ping_rounded,
  'reboot' => Icons.restart_alt_rounded,
  'check_update' => Icons.system_update_rounded,
  'set_admin_pin' => Icons.pin_rounded,
  'add_wifi' => Icons.wifi_rounded,
  'lock' => Icons.lock_rounded,
  'unlock' => Icons.lock_open_rounded,
  'reset_app' => Icons.settings_backup_restore_rounded,
  'clear_history' => Icons.delete_sweep_rounded,
  'record_khutbah' => Icons.mic_rounded,
  'upload_crashes' => Icons.bug_report_rounded,
  _ => Icons.bolt_rounded,
};

/// A short line for a command's arguments, or null when it has none.
String? describeCommandArgs(String type, Map<String, Object?> args) {
  if (args.isEmpty) return null;
  switch (type) {
    case 'add_wifi':
      final security = readString(args['security']);
      return [
        readString(args['ssid']) ?? 'No name',
        if (security != null) security.toUpperCase(),
        if (readString(args['password']) != null) 'password •••',
      ].join(' · ');
    case 'set_admin_pin':
      return 'PIN •••';
    case 'lock':
      final message = readString(args['message'])?.trim() ?? '';
      return message.isEmpty ? 'Default message' : '"$message"';
    case 'record_khutbah':
      final sessions = readInt(args['sessions']) ?? 1;
      return sessions == 1 ? '1 session' : '$sessions sessions';
  }
  return [
    for (final entry in args.entries) '${entry.key}: ${entry.value}',
  ].join(', ');
}

(String, Color) commandStateLabel(UnitCommandState state) => switch (state) {
  UnitCommandState.pending => ('Waiting', AppConstants.warning),
  UnitCommandState.sent => ('Sent', AppConstants.info),
  UnitCommandState.done => ('Done', AppConstants.success),
  UnitCommandState.failed => ('Failed', AppConstants.danger),
  UnitCommandState.cancelled => ('Cancelled', AppConstants.textMuted),
  UnitCommandState.unknown => ('Unknown', AppConstants.textMuted),
};

class UnitFlag {
  const UnitFlag(this.label, this.color, {this.tooltip});

  final String label;
  final Color color;
  final String? tooltip;
}

List<UnitFlag> unitFlags(DeviceUnit unit) {
  final update = unit.updateState;
  return [
    if (unit.revoked)
      const UnitFlag(
        'Revoked',
        AppConstants.danger,
        tooltip: 'Its activation is revoked, so it cannot use Emam.',
      ),
    if (unit.locked) const UnitFlag('Locked', AppConstants.warning),
    if (unit.crashes > 0)
      UnitFlag(
        unit.crashes == 1 ? '1 crash report' : '${unit.crashes} crash reports',
        AppConstants.danger,
        tooltip: 'Crash reports saved on the unit',
      ),
    if (unit.openCommands > 0)
      UnitFlag(
        unit.openCommands == 1
            ? '1 open command'
            : '${unit.openCommands} open commands',
        AppConstants.info,
        tooltip: 'Queued or sent, and not finished yet',
      ),
    if (update != null)
      UnitFlag(
        update,
        unit.updateFailed ? AppConstants.danger : AppConstants.info,
      ),
    if (unit.backIsSpeech)
      const UnitFlag(
        'Button 3 = Back',
        AppConstants.textMuted,
        tooltip: 'Its third button sends Back, which the app treats as Speech.',
      ),
  ];
}

class UnitStatusEntry {
  const UnitStatusEntry(this.label, this.value);

  final String label;
  final String value;
}

class UnitStatusGroup {
  const UnitStatusGroup(this.title, this.entries);

  final String title;
  final List<UnitStatusEntry> entries;
}

const _statusLabels = <String, String>{
  'online': 'Internet',
  'wifi_on': 'Wi-Fi',
  'wifi_ssid': 'Wi-Fi network',
  'wifi_bars': 'Wi-Fi signal',
  'battery': 'Battery',
  'uptime_min': 'Time since restart',
  'active': 'Session running',
  'language': 'Interface language',
  'locked': 'Locked',
  'setup_done': 'First-run setup',
  'admin_pin_set': 'Admin PIN',
  'auto_update': 'Automatic updates',
  'update': 'Update',
  'mic_mode': 'Khutbah microphone',
  'back_key': 'Back key',
  'back_is_speech': 'Back key starts Speech',
  'confidence_gate': 'Hold back unclear speech',
  'history_sessions': 'Sessions in history',
  'record_sessions': 'Sessions left to record',
  'pending_recordings': 'Recordings waiting to upload',
  'crashes': 'Crash reports on the unit',
  'model': 'Model',
  'android': 'Android version',
  'firmware': 'Firmware',
  'serial': 'Serial number',
  'system_language': 'Android language',
  'time_zone': 'Time zone',
  'free_storage_mb': 'Free storage',
  'free_memory_mb': 'Free memory',
  'device_owner': 'Device owner',
  'lock_task': 'Kiosk mode',
};

const _statusGroups = <(String, List<String>)>[
  ('Connection', ['online', 'wifi_on', 'wifi_ssid', 'wifi_bars']),
  ('Power', ['battery', 'uptime_min']),
  (
    'App',
    [
      'active',
      'language',
      'locked',
      'setup_done',
      'admin_pin_set',
      'auto_update',
      'update',
      'mic_mode',
      'back_key',
      'back_is_speech',
      'confidence_gate',
      'history_sessions',
      'record_sessions',
      'pending_recordings',
      'crashes',
    ],
  ),
  (
    'Device',
    [
      'model',
      'serial',
      'android',
      'firmware',
      'system_language',
      'time_zone',
      'free_storage_mb',
      'free_memory_mb',
      'device_owner',
      'lock_task',
    ],
  ),
];

String statusLabel(String key) => _statusLabels[key] ?? humanizeKey(key);

String statusValue(String key, Map<String, Object?> status) {
  final value = status[key];
  String pick(String yes, String no) => value == true
      ? yes
      : value == false
      ? no
      : 'Unknown';

  switch (key) {
    case 'online':
      return pick('Connected', 'Not connected');
    case 'wifi_on' || 'auto_update' || 'confidence_gate' || 'lock_task':
      return pick('On', 'Off');
    case 'locked':
      return pick('Locked', 'Not locked');
    case 'setup_done':
      return pick('Done', 'Not done');
    case 'admin_pin_set':
      return pick('Set', 'Not set');
    case 'back_is_speech' || 'device_owner':
      return pick('Yes', 'No');
    case 'wifi_ssid':
      return readString(value) ?? 'None';
    case 'wifi_bars':
      final bars = readInt(value);
      return bars == null ? 'Unknown' : '$bars of $kUnitWifiMaxBars bars';
    case 'battery':
      final level = readInt(value);
      if (level == null) return 'Unknown';
      return readBool(status['charging']) == true
          ? '$level%, charging'
          : '$level%';
    case 'uptime_min':
      final minutes = readInt(value);
      return minutes == null ? 'Unknown' : formatUptime(minutes);
    case 'free_storage_mb' || 'free_memory_mb':
      final megabytes = readInt(value);
      return megabytes == null ? 'Unknown' : formatMegabytes(megabytes);
    case 'active':
      return readString(value) ?? 'None';
    case 'update':
      return readString(value) ?? 'Nothing pending';
    case 'language':
      final code = readString(value);
      return code == null ? 'Unknown' : '${languageName(code)} ($code)';
    case 'mic_mode' || 'back_key':
      final choice = readString(value);
      return choice == null ? 'Unknown' : choiceLabel(choice);
  }
  if (value is bool) return value ? 'Yes' : 'No';
  return readString(value) ?? 'Unknown';
}

String _when(DateTime? time, DateTime now, {String never = 'Never'}) {
  if (time == null) return never;
  return '${relativeTime(time, now)} '
      '(${formatAdminDate(time, includeTime: true)})';
}

/// Everything known about a unit, grouped and labelled for people. Status
/// keys this panel doesn't know yet are shown under "Other".
List<UnitStatusGroup> describeStatus(DeviceUnit unit, DateTime now) {
  final status = unit.status;
  final shown = <String>{'charging'};

  List<UnitStatusEntry> entries(List<String> keys) => [
    for (final key in keys)
      if (status.containsKey(key) && shown.add(key))
        UnitStatusEntry(statusLabel(key), statusValue(key, status)),
  ];

  final groups = <UnitStatusGroup>[];
  for (final (title, keys) in _statusGroups) {
    final extra = <UnitStatusEntry>[
      if (title == 'Connection') ...[
        UnitStatusEntry('Last check-in', _when(unit.statusAt, now)),
        UnitStatusEntry('Last seen', _when(unit.lastSeenAt, now)),
        UnitStatusEntry('Last IP address', unit.lastIp ?? 'Unknown'),
      ],
      if (title == 'App')
        UnitStatusEntry('App version', unit.appVersion ?? 'Unknown'),
      if (title == 'Device' && unit.manufacturer != null)
        UnitStatusEntry('Manufacturer', unit.manufacturer!),
    ];
    final all = [...extra, ...entries(keys)];
    if (all.isNotEmpty) groups.add(UnitStatusGroup(title, all));
  }

  groups.add(
    UnitStatusGroup('Activation', [
      UnitStatusEntry('Activation', unit.revoked ? 'Revoked' : 'Active'),
      UnitStatusEntry(
        'Activated',
        _when(unit.activatedAt, now, never: 'Unknown'),
      ),
      UnitStatusEntry(
        'Activation code label',
        unit.label.isEmpty ? 'None' : unit.label,
      ),
      UnitStatusEntry('Install ID', unit.installId),
    ]),
  );

  final other = entries(status.keys.toList()..sort());
  if (other.isNotEmpty) groups.add(UnitStatusGroup('Other', other));
  return groups;
}
