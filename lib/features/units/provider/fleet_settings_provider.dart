import 'package:emam_admin_web_app/features/units/models/unit_settings.dart';
import 'package:emam_admin_web_app/features/units/provider/units_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final fleetSettingsProvider =
    AsyncNotifierProvider.autoDispose<FleetSettingsNotifier, FleetSettings>(
      FleetSettingsNotifier.new,
    );

class FleetSettingsNotifier extends AsyncNotifier<FleetSettings> {
  @override
  Future<FleetSettings> build() =>
      ref.read(unitsRepositoryProvider).fetchFleetSettings();

  /// Throws on failure so the caller can show the error.
  Future<void> save(Map<String, Object?> changes) async {
    final values = await ref
        .read(unitsRepositoryProvider)
        .saveFleetSettings(changes);
    final current = state.value;
    if (ref.mounted && current != null) {
      state = AsyncData(current.withValues(values));
    }
  }
}
