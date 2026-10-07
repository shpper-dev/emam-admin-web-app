import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:emam_admin_web_app/core/storage/token_storage.dart';
import 'package:emam_admin_web_app/features/auth/models/auth_repository.dart';
import 'package:emam_admin_web_app/features/users/utils/admin_panel_user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);
  final ResponseBody Function(RequestOptions) handler;
  final calls = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls.add(options.uri.toString());
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(int status, Map<String, dynamic> body) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

Future<(AuthRepository, TokenStorage, _FakeAdapter)> _setup(
  ResponseBody Function(RequestOptions) handler, {
  bool expired = false,
}) async {
  SharedPreferences.setMockInitialValues({});
  final storage = TokenStorage(await SharedPreferences.getInstance());
  await storage.saveTokens(
    accessToken: 'old',
    refreshToken: 'refresh',
    expiresInSeconds: expired ? -10 : 3600,
  );
  final adapter = _FakeAdapter(handler);
  final dio = Dio()..httpClientAdapter = adapter;
  return (AuthRepository(tokenStorage: storage, dio: dio), storage, adapter);
}

void main() {
  bool isMe(RequestOptions o) => o.path.endsWith('/admin/auth/me');

  test('restore: admin session takes email from /admin/auth/me', () async {
    final (repo, _, _) = await _setup(
      (o) => _json(200, {'admin': true, 'email': 'boss@emam.ai'}),
    );
    final session = await repo.restoreSession();
    expect(session?.email, 'boss@emam.ai');
  });

  test('restore: 403 clears tokens', () async {
    final (repo, storage, _) = await _setup((o) => _json(403, {}));
    expect(await repo.restoreSession(), isNull);
    expect(storage.hasTokens, isFalse);
  });

  test('restore: 401 refreshes once then retries', () async {
    var meCalls = 0;
    final (repo, storage, _) = await _setup((o) {
      if (isMe(o)) {
        meCalls++;
        return meCalls == 1
            ? _json(401, {})
            : _json(200, {'admin': true, 'email': 'boss@emam.ai'});
      }
      return _json(200, {
        'id_token': 'new',
        'refresh_token': 'refresh2',
        'expires_in': '3600',
      });
    });
    final session = await repo.restoreSession();
    expect(session?.email, 'boss@emam.ai');
    expect(storage.accessToken, 'new');
  });

  test('restore: network/server error keeps tokens', () async {
    final (repo, storage, _) = await _setup((o) => _json(500, {}));
    expect(await repo.restoreSession(), isNull);
    expect(storage.hasTokens, isTrue);
  });

  test('sign-in: non-admin is rejected and nothing is stored', () async {
    final (repo, storage, _) = await _setup((o) {
      if (isMe(o)) return _json(403, {});
      return _json(200, {
        'idToken': 'tok',
        'refreshToken': 'r',
        'expiresIn': '3600',
        'localId': 'u',
        'email': 'user@x.com',
      });
    });
    await storage.clear();
    await expectLater(
      repo.signIn(email: 'user@x.com', password: 'pw'),
      throwsA(isA<NotAdminException>()),
    );
    expect(storage.hasTokens, isFalse);
  });

  test('admin email filtering is case-insensitive and null-safe', () {
    expect(isAdminPanelUserEmail('Boss@Emam.ai', 'boss@emam.ai'), isTrue);
    expect(isAdminPanelUserEmail('a@b.c', null), isFalse);
    expect(isAdminPanelUserEmail('a@b.c', ''), isFalse);
  });
}
