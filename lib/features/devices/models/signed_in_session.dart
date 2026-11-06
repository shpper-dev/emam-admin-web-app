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

  factory SignedInSession.fromJson(
    Map<dynamic, dynamic> json, {
    String? currentSessionId,
  }) {
    final device = json['device_name'];
    final id =
        _str(json['id']) ??
        _str(json['session_id']) ??
        _str(json['portal_session_id']) ??
        '';
    return SignedInSession(
      id: id,
      adminUserId:
          _str(json['admin_user_id']) ??
          _str(json['user_id']) ??
          _str(json['uid']),
      adminEmail: _str(json['admin_email']) ?? _str(json['email']),
      deviceName: device is String && device.isNotEmpty
          ? device
          : 'Unknown device',
      ipAddress: _str(json['ip_address']) ?? _str(json['ip']),
      startedAt: _date(json['started_at']),
      lastAccessedAt: _date(json['last_accessed_at']),
      expiresAt: _date(json['expires_at']),
      isCurrent:
          json['is_current'] == true ||
          json['is_current'] == 'true' ||
          (currentSessionId != null &&
              currentSessionId.isNotEmpty &&
              id == currentSessionId),
    );
  }

  SignedInSession copyWith({bool? isCurrent}) => SignedInSession(
    id: id,
    adminUserId: adminUserId,
    adminEmail: adminEmail,
    deviceName: deviceName,
    ipAddress: ipAddress,
    startedAt: startedAt,
    lastAccessedAt: lastAccessedAt,
    expiresAt: expiresAt,
    isCurrent: isCurrent ?? this.isCurrent,
  );
}

class SignedInSessions {
  const SignedInSessions({required this.sessions});

  final List<SignedInSession> sessions;

  factory SignedInSessions.fromJson(Map<dynamic, dynamic> json) {
    final currentId =
        _str(json['current_session_id']) ??
        _str(_asMap(json['data'])['current_session_id']);
    return SignedInSessions(
      sessions: [
        for (final item in _sessionList(json))
          SignedInSession.fromJson(item, currentSessionId: currentId),
      ],
    );
  }

  /// Flags the row whose id is this browser's `portal_session_id`.
  /// The list endpoint only sets `is_current` when `X-Emam-Auth-Session`
  /// was sent; matching locally covers a response that omitted the flag.
  SignedInSessions withCurrent(String? sessionId) {
    if (sessionId == null || sessionId.isEmpty) return this;
    return SignedInSessions(
      sessions: [
        for (final session in sessions)
          session.id == sessionId ? session.copyWith(isCurrent: true) : session,
      ],
    );
  }

  SignedInSessions without(String id) =>
      SignedInSessions(sessions: sessions.where((s) => s.id != id).toList());
}

List<Map<String, dynamic>> _sessionList(Map<dynamic, dynamic> json) {
  final top = json['sessions'];
  if (top is List) return _maps(top);
  final data = json['data'];
  if (data is List) return _maps(data);
  final nested = _asMap(data)['sessions'];
  if (nested is List) return _maps(nested);
  return const [];
}

List<Map<String, dynamic>> _maps(List<dynamic> list) => [
  for (final item in list)
    if (item is Map) Map<String, dynamic>.from(item),
];

Map<String, dynamic> _asMap(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : const {};

String? _str(Object? value) {
  if (value is String && value.isNotEmpty) return value;
  return null;
}

DateTime? _date(Object? value) {
  if (value is String) return DateTime.tryParse(value);
  if (value is int) {
    final millis = value > 100000000000 ? value : value * 1000;
    return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
  }
  return null;
}
