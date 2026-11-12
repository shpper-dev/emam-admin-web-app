import 'package:emam_admin_web_app/features/units/models/unit_json.dart';

enum UnitCommandState { pending, sent, done, failed, cancelled, unknown }

/// A command queued for a unit, from
/// `GET /api/admin/devices/{install_id}/commands`.
class UnitCommand {
  const UnitCommand({
    required this.id,
    required this.type,
    required this.args,
    required this.state,
    required this.result,
    required this.createdBy,
    required this.createdAt,
    required this.sentAt,
    required this.doneAt,
  });

  final String id;
  final String type;

  /// Arguments as the server shows them, with the PIN and Wi-Fi password
  /// replaced by "•••".
  final Map<String, Object?> args;
  final UnitCommandState state;
  final String? result;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? sentAt;
  final DateTime? doneAt;

  factory UnitCommand.fromJson(Map<dynamic, dynamic> json) {
    return UnitCommand(
      id: readString(json['id']) ?? '',
      type: readString(json['type']) ?? '',
      args: readMap(json['args']),
      state: _state(json['state']),
      result: readString(json['result']),
      createdBy: readString(json['created_by']),
      createdAt: readDate(json['created_at']),
      sentAt: readDate(json['sent_at']),
      doneAt: readDate(json['done_at']),
    );
  }

  static List<UnitCommand> listFromJson(Map<dynamic, dynamic> json) => [
    for (final item in readMaps(json['commands'])) UnitCommand.fromJson(item),
  ];

  /// Only a command the unit hasn't fetched yet can be cancelled.
  bool get canCancel => state == UnitCommandState.pending;

  static UnitCommandState _state(Object? value) => switch (value) {
    'pending' => UnitCommandState.pending,
    'sent' => UnitCommandState.sent,
    'done' => UnitCommandState.done,
    'failed' => UnitCommandState.failed,
    'cancelled' => UnitCommandState.cancelled,
    _ => UnitCommandState.unknown,
  };
}
