import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:emam_admin_web_app/core/constants/api_constants.dart';
import 'package:emam_admin_web_app/core/network/auth_interceptor.dart';
import 'package:emam_admin_web_app/core/network/dio_client.dart';
import 'package:emam_admin_web_app/core/storage/token_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Adapter implements HttpClientAdapter {
  final headers = <String, Object?>{};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    headers[options.uri.toString()] = options.headers['Authorization'];
    return ResponseBody.fromString(
      jsonEncode({}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _NoRefresh implements TokenRefresher {
  @override
  Future<void> refreshAccessToken() async {}
}

void main() {
  test('bearer token is sent only to the admin API host', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = TokenStorage(await SharedPreferences.getInstance());
    await storage.saveTokens(
      accessToken: 'secret',
      refreshToken: 'r',
      expiresInSeconds: 3600,
    );
    final adapter = _Adapter();
    final dio = Dio()..httpClientAdapter = adapter;
    dio.interceptors.add(
      AuthInterceptor(tokenStorage: storage, refresher: _NoRefresh(), dio: dio),
    );

    await dio.get<dynamic>('${ApiConstants.apiBaseUrl}/admin/users');
    await dio.get<dynamic>('https://other.example/collect');

    expect(
      adapter.headers['${ApiConstants.apiBaseUrl}/admin/users'],
      'Bearer secret',
    );
    expect(adapter.headers['https://other.example/collect'], isNull);
  });

  test('IDs are percent-encoded into admin request paths', () {
    expect(
      ApiConstants.userDetail('a/../b?x=1#y'),
      '/admin/users/a%2F..%2Fb%3Fx%3D1%23y/detail',
    );
    expect(
      ApiConstants.hideDuaPost('p/1'),
      '/admin/moderation/posts/p%2F1/hide',
    );
    expect(ApiConstants.userDetail('uid123'), '/admin/users/uid123/detail');
  });
}
