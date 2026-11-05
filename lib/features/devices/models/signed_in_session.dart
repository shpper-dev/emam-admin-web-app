/// One admin device row from `GET /admin/auth/sessions/all`.
class SignedInSession {
  const SignedInSession({
    required this.id,
    required this.adminUserId,
    required this.adminEmail,
    required this.deviceName,
    required this.ipAddress,
    required this.startedAt,
    required this.lastAccessedAt,
    required this.expiresAt,
    required this.isCurrent,
  });

  final String id;
  final String? adminUserId;
  final String? adminEmail;
  final String deviceName;
  final String? ipAddress;
  final DateTime? startedAt;
  final DateTime? lastAccessedAt;
  final DateTime? expiresAt;
  final bool isCurrent;

  factory SignedInSession.fromJson(Map<String, dynamic> json) {
    final device = json['device_name'];
    return SignedInSession(
      id: (json['id'] ?? json['session_id'] ?? '') as String,
      adminUserId: json['admin_user_id'] as String?,
      adminEmail: json['admin_email'] as String?,
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
