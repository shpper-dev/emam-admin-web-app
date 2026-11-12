import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:emam_admin_web_app/features/units/models/unit_release.dart';
import 'package:emam_admin_web_app/features/units/provider/units_repository_provider.dart';
import 'package:emam_admin_web_app/features/units/repository/units_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final unitReleasesProvider =
    AsyncNotifierProvider.autoDispose<UnitReleasesNotifier, List<UnitRelease>>(
      UnitReleasesNotifier.new,
    );

class UnitReleasesNotifier extends AsyncNotifier<List<UnitRelease>> {
  UnitsRepository get _repo => ref.read(unitsRepositoryProvider);

  @override
  Future<List<UnitRelease>> build() => _repo.fetchReleases();

  Future<void> refresh() async {
    if (!ref.mounted) return;
    try {
      final releases = await _repo.fetchReleases();
      if (ref.mounted) state = AsyncData(releases);
    } on DioException catch (error, stack) {
      if (ref.mounted && state.value == null) state = AsyncError(error, stack);
    }
  }

  /// These throw on failure so the caller can show the server's reason.
  Future<UnitRelease> upload(
    Uint8List apk, {
    String notes = '',
    ProgressCallback? onProgress,
  }) async {
    final release = await _repo.uploadRelease(
      apk,
      notes: notes,
      onProgress: onProgress,
    );
    await refresh();
    return release;
  }

  Future<void> publish(int versionCode, {List<String>? unitIds}) async {
    await _repo.publishRelease(versionCode, unitIds: unitIds);
    await refresh();
  }

  Future<void> unpublish(int versionCode) async {
    await _repo.unpublishRelease(versionCode);
    await refresh();
  }

  Future<void> delete(int versionCode) async {
    await _repo.deleteRelease(versionCode);
    await refresh();
  }
}
