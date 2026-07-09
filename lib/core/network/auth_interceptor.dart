import 'package:dio/dio.dart';
import 'package:emam_admin_web_app/core/network/dio_client.dart';
import 'package:emam_admin_web_app/core/storage/token_storage.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this._tokenStorage,
    required this._refresher,
  });

  final TokenStorage _tokenStorage;
  final TokenRefresher _refresher;
  bool _isRefreshing = false;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final skipAuth = options.extra['skipAuth'] == true;
    if (!skipAuth) {
      final token = _tokenStorage.accessToken;
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final skipAuth = err.requestOptions.extra['skipAuth'] == true;
    if (skipAuth || err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    if (_isRefreshing) {
      handler.next(err);
      return;
    }

    _isRefreshing = true;
    try {
      await _refresher.refreshAccessToken();
      final response = await Dio().fetch(err.requestOptions);
      handler.resolve(response);
    } catch (_) {
      await _tokenStorage.clear();
      handler.next(err);
    } finally {
      _isRefreshing = false;
    }
  }
}
