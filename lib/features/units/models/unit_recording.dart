import 'package:emam_admin_web_app/features/units/models/unit_json.dart';

/// A Khutbah session a unit recorded and uploaded.
class UnitRecording {
  const UnitRecording({
    required this.installId,
    required this.name,
    required this.size,
    required this.modified,
    required this.complete,
  });

  final String installId;
  final String name;
  final int size;
  final DateTime? modified;

  /// False while the unit is still uploading it; only a complete recording
  /// can be downloaded or deleted.
  final bool complete;

  factory UnitRecording.fromJson(Map<dynamic, dynamic> json) {
    return UnitRecording(
      installId: readString(json['install_id']) ?? '',
      name: readString(json['name']) ?? '',
      size: readInt(json['size']) ?? 0,
      modified: readEpochSeconds(json['modified']),
      complete: readBool(json['complete']) ?? false,
    );
  }
}

/// `GET /api/admin/device-recordings`.
class UnitRecordings {
  const UnitRecordings({required this.recordings, required this.diskFreeGb});

  final List<UnitRecording> recordings;
  final double? diskFreeGb;

  factory UnitRecordings.fromJson(Map<dynamic, dynamic> json) {
    return UnitRecordings(
      recordings: [
        for (final item in readMaps(json['recordings']))
          UnitRecording.fromJson(item),
      ],
      diskFreeGb: readDouble(json['disk_free_gb']),
    );
  }

  UnitRecordings without(UnitRecording recording) => UnitRecordings(
    recordings: [
      for (final item in recordings)
        if (item.installId != recording.installId ||
            item.name != recording.name)
          item,
    ],
    diskFreeGb: diskFreeGb,
  );
}
