import 'package:emam_admin_web_app/core/providers/core_providers.dart';
import 'package:emam_admin_web_app/features/voice_server/repository/voice_server_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final voiceServerRepositoryProvider = Provider<VoiceServerRepository>((ref) {
  return VoiceServerRepository(ref.watch(dioClientProvider));
});
