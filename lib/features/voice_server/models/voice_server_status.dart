enum VoiceServerPhase {
  notConfigured,
  off,
  starting,
  loadingVoice,
  ready,
  stopping,
  unavailable,
}

class VoiceServerStatus {
  const VoiceServerStatus({
    required this.configured,
    required this.state,
    required this.ready,
    required this.runningMinutes,
    required this.estimatedCostUsd,
    required this.hourlyCostUsd,
    required this.idleShutdownMinutes,
    required this.activeSessions,
  });

  factory VoiceServerStatus.fromJson(Map<String, dynamic> json) {
    return VoiceServerStatus(
      configured: json['configured'] == true,
      state: (json['state'] as String?) ?? 'unknown',
      ready: json['ready'] == true,
      runningMinutes: (json['running_minutes'] as num?)?.toInt() ?? 0,
      estimatedCostUsd: (json['estimated_cost_usd'] as num?)?.toDouble() ?? 0,
      hourlyCostUsd: (json['hourly_cost_usd'] as num?)?.toDouble() ?? 0,
      idleShutdownMinutes:
          (json['idle_shutdown_minutes'] as num?)?.toInt() ?? 0,
      activeSessions: (json['active_sessions'] as num?)?.toInt() ?? 0,
    );
  }

  final bool configured;
  final String state;
  final bool ready;
  final int runningMinutes;
  final double estimatedCostUsd;
  final double hourlyCostUsd;
  final int idleShutdownMinutes;
  final int activeSessions;

  VoiceServerPhase get phase {
    if (!configured) return VoiceServerPhase.notConfigured;
    return switch (state) {
      'stopped' => VoiceServerPhase.off,
      'pending' => VoiceServerPhase.starting,
      'running' =>
        ready ? VoiceServerPhase.ready : VoiceServerPhase.loadingVoice,
      'stopping' => VoiceServerPhase.stopping,
      _ => VoiceServerPhase.unavailable,
    };
  }

  bool get isTransitioning => const {
    VoiceServerPhase.starting,
    VoiceServerPhase.loadingVoice,
    VoiceServerPhase.stopping,
  }.contains(phase);

  bool get canTurnOn => phase == VoiceServerPhase.off;

  bool get canTurnOff =>
      phase == VoiceServerPhase.ready || phase == VoiceServerPhase.loadingVoice;
}
