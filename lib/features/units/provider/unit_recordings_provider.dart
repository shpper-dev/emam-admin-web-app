import 'package:dio/dio.dart';
import 'package:emam_admin_web_app/features/units/models/unit_recording.dart';
import 'package:emam_admin_web_app/features/units/provider/units_repository_provider.dart';
import 'package:emam_admin_web_app/features/units/repository/units_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final unitRecordingsProvider =
    AsyncNotifierProvider.autoDispose<UnitRecordingsNotifier, UnitRecordings>(
      UnitRecordingsNotifier.new,
    );

class UnitRecordingsNotifier extends AsyncNotifier<UnitRecordings> {
  UnitsRepository get _repo => ref.read(unitsRepositoryProvider);

  @override
  Future<UnitRecordings> build() => _repo.fetchRecordings();

  Future<void> refresh() async {
    if (!ref.mounted) return;
    try {
      final recordings = await _repo.fetchRecordings();
      if (ref.mounted) state = AsyncData(recordings);
    } on DioException catch (error, stack) {
      if (ref.mounted && state.value == null) state = AsyncError(error, stack);
    }
  }

  /// Throws on failure so the caller can show the error.
  Future<void> delete(UnitRecording recording) async {
    await _repo.deleteRecording(recording.installId, recording.name);
    final current = state.value;
    if (ref.mounted && current != null) {
      state = AsyncData(current.without(recording));
    }
  }
}
