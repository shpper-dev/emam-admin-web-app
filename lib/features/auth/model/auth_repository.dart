import 'package:dio/dio.dart';
import 'package:emam_admin_web_app/core/constants/api_constants.dart';
import 'package:emam_admin_web_app/core/network/dio_client.dart';
import 'package:emam_admin_web_app/core/storage/token_storage.dart';
import 'package:emam_admin_web_app/features/auth/model/auth_session.dart';

class AuthRepository implements TokenRefresher {
  AuthRepository({required this._tokenStorage});

  final TokenStorage _tokenStorage;
  final Dio _authDio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _authDio.post<Map<String, dynamic>>(
      ApiConstants.signInUrl,
      data: {
        'email': email,
        'password': password,
        'returnSecureToken': true,
      },
    );

    final data = response.data!;
    final session = AuthSession.fromSignInResponse(email: email, json: data);

    await _tokenStorage.saveTokens(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      expiresInSeconds: session.expiresInSeconds,
    );

    return session;
  }

  @override
  Future<void> refreshAccessToken() async {
    final refreshToken = _tokenStorage.refreshToken;
    if (refreshToken == null) {
      throw Exception('No refresh token available');
    }

    final response = await _authDio.post<Map<String, dynamic>>(
      ApiConstants.refreshTokenUrl,
      data: {
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
      },
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

    final email = _tokenStorage.savedEmail ?? '';
    return AuthSession(
      email: email,
      localId: '',
      accessToken: _tokenStorage.accessToken!,
      refreshToken: _tokenStorage.refreshToken!,
      expiresInSeconds: 0,
    );
  }

  Future<void> signOut() => _tokenStorage.clear();
}
