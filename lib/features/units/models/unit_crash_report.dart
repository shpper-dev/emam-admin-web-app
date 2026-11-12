import 'package:emam_admin_web_app/features/units/models/unit_json.dart';

/// A crash report a unit uploaded, from
/// `GET /api/admin/devices/{install_id}/crashes`.
class UnitCrashReport {
  const UnitCrashReport({
    required this.name,
    required this.text,
    required this.receivedAt,
  });

  final String name;
  final String text;
  final DateTime? receivedAt;

  factory UnitCrashReport.fromJson(Map<dynamic, dynamic> json) {
    return UnitCrashReport(
      name: readString(json['name']) ?? 'crash',
      text: json['text'] is String ? json['text'] as String : '',
      receivedAt: readDate(json['received_at']),
    );
  }

  static List<UnitCrashReport> listFromJson(Map<dynamic, dynamic> json) => [
    for (final item in readMaps(json['crashes']))
      UnitCrashReport.fromJson(item),
  ];
}
