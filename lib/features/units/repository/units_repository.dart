import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:emam_admin_web_app/core/constants/api_constants.dart';
import 'package:emam_admin_web_app/core/network/dio_client.dart';
import 'package:emam_admin_web_app/features/units/models/device_unit.dart';
import 'package:emam_admin_web_app/features/units/models/unit_command.dart';
import 'package:emam_admin_web_app/features/units/models/unit_crash_report.dart';
import 'package:emam_admin_web_app/features/units/models/unit_json.dart';
import 'package:emam_admin_web_app/features/units/models/unit_recording.dart';
import 'package:emam_admin_web_app/features/units/models/unit_release.dart';
import 'package:emam_admin_web_app/features/units/models/unit_settings.dart';

class UnitsRepository {
  UnitsRepository(this._client);

  final DioClient _client;

  static const apkContentType = 'application/vnd.android.package-archive';

  // APKs (up to 60 MB) and recordings (up to 200 MB) need far longer than the
  // client's default; on web the request is cut off after connect + receive.
  static const _transferTimeout = Duration(minutes: 15);

  Future<List<DeviceUnit>> fetchUnits() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.units,
    );
    return [
      for (final item in readMaps(response.data?['devices']))
        DeviceUnit.fromJson(item),
    ];
  }

  /// A null in [settings] removes the unit's own value for that key.
  Future<void> updateUnit(
    String installId, {
    String? name,
    Map<String, Object?>? settings,
  }) async {
    await _client.patch<Object>(
      ApiConstants.unit(installId),
      data: {'name': ?name, 'settings': ?settings},
    );
  }

  Future<void> revoke(String installId) async {
    await _client.post<Object>(ApiConstants.unitRevoke(installId));
  }

  Future<void> restore(String installId) async {
    await _client.post<Object>(ApiConstants.unitRestore(installId));
  }

  Future<List<UnitCommand>> fetchCommands(String installId) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.unitCommands(installId),
    );
    return UnitCommand.listFromJson(response.data ?? const {});
  }

  /// Returns the new command's id.
  Future<String> queueCommand(
    String installId,
    String type, [
    Map<String, Object?> args = const {},
  ]) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.unitCommands(installId),
      data: {'type': type, 'args': args},
    );
    return readString(response.data?['id']) ?? '';
  }

  Future<void> cancelCommand(String installId, String commandId) async {
    await _client.delete<Object>(
      ApiConstants.unitCommand(installId, commandId),
    );
  }

  Future<List<UnitCrashReport>> fetchCrashReports(String installId) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.unitCrashes(installId),
    );
    return UnitCrashReport.listFromJson(response.data ?? const {});
  }

  Future<FleetSettings> fetchFleetSettings() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.unitSettings,
    );
    return FleetSettings.fromJson(response.data ?? const {});
  }

  /// Returns the fleet values after the change.
  Future<Map<String, Object?>> saveFleetSettings(
    Map<String, Object?> values,
  ) async {
    final response = await _client.put<Map<String, dynamic>>(
      ApiConstants.unitSettings,
      data: {'values': values},
    );
    return readMap(response.data?['values']);
  }

  Future<List<UnitRelease>> fetchReleases() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.unitReleases,
    );
    return UnitRelease.listFromJson(response.data ?? const {});
  }

  /// The server reads the version from the APK itself.
  Future<UnitRelease> uploadRelease(
    Uint8List apk, {
    String notes = '',
    ProgressCallback? onProgress,
  }) async {
    final trimmed = notes.trim();
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.unitReleases,
      data: apk,
      queryParameters: {if (trimmed.isNotEmpty) 'notes': trimmed},
      options: Options(
        contentType: apkContentType,
        receiveTimeout: _transferTimeout,
      ),
      onSendProgress: onProgress,
    );
    return UnitRelease.fromJson(response.data ?? const {});
  }

  /// Publishes to every unit, or only to [unitIds] when given.
  Future<void> publishRelease(int versionCode, {List<String>? unitIds}) async {
    await _client.post<Object>(
      ApiConstants.unitReleasePublish(versionCode),
      data: {'target': unitIds ?? 'all'},
    );
  }

  Future<void> unpublishRelease(int versionCode) async {
    await _client.post<Object>(ApiConstants.unitReleaseUnpublish(versionCode));
  }

  Future<void> deleteRelease(int versionCode) async {
    await _client.delete<Object>(ApiConstants.unitRelease(versionCode));
  }

  Future<UnitRecordings> fetchRecordings() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.unitRecordings,
    );
    return UnitRecordings.fromJson(response.data ?? const {});
  }

  Future<Uint8List> downloadRecording(
    String installId,
    String name, {
    ProgressCallback? onProgress,
  }) async {
    final response = await _client.get<List<int>>(
      ApiConstants.unitRecording(installId, name),
      options: Options(
        responseType: ResponseType.bytes,
        receiveTimeout: _transferTimeout,
      ),
      onReceiveProgress: onProgress,
    );
    final data = response.data ?? const <int>[];
    return data is Uint8List ? data : Uint8List.fromList(data);
  }

  Future<void> deleteRecording(String installId, String name) async {
    await _client.delete<Object>(ApiConstants.unitRecording(installId, name));
  }

  /// The codes are only ever returned here; the server keeps their hashes.
  Future<List<String>> createActivationCodes({
    required int count,
    String label = '',
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.unitActivationCodes,
      data: {'count': count, 'label': label.trim()},
    );
    return readStrings(response.data?['codes']);
  }
}
