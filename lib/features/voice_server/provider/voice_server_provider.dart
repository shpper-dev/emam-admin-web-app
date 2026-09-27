import 'dart:async';

import 'package:dio/dio.dart';
import 'package:emam_admin_web_app/core/network/api_error.dart';
import 'package:emam_admin_web_app/features/voice_server/models/voice_server_status.dart';
import 'package:emam_admin_web_app/features/voice_server/provider/voice_server_repository_provider.dart';
import 'package:emam_admin_web_app/features/voice_server/repository/voice_server_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final voiceServerProvider =
    AsyncNotifierProvider.autoDispose<VoiceServerNotifier, VoiceServerStatus>(
      VoiceServerNotifier.new,
    );

class VoiceServerNotifier extends AsyncNotifier<VoiceServerStatus> {
  Timer? _poll;

  @override
  Future<VoiceServerStatus> build() async {
    ref.onDispose(() => _poll?.cancel());
    final status = await ref.read(voiceServerRepositoryProvider).fetchStatus();
    _schedulePoll(status);
    return status;
  }

  /// Returns an error message, or null when the switch was accepted.
  Future<String?> turnOn() => _apply((repo) => repo.turnOn());

  Future<String?> turnOff() => _apply((repo) => repo.turnOff());

  Future<String?> _apply(
    Future<VoiceServerStatus> Function(VoiceServerRepository repo) action,
  ) async {
    try {
      final status = await action(ref.read(voiceServerRepositoryProvider));
      if (ref.mounted) {
        state = AsyncData(status);
        _schedulePoll(status);
      }
      return null;
    } on DioException catch (error) {
      return parseApiError(error);
    }
  }

  Future<void> _refresh() async {
    try {
      final status = await ref
          .read(voiceServerRepositoryProvider)
          .fetchStatus();
      if (!ref.mounted) return;
      state = AsyncData(status);
      _schedulePoll(status);
    } on DioException {
      if (ref.mounted) _poll = Timer(const Duration(seconds: 10), _refresh);
    }
  }

  // Every few seconds while switching, every half minute while on for the
  // running time, not at all while off.
  void _schedulePoll(VoiceServerStatus status) {
    _poll?.cancel();
    final Duration? every = status.isTransitioning
        ? const Duration(seconds: 5)
        : status.phase == VoiceServerPhase.ready
        ? const Duration(seconds: 30)
        : null;
    if (every != null) _poll = Timer(every, _refresh);
  }
}
