import 'dart:async';

import 'package:dio/dio.dart';
import 'package:emam_admin_web_app/features/units/models/unit_command.dart';
import 'package:emam_admin_web_app/features/units/models/unit_crash_report.dart';
import 'package:emam_admin_web_app/features/units/provider/units_provider.dart';
import 'package:emam_admin_web_app/features/units/provider/units_repository_provider.dart';
import 'package:emam_admin_web_app/features/units/repository/units_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final unitCommandsProvider = AsyncNotifierProvider.autoDispose
    .family<UnitCommandsNotifier, List<UnitCommand>, String>(
      UnitCommandsNotifier.new,
    );

class UnitCommandsNotifier extends AsyncNotifier<List<UnitCommand>> {
  UnitCommandsNotifier(this.installId);

  final String installId;

  UnitsRepository get _repo => ref.read(unitsRepositoryProvider);

  @override
  Future<List<UnitCommand>> build() {
    final timer = Timer.periodic(UnitsNotifier.refreshEvery, (_) => refresh());
    ref.onDispose(timer.cancel);
    return _repo.fetchCommands(installId);
  }

  Future<void> refresh() async {
    if (!ref.mounted) return;
    try {
      final commands = await _repo.fetchCommands(installId);
      if (ref.mounted) state = AsyncData(commands);
    } on DioException catch (error, stack) {
      if (ref.mounted && state.value == null) state = AsyncError(error, stack);
    }
  }

  /// These throw on failure so the caller can show the error.
  Future<void> queue(
    String type, [
    Map<String, Object?> args = const {},
  ]) async {
    await _repo.queueCommand(installId, type, args);
    await refresh();
  }

  Future<void> cancel(String commandId) async {
    await _repo.cancelCommand(installId, commandId);
    await refresh();
  }
}

final unitCrashReportsProvider = FutureProvider.autoDispose
    .family<List<UnitCrashReport>, String>(
      (ref, installId) =>
          ref.watch(unitsRepositoryProvider).fetchCrashReports(installId),
    );
