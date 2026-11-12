import 'dart:async';

import 'package:dio/dio.dart';
import 'package:emam_admin_web_app/core/network/api_error.dart';
import 'package:emam_admin_web_app/features/units/models/device_unit.dart';
import 'package:emam_admin_web_app/features/units/provider/units_repository_provider.dart';
import 'package:emam_admin_web_app/features/units/repository/units_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum UnitsTab { units, fleetSettings, updates, recordings, activationCodes }

final unitsTabProvider = NotifierProvider<UnitsTabNotifier, UnitsTab>(
  UnitsTabNotifier.new,
);

class UnitsTabNotifier extends Notifier<UnitsTab> {
  @override
  UnitsTab build() => UnitsTab.units;

  void select(UnitsTab tab) => state = tab;
}

/// The unit open in the side panel on wide screens.
final selectedUnitIdProvider = NotifierProvider<SelectedUnitNotifier, String?>(
  SelectedUnitNotifier.new,
);

class SelectedUnitNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? installId) => state = installId;
}

class UnitsSnapshot {
  const UnitsSnapshot({
    required this.units,
    required this.fetchedAt,
    this.refreshError,
  });

  final List<DeviceUnit> units;
  final DateTime fetchedAt;

  /// Set when the last background refresh failed and [units] are older.
  final String? refreshError;

  DeviceUnit? byId(String installId) {
    for (final unit in units) {
      if (unit.installId == installId) return unit;
    }
    return null;
  }

  UnitsSnapshot withRefreshError(String message) =>
      UnitsSnapshot(units: units, fetchedAt: fetchedAt, refreshError: message);
}

final unitsProvider =
    AsyncNotifierProvider.autoDispose<UnitsNotifier, UnitsSnapshot>(
      UnitsNotifier.new,
    );

class UnitsNotifier extends AsyncNotifier<UnitsSnapshot> {
  static const refreshEvery = Duration(seconds: 30);

  UnitsRepository get _repo => ref.read(unitsRepositoryProvider);

  @override
  Future<UnitsSnapshot> build() {
    final timer = Timer.periodic(refreshEvery, (_) => refresh());
    ref.onDispose(timer.cancel);
    return _load();
  }

  Future<UnitsSnapshot> _load() async =>
      UnitsSnapshot(units: await _repo.fetchUnits(), fetchedAt: DateTime.now());

  /// Reloads without the loading state; a failure keeps the last list.
  Future<void> refresh() async {
    if (!ref.mounted) return;
    try {
      final next = await _load();
      if (ref.mounted) state = AsyncData(next);
    } on DioException catch (error, stack) {
      if (!ref.mounted) return;
      final current = state.value;
      state = current == null
          ? AsyncError(error, stack)
          : AsyncData(current.withRefreshError(parseApiError(error)));
    }
  }

  /// These throw on failure so the caller can show the error.
  Future<void> rename(String installId, String name) async {
    await _repo.updateUnit(installId, name: name.trim());
    await refresh();
  }

  Future<void> updateSettings(
    String installId,
    Map<String, Object?> changes,
  ) async {
    await _repo.updateUnit(installId, settings: changes);
    await refresh();
  }

  Future<void> setRevoked(String installId, {required bool revoked}) async {
    if (revoked) {
      await _repo.revoke(installId);
    } else {
      await _repo.restore(installId);
    }
    await refresh();
  }
}
