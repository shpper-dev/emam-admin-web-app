import 'package:emam_admin_web_app/core/providers/core_providers.dart';
import 'package:emam_admin_web_app/features/content/repository/content_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final contentRepositoryProvider = Provider<ContentRepository>((ref) {
  return ContentRepository(ref.watch(dioClientProvider));
});
