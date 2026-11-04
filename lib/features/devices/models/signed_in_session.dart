/// One server-side refresh-token session from `GET /api/auth/sessions`.
class SignedInSession {
  const SignedInSession({
    required this.id,
    required this.deviceName,
    required this.ipAddress,
    required this.startedAt,
    required this.lastAccessedAt,
    required this.expiresAt,
    required this.isCurrent,
  });

  final String id;
  final String deviceName;
  final String? ipAddress;
  final DateTime? startedAt;
  final DateTime? lastAccessedAt;
  final DateTime? expiresAt;
  final bool isCurrent;

  factory SignedInSession.fromJson(Map<String, dynamic> json) {
    final device = json['device_name'];
    return SignedInSession(
      id: json['id'] as String,
      deviceName: device is String && device.isNotEmpty
          ? device
          : 'Unknown device',
      ipAddress: json['ip_address'] as String?,
      startedAt: _date(json['started_at']),
      lastAccessedAt: _date(json['last_accessed_at']),
      expiresAt: _date(json['expires_at']),
      isCurrent: json['is_current'] == true,
    );
  }
}

class SignedInSessions {
  const SignedInSessions({required this.sessions});

  final List<SignedInSession> sessions;

  List<SignedInSession> get others =>
      sessions.where((s) => !s.isCurrent).toList();

  factory SignedInSessions.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final list = data is Map ? data['sessions'] : null;
    return SignedInSessions(
      sessions: [
        if (list is List)
          for (final item in list)
            if (item is Map<String, dynamic>) SignedInSession.fromJson(item),
      ],
    );
  }

  SignedInSessions without(String id) =>
      SignedInSessions(sessions: sessions.where((s) => s.id != id).toList());
}

DateTime? _date(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;
