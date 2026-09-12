import 'dart:async';

import 'package:dio/dio.dart';
import 'package:emam_admin_web_app/core/network/dio_client.dart';
import 'package:emam_admin_web_app/core/storage/token_storage.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this._tokenStorage,
    required this._refresher,
    required this._dio,
    this._onSessionExpired,
  });

  final TokenStorage _tokenStorage;
  final TokenRefresher _refresher;
  final Dio _dio;
  final void Function()? _onSessionExpired;
  Completer<bool>? _refreshCompleter;

  static const _retriedKey = 'authRetried';

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
    final options = err.requestOptions;
    final skipAuth = options.extra['skipAuth'] == true;
    if (skipAuth ||
        options.extra[_retriedKey] == true ||
        err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    if (!await _refreshOnce()) {
      handler.next(err);
      return;
    }

    options.extra[_retriedKey] = true;
    options.headers['Authorization'] = 'Bearer ${_tokenStorage.accessToken}';
    try {
      final response = await _dio.fetch<dynamic>(options);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  Future<bool> _refreshOnce() async {
    final pending = _refreshCompleter;
    if (pending != null) return pending.future;

    final completer = Completer<bool>();
    _refreshCompleter = completer;
    var refreshed = false;
    try {
      await _refresher.refreshAccessToken();
      refreshed = true;
    } catch (_) {
      await _tokenStorage.clear();
      _onSessionExpired?.call();
    } finally {
      _refreshCompleter = null;
      completer.complete(refreshed);
    }
    return refreshed;
  }
}
