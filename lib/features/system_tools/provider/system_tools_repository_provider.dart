import 'package:emam_admin_web_app/core/providers/core_providers.dart';
import 'package:emam_admin_web_app/features/system_tools/repository/system_tools_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final systemToolsRepositoryProvider = Provider<SystemToolsRepository>((ref) {
  return SystemToolsRepository(ref.watch(dioClientProvider));
});
