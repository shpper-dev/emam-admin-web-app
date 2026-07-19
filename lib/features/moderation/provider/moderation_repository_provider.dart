import 'package:emam_admin_web_app/core/providers/core_providers.dart';
import 'package:emam_admin_web_app/features/moderation/repository/moderation_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final moderationRepositoryProvider = Provider<ModerationRepository>((ref) {
  return ModerationRepository(ref.watch(dioClientProvider));
});
