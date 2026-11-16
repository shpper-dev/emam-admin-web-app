import 'package:emam_admin_web_app/features/cms/models/staff_session.dart';

int _parseExpiresIn(Object? value) {
  if (value is int) return value;
  if (value is String) return int.parse(value);
  throw const FormatException('Invalid expires_in value');
}

class AuthSession {
  const AuthSession({
    required this.email,
    required this.localId,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresInSeconds,
    this.staff,
  });

  final String email;
  final String localId;
  final String accessToken;
  final String refreshToken;
  final int expiresInSeconds;

  /// CMS staff roles from `GET /admin/me`; null if that call failed.
  final StaffSession? staff;

  AuthSession copyWith({String? email, String? localId, StaffSession? staff}) =>
      AuthSession(
        email: email ?? this.email,
        localId: localId ?? this.localId,
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiresInSeconds: expiresInSeconds,
        staff: staff ?? this.staff,
      );

  factory AuthSession.fromSignInResponse({
    required String email,
    required Map<String, dynamic> json,
  }) {
    return AuthSession(
      email: email,
      localId: json['localId'] as String,
      accessToken: json['idToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresInSeconds: _parseExpiresIn(json['expiresIn']),
    );
  }

  factory AuthSession.fromRefreshResponse({
    required String email,
    required String localId,
    required Map<String, dynamic> json,
  }) {
    return AuthSession(
      email: email,
      localId: localId,
      accessToken: json['id_token'] as String,
      refreshToken: json['refresh_token'] as String,
      expiresInSeconds: _parseExpiresIn(json['expires_in']),
    );
  }
}
