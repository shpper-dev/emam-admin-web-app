import 'package:emam_admin_web_app/features/units/models/unit_json.dart';

/// An uploaded version of the unit app, from `GET /api/admin/device-releases`.
class UnitRelease {
  const UnitRelease({
    required this.versionCode,
    required this.versionName,
    required this.size,
    required this.sha256,
    required this.notes,
    required this.uploadedBy,
    required this.uploadedAt,
    required this.published,
    required this.targetsAll,
    required this.targetUnits,
    required this.publishedAt,
    required this.filePresent,
  });

  final int versionCode;
  final String versionName;
  final int size;
  final String sha256;
  final String notes;
  final String? uploadedBy;
  final DateTime? uploadedAt;
  final bool published;

  /// Published to every unit; otherwise only to [targetUnits].
  final bool targetsAll;
  final List<String> targetUnits;
  final DateTime? publishedAt;

  /// False when the APK is gone from the server's disk.
  final bool filePresent;

  factory UnitRelease.fromJson(Map<dynamic, dynamic> json) {
    final target = json['target'];
    final code = readInt(json['version_code']) ?? 0;
    return UnitRelease(
      versionCode: code,
      versionName: readString(json['version_name']) ?? '$code',
      size: readInt(json['size']) ?? 0,
      sha256: readString(json['sha256']) ?? '',
      notes: (readString(json['notes']) ?? '').trim(),
      uploadedBy: readString(json['uploaded_by']),
      uploadedAt: readDate(json['uploaded_at']),
      published: readBool(json['published']) ?? false,
      targetsAll: target == 'all',
      targetUnits: readStrings(target),
      publishedAt: readDate(json['published_at']),
      // The upload reply leaves this out; the file was just written then.
      filePresent: readBool(json['file_present']) ?? true,
    );
  }

  static List<UnitRelease> listFromJson(Map<dynamic, dynamic> json) => [
    for (final item in readMaps(json['releases'])) UnitRelease.fromJson(item),
  ];

  /// Delete is refused while a release is published.
  bool get canDelete => !published;
}
