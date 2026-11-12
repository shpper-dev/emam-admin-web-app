import 'package:emam_admin_web_app/core/utils/formatters.dart';
import 'package:emam_admin_web_app/features/units/models/unit_json.dart';

/// One E-mam handheld unit from `GET /api/admin/devices`, with the status it
/// reported at its last check-in.
class DeviceUnit {
  const DeviceUnit({
    required this.installId,
    required this.name,
    required this.label,
    required this.device,
    required this.revoked,
    required this.activatedAt,
    required this.lastSeenAt,
    required this.lastIp,
    required this.status,
    required this.statusAt,
    required this.versionCode,
    required this.versionName,
    required this.settings,
    required this.openCommands,
  });

  /// A unit counts as online only while its last check-in is this recent.
  static const onlineWindow = Duration(minutes: 15);

  final String installId;
  final String name;

  /// The label of the activation code the unit was activated with.
  final String label;

  /// What the unit sent when it was activated (manufacturer, model, ...).
  final Map<String, Object?> device;
  final bool revoked;
  final DateTime? activatedAt;
  final DateTime? lastSeenAt;
  final String? lastIp;
  final Map<String, Object?> status;
  final DateTime? statusAt;
  final int? versionCode;
  final String? versionName;

  /// The unit's own overrides of the fleet settings.
  final Map<String, Object?> settings;
  final int openCommands;

  factory DeviceUnit.fromJson(Map<dynamic, dynamic> json) {
    return DeviceUnit(
      installId: readString(json['install_id']) ?? '',
      name: (readString(json['name']) ?? '').trim(),
      label: (readString(json['label']) ?? '').trim(),
      device: readMap(json['device']),
      revoked: readBool(json['revoked']) ?? false,
      activatedAt: readDate(json['activated_at']),
      lastSeenAt: readDate(json['last_seen_at']),
      lastIp: readString(json['last_ip']),
      status: readMap(json['status']),
      statusAt: readDate(json['status_at']),
      versionCode: readInt(json['version_code']),
      versionName: readString(json['version_name']),
      settings: readMap(json['settings']),
      openCommands: readInt(json['open_commands']) ?? 0,
    );
  }

  String get displayName => name.isNotEmpty ? name : shortId(installId);

  String? get serial => readString(status['serial']);

  String? get model =>
      readString(status['model']) ?? readString(device['model']);

  String? get manufacturer => readString(device['manufacturer']);

  /// The version from the last check-in, else the one it was activated with.
  String? get appVersion {
    final name = versionName ?? readString(device['app_version']);
    final code = versionCode;
    if (name == null) return code?.toString();
    return code == null ? name : '$name ($code)';
  }

  int? get battery => readInt(status['battery']);

  bool get charging => readBool(status['charging']) ?? false;

  bool? get wifiOn => readBool(status['wifi_on']);

  String? get wifiSsid => readString(status['wifi_ssid']);

  int? get wifiBars => readInt(status['wifi_bars']);

  String? get language => readString(status['language']);

  bool get locked => readBool(status['locked']) ?? false;

  int get crashes => readInt(status['crashes']) ?? 0;

  /// What the unit's updater is doing, e.g. "Downloading 0.1.5".
  String? get updateState => readString(status['update']);

  bool get updateFailed => updateState?.startsWith('Update failed') ?? false;

  /// The unit's third button sends Back, which the app treats as Speech.
  bool get backIsSpeech => readBool(status['back_is_speech']) ?? false;

  bool isOnline(DateTime now) {
    final at = statusAt;
    return at != null &&
        readBool(status['online']) == true &&
        now.difference(at) < onlineWindow;
  }

  /// The latest sign of life: a check-in or any other request from the unit.
  DateTime? get lastContactAt {
    final checkIn = statusAt;
    final seen = lastSeenAt;
    if (checkIn == null) return seen;
    if (seen == null) return checkIn;
    return seen.isAfter(checkIn) ? seen : checkIn;
  }
}
