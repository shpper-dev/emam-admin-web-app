import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:emam_admin_web_app/core/constants/api_constants.dart';
import 'package:emam_admin_web_app/core/network/dio_client.dart';
import 'package:emam_admin_web_app/core/storage/token_storage.dart';
import 'package:emam_admin_web_app/features/units/repository/units_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Request {
  _Request(this.method, this.uri, this.contentType, this.body);

  final String method;
  final Uri uri;
  final String? contentType;
  final List<int> body;

  Object? get json => jsonDecode(utf8.decode(body));
}

class _Adapter implements HttpClientAdapter {
  final requests = <_Request>[];
  Object? reply = const <String, Object?>{};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final body = <int>[];
    if (requestStream != null) {
      await for (final chunk in requestStream) {
        body.addAll(chunk);
      }
    }
    requests.add(
      _Request(
        options.method,
        options.uri,
        options.headers[Headers.contentTypeHeader]?.toString(),
        body,
      ),
    );
    return ResponseBody.fromString(
      jsonEncode(reply),
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

Future<(UnitsRepository, _Adapter)> _repository() async {
  SharedPreferences.setMockInitialValues({});
  final client = DioClient(
    tokenStorage: TokenStorage(await SharedPreferences.getInstance()),
    refresher: _NoRefresh(),
  );
  final adapter = _Adapter();
  client.dio.httpClientAdapter = adapter;
  return (UnitsRepository(client), adapter);
}

void main() {
  test('the unit list is read from "devices"', () async {
    final (repo, adapter) = await _repository();
    adapter.reply = {
      'devices': [
        {'install_id': 'unit-a', 'name': 'A'},
        {'install_id': 'unit-b', 'name': ''},
      ],
    };

    final units = await repo.fetchUnits();

    expect(units.map((u) => u.installId), ['unit-a', 'unit-b']);
    expect(adapter.requests.single.method, 'GET');
    expect(adapter.requests.single.uri.path, '/api/admin/devices');
  });

  test('settings are patched with null for "use fleet setting"', () async {
    final (repo, adapter) = await _repository();

    await repo.updateUnit(
      'unit-a',
      settings: {'mic_mode': null, 'checkin_minutes': 2},
    );
    await repo.updateUnit('unit-a', name: 'Muscat 1');

    expect(adapter.requests[0].method, 'PATCH');
    expect(adapter.requests[0].uri.path, '/api/admin/devices/unit-a');
    expect(adapter.requests[0].json, {
      'settings': {'mic_mode': null, 'checkin_minutes': 2},
    });
    expect(adapter.requests[1].json, {'name': 'Muscat 1'});
  });

  test('commands are queued and cancelled on the unit', () async {
    final (repo, adapter) = await _repository();
    adapter.reply = {'id': 'cmd-1'};

    final id = await repo.queueCommand('unit-a', 'add_wifi', {
      'ssid': 'MosqueNet',
      'security': 'wpa2',
      'password': 'secret123',
    });
    await repo.cancelCommand('unit-a', 'cmd-1');

    expect(id, 'cmd-1');
    expect(adapter.requests[0].method, 'POST');
    expect(adapter.requests[0].uri.path, '/api/admin/devices/unit-a/commands');
    expect(adapter.requests[0].json, {
      'type': 'add_wifi',
      'args': {
        'ssid': 'MosqueNet',
        'security': 'wpa2',
        'password': 'secret123',
      },
    });
    expect(adapter.requests[1].method, 'DELETE');
    expect(
      adapter.requests[1].uri.path,
      '/api/admin/devices/unit-a/commands/cmd-1',
    );
  });

  test('fleet settings are saved with PUT', () async {
    final (repo, adapter) = await _repository();
    adapter.reply = {
      'values': {'auto_update': false},
    };

    final values = await repo.saveFleetSettings({'auto_update': false});

    expect(values, {'auto_update': false});
    expect(adapter.requests.single.method, 'PUT');
    expect(adapter.requests.single.uri.path, '/api/admin/device-settings');
    expect(adapter.requests.single.json, {
      'values': {'auto_update': false},
    });
  });

  test('an APK is uploaded as the raw body with its notes', () async {
    final (repo, adapter) = await _repository();
    adapter.reply = {'version_code': 6, 'version_name': '0.1.5'};
    final apk = Uint8List.fromList(List.generate(5000, (i) => i % 256));

    final release = await repo.uploadRelease(apk, notes: ' Mic fix ');

    final request = adapter.requests.single;
    expect(release.versionCode, 6);
    expect(request.method, 'POST');
    expect(request.uri.path, '/api/admin/device-releases');
    expect(request.uri.queryParameters, {'notes': 'Mic fix'});
    expect(request.contentType, 'application/vnd.android.package-archive');
    expect(request.body, apk);
  });

  test('an upload without notes sends no notes parameter', () async {
    final (repo, adapter) = await _repository();
    adapter.reply = {'version_code': 6};

    await repo.uploadRelease(Uint8List(4));

    expect(adapter.requests.single.uri.queryParameters, isEmpty);
  });

  test('a release is published to all units or to a list', () async {
    final (repo, adapter) = await _repository();

    await repo.publishRelease(6);
    await repo.publishRelease(6, unitIds: ['unit-a', 'unit-b']);
    await repo.unpublishRelease(6);
    await repo.deleteRelease(6);

    expect(
      adapter.requests[0].uri.path,
      '/api/admin/device-releases/6/publish',
    );
    expect(adapter.requests[0].json, {'target': 'all'});
    expect(adapter.requests[1].json, {
      'target': ['unit-a', 'unit-b'],
    });
    expect(
      adapter.requests[2].uri.path,
      '/api/admin/device-releases/6/unpublish',
    );
    expect(adapter.requests[3].method, 'DELETE');
    expect(adapter.requests[3].uri.path, '/api/admin/device-releases/6');
  });

  test('activation codes are requested with a count and label', () async {
    final (repo, adapter) = await _repository();
    adapter.reply = {
      'codes': ['EMAM-ABCD-EFGH-JKLM', 'EMAM-NPQR-STUV-WXYZ'],
    };

    final codes = await repo.createActivationCodes(
      count: 2,
      label: ' Batch 2 ',
    );

    expect(codes, ['EMAM-ABCD-EFGH-JKLM', 'EMAM-NPQR-STUV-WXYZ']);
    expect(adapter.requests.single.uri.path, '/api/admin/device-codes');
    expect(adapter.requests.single.json, {'count': 2, 'label': 'Batch 2'});
  });

  test('IDs and file names are percent-encoded into unit paths', () {
    expect(
      ApiConstants.unitRecording('unit/../x', 'a b?.wav'),
      '/api/admin/device-recordings/unit%2F..%2Fx/a%20b%3F.wav',
    );
    expect(
      ApiConstants.unitCommand('unit-a', 'c/1'),
      '/api/admin/devices/unit-a/commands/c%2F1',
    );
    expect(
      ApiConstants.unitRevoke('unit-a'),
      '/api/admin/devices/unit-a/revoke',
    );
  });
}
