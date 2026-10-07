import 'package:dio/dio.dart';
import 'package:emam_admin_web_app/core/constants/api_constants.dart';
import 'package:emam_admin_web_app/core/network/dio_client.dart';
import 'package:emam_admin_web_app/core/storage/token_storage.dart';
import 'package:emam_admin_web_app/features/auth/models/auth_session.dart';

/// Thrown when the signed-in Firebase user is not an admin.
class NotAdminException implements Exception {
  const NotAdminException();

  static const message = 'This account does not have admin access.';
}

class AuthRepository implements TokenRefresher {
  AuthRepository({required this._tokenStorage, Dio? dio})
    : _authDio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 30),
              headers: {'Content-Type': 'application/json'},
            ),
          );

  final TokenStorage _tokenStorage;
  final Dio _authDio;

  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _authDio.post<Map<String, dynamic>>(
      ApiConstants.signInUrl,
      data: {'email': email, 'password': password, 'returnSecureToken': true},
    );

    final data = response.data!;
    var session = AuthSession.fromSignInResponse(email: email, json: data);

    final admin = await _fetchAdmin(session.accessToken);
    if (admin == null) throw const NotAdminException();
    session = session.copyWith(
      email: admin.email.isEmpty ? email : admin.email,
      localId: admin.id.isEmpty ? null : admin.id,
    );

    await _tokenStorage.saveTokens(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      expiresInSeconds: session.expiresInSeconds,
    );
    await _tokenStorage.markSignedInNow();

    return session;
  }

  /// Calls `/admin/auth/me`. Returns the admin's email and uid (empty if the
  /// body has none), or null when the backend says the user is not an admin (`admin` is not
  /// true, or 403; also 401 unless [throwOnUnauthorized] is set).
  Future<({String email, String id})?> _fetchAdmin(
    String accessToken, {
    bool throwOnUnauthorized = false,
  }) async {
    try {
      final response = await _authDio.get<Map<String, dynamic>>(
        '${ApiConstants.apiBaseUrl}${ApiConstants.authMe}',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
      final data = response.data;
      if (data?['admin'] != true) return null;
      return (
        email: (data?['email'] as String?) ?? '',
        id: (data?['id'] as String?) ?? '',
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 403) return null;
      if (status == 401 && !throwOnUnauthorized) return null;
      rethrow;
    }
  }

  @override
  Future<void> refreshAccessToken() async {
    final refreshToken = _tokenStorage.refreshToken;
    if (refreshToken == null) {
      throw Exception('No refresh token available');
    }

    final response = await _authDio.post<Map<String, dynamic>>(
      ApiConstants.refreshTokenUrl,
      data: {'grant_type': 'refresh_token', 'refresh_token': refreshToken},
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
        extra: const {'skipAuth': true},
      ),
    );

    final data = response.data!;
    await _tokenStorage.saveTokens(
      accessToken: data['id_token'] as String,
      refreshToken: data['refresh_token'] as String,
      expiresInSeconds: _parseExpiresIn(data['expires_in']),
    );
  }

  int _parseExpiresIn(Object? value) {
    if (value is int) return value;
    if (value is String) return int.parse(value);
    throw const FormatException('Invalid expires_in value');
  }

  Future<AuthSession?> restoreSession() async {
    if (!_tokenStorage.hasTokens) return null;

    if (_tokenStorage.isAccessTokenExpired) {
      try {
        await refreshAccessToken();
      } catch (_) {
        await _tokenStorage.clear();
        return null;
      }
    }

    ({String email, String id})? admin;
    try {
      admin = await _fetchAdmin(
        _tokenStorage.accessToken!,
        throwOnUnauthorized: true,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode != 401) {
        // Backend unreachable: fall back to the login screen, keep tokens.
        return null;
      }
      // Token rejected: refresh once and retry before giving up.
      try {
        await refreshAccessToken();
        admin = await _fetchAdmin(_tokenStorage.accessToken!);
      } catch (_) {
        await _tokenStorage.clear();
        return null;
      }
    }
    if (admin == null) {
      await _tokenStorage.clear();
      return null;
    }

    return AuthSession(
      email: admin.email.isEmpty
          ? (_tokenStorage.savedEmail ?? '')
          : admin.email,
      localId: admin.id,
      accessToken: _tokenStorage.accessToken!,
      refreshToken: _tokenStorage.refreshToken!,
      expiresInSeconds: 0,
    );
  }

  Future<void> signOut() => _tokenStorage.clear();
}
