import 'package:emam_admin_web_app/core/providers/core_providers.dart';
import 'package:emam_admin_web_app/features/units/repository/units_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final unitsRepositoryProvider = Provider<UnitsRepository>((ref) {
  return UnitsRepository(ref.watch(dioClientProvider));
});
