import 'package:dio/dio.dart';
import 'package:emam_admin_web_app/core/constants/api_constants.dart';
import 'package:emam_admin_web_app/core/network/auth_interceptor.dart';
import 'package:emam_admin_web_app/core/storage/token_storage.dart';

class DioClient {
  DioClient({required TokenStorage tokenStorage, required TokenRefresher refresher})
      : _dio = Dio(
          BaseOptions(
            baseUrl: ApiConstants.apiBaseUrl,
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 30),
            headers: {'Content-Type': 'application/json'},
          ),
        ) {
    _dio.interceptors.add(
      AuthInterceptor(tokenStorage: tokenStorage, refresher: refresher),
    );
  }

  final Dio _dio;

  Dio get dio => _dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.get<T>(path, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
}

/// Implemented by [AuthRepository] to avoid circular imports.
abstract class TokenRefresher {
  Future<void> refreshAccessToken();
}
