import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  TokenStorage(this._prefs);

  final SharedPreferences _prefs;

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _expiresAtKey = 'expires_at';
  static const _emailKey = 'saved_email';
  static const _rememberMeKey = 'remember_me';

  String? get accessToken => _prefs.getString(_accessTokenKey);
  String? get refreshToken => _prefs.getString(_refreshTokenKey);
  int? get expiresAt => _prefs.getInt(_expiresAtKey);
  String? get savedEmail => _prefs.getString(_emailKey);
  bool get rememberMe => _prefs.getBool(_rememberMeKey) ?? false;

  bool get hasTokens =>
      accessToken != null &&
      refreshToken != null &&
      expiresAt != null;

  bool get isAccessTokenExpired {
    final expiresAt = this.expiresAt;
    if (expiresAt == null) return true;
    return DateTime.now().millisecondsSinceEpoch >= expiresAt;
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required int expiresInSeconds,
  }) async {
    final expiresAt = DateTime.now()
        .add(Duration(seconds: expiresInSeconds))
        .millisecondsSinceEpoch;

    await _prefs.setString(_accessTokenKey, accessToken);
    await _prefs.setString(_refreshTokenKey, refreshToken);
    await _prefs.setInt(_expiresAtKey, expiresAt);
  }

  Future<void> saveRememberMe({required bool rememberMe, String? email}) async {
    await _prefs.setBool(_rememberMeKey, rememberMe);
    if (rememberMe && email != null) {
      await _prefs.setString(_emailKey, email);
    } else {
      await _prefs.remove(_emailKey);
    }
  }

  Future<void> clear() async {
    await _prefs.remove(_accessTokenKey);
    await _prefs.remove(_refreshTokenKey);
    await _prefs.remove(_expiresAtKey);
  }
}
