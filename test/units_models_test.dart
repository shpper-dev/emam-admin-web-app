import 'package:emam_admin_web_app/features/units/models/device_unit.dart';
import 'package:emam_admin_web_app/features/units/models/unit_command.dart';
import 'package:emam_admin_web_app/features/units/models/unit_crash_report.dart';
import 'package:emam_admin_web_app/features/units/models/unit_recording.dart';
import 'package:emam_admin_web_app/features/units/models/unit_release.dart';
import 'package:emam_admin_web_app/features/units/models/unit_settings.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime.utc(2026, 11, 12, 10, 0);

Map<String, Object?> _unitJson({
  String? statusAt = '2026-11-12T09:55:00.123456+00:00',
  bool online = true,
  Map<String, Object?> status = const {},
}) => {
  'install_id': 'a1b2c3d4e5f60718293a4b5c',
  'name': ' Muscat 1 ',
  'label': 'JWD batch 1',
  'device': {
    'manufacturer': 'JWD',
    'model': 'JWD-X1',
    'android': '8.1.0',
    'sdk': 27,
    'app_version': '0.1.3',
  },
  'revoked': false,
  'attestation': {'ok': true},
  'last_ip': '203.0.113.7',
  'activated_at': '2026-11-01T08:00:00+00:00',
  'last_seen_at': '2026-11-12T09:50:00+00:00',
  'status': {
    'battery': 76,
    'charging': true,
    'online': online,
    'wifi_on': true,
    'wifi_ssid': 'MosqueNet',
    'wifi_bars': 3,
    'language': 'bn',
    'serial': 'SN123',
    'model': 'X1 Pro',
    'locked': false,
    'crashes': 2,
    'update': null,
    'back_is_speech': true,
    ...status,
  },
  'status_at': statusAt,
  'version_code': 5,
  'version_name': '0.1.4',
  'settings': {'mic_mode': 'recognition'},
  'open_commands': 1,
};

void main() {
  group('DeviceUnit', () {
    test('reads a unit as the admin list returns it', () {
      final unit = DeviceUnit.fromJson(_unitJson());

      expect(unit.installId, 'a1b2c3d4e5f60718293a4b5c');
      expect(unit.name, 'Muscat 1');
      expect(unit.displayName, 'Muscat 1');
      expect(unit.label, 'JWD batch 1');
      expect(unit.serial, 'SN123');
      expect(unit.model, 'X1 Pro');
      expect(unit.manufacturer, 'JWD');
      expect(unit.appVersion, '0.1.4 (5)');
      expect(unit.battery, 76);
      expect(unit.charging, isTrue);
      expect(unit.wifiSsid, 'MosqueNet');
      expect(unit.wifiBars, 3);
      expect(unit.language, 'bn');
      expect(unit.crashes, 2);
      expect(unit.updateState, isNull);
      expect(unit.backIsSpeech, isTrue);
      expect(unit.settings, {'mic_mode': 'recognition'});
      expect(unit.openCommands, 1);
      expect(unit.lastIp, '203.0.113.7');
      expect(unit.statusAt, DateTime.utc(2026, 11, 12, 9, 55, 0, 123, 456));
    });

    test('a unit that never checked in falls back to its activation data', () {
      final unit = DeviceUnit.fromJson({
        'install_id': 'ffeeddccbbaa99887766',
        'device': {'model': 'JWD-X1', 'app_version': '0.1.3'},
        'status': {},
        'status_at': null,
        'version_code': null,
        'version_name': null,
        'settings': {},
      });

      expect(unit.displayName, 'ffeeddcc…');
      expect(unit.model, 'JWD-X1');
      expect(unit.appVersion, '0.1.3');
      expect(unit.battery, isNull);
      expect(unit.crashes, 0);
      expect(unit.revoked, isFalse);
      expect(unit.isOnline(_now), isFalse);
      expect(unit.lastContactAt, isNull);
    });

    test('online needs a check-in under 15 minutes old and a connection', () {
      expect(DeviceUnit.fromJson(_unitJson()).isOnline(_now), isTrue);
      expect(
        DeviceUnit.fromJson(
          _unitJson(statusAt: '2026-11-12T09:45:01+00:00'),
        ).isOnline(_now),
        isTrue,
      );
      expect(
        DeviceUnit.fromJson(
          _unitJson(statusAt: '2026-11-12T09:44:59+00:00'),
        ).isOnline(_now),
        isFalse,
      );
      expect(
        DeviceUnit.fromJson(_unitJson(online: false)).isOnline(_now),
        isFalse,
      );
      expect(
        DeviceUnit.fromJson(_unitJson(statusAt: null)).isOnline(_now),
        isFalse,
      );
    });

    test('last contact is the later of check-in and last request', () {
      final unit = DeviceUnit.fromJson(_unitJson());
      expect(unit.lastContactAt, unit.statusAt);

      final seenLater = DeviceUnit.fromJson({
        ..._unitJson(statusAt: '2026-11-10T08:00:00+00:00'),
        'last_seen_at': '2026-11-11T08:00:00+00:00',
      });
      expect(seenLater.lastContactAt, DateTime.utc(2026, 11, 11, 8));
    });

    test('a failed update is recognised from the unit\'s own wording', () {
      final unit = DeviceUnit.fromJson(
        _unitJson(status: {'update': 'Update failed 0.1.5: download damaged'}),
      );
      expect(unit.updateState, 'Update failed 0.1.5: download damaged');
      expect(unit.updateFailed, isTrue);
      expect(
        DeviceUnit.fromJson(
          _unitJson(status: {'update': 'Downloading 0.1.5'}),
        ).updateFailed,
        isFalse,
      );
    });
  });

  test('commands are read newest first with their states', () {
    final commands = UnitCommand.listFromJson({
      'commands': [
        {
          'id': 'c2',
          'type': 'add_wifi',
          'args': {'ssid': 'MosqueNet', 'password': '•••', 'security': 'wpa2'},
          'state': 'pending',
          'result': null,
          'created_by': 'admin@emam.ai',
          'created_at': '2026-11-12T09:58:00+00:00',
          'sent_at': null,
          'done_at': null,
        },
        {
          'id': 'c1',
          'type': 'reboot',
          'args': {},
          'state': 'done',
          'result': 'Restarting',
          'created_at': '2026-11-12T09:00:00+00:00',
          'sent_at': '2026-11-12T09:05:00+00:00',
          'done_at': '2026-11-12T09:10:00+00:00',
        },
        {'id': 'c0', 'type': 'ping', 'state': 'archived'},
      ],
    });

    expect(commands.map((c) => c.id), ['c2', 'c1', 'c0']);
    expect(commands[0].state, UnitCommandState.pending);
    expect(commands[0].canCancel, isTrue);
    expect(commands[0].args['password'], '•••');
    expect(commands[0].createdBy, 'admin@emam.ai');
    expect(commands[1].state, UnitCommandState.done);
    expect(commands[1].canCancel, isFalse);
    expect(commands[1].result, 'Restarting');
    expect(commands[1].doneAt, DateTime.utc(2026, 11, 12, 9, 10));
    expect(commands[2].state, UnitCommandState.unknown);
  });

  test('crash reports keep their text', () {
    final reports = UnitCrashReport.listFromJson({
      'crashes': [
        {
          'name': 'crash-2026-11-12.txt',
          'text': 'java.lang.IllegalStateException\n  at ai.emam.device',
          'received_at': '2026-11-12T09:00:00+00:00',
        },
        {'name': 'empty.txt', 'text': null, 'received_at': null},
      ],
    });

    expect(reports, hasLength(2));
    expect(reports.first.text, contains('IllegalStateException'));
    expect(reports.first.receivedAt, DateTime.utc(2026, 11, 12, 9));
    expect(reports.last.text, isEmpty);
    expect(reports.last.receivedAt, isNull);
  });

  group('FleetSettings', () {
    final fleet = FleetSettings.fromJson({
      'values': {'checkin_minutes': 10},
      'schema': {
        'mic_mode': {
          'label': 'Khutbah microphone',
          'type': 'choice',
          'choices': ['call', 'recognition', 'unprocessed'],
          'default': 'call',
          'help': 'Call cancels echo.',
        },
        'confidence_gate': {
          'label': 'Hold back translations of unclear speech',
          'type': 'bool',
          'default': true,
          'help': 'The unit asks the listener to move closer.',
        },
        'checkin_minutes': {
          'label': 'Check in every (minutes)',
          'type': 'int',
          'min': 1,
          'max': 60,
          'default': 5,
          'help': 'How soon a unit sees commands and settings.',
        },
        'colour': {'label': 'Colour', 'type': 'rgb', 'default': '#fff'},
      },
      'commands': ['ping', 'reboot'],
    });

    test('keeps the schema in the server\'s order', () {
      expect(fleet.schema.map((s) => s.key), [
        'mic_mode',
        'confidence_gate',
        'checkin_minutes',
        'colour',
      ]);
      expect(fleet.editable.map((s) => s.key), [
        'mic_mode',
        'confidence_gate',
        'checkin_minutes',
      ]);
      expect(fleet.commands, ['ping', 'reboot']);
      final mic = fleet.spec('mic_mode')!;
      expect(mic.type, UnitSettingType.choice);
      expect(mic.choices, ['call', 'recognition', 'unprocessed']);
      expect(mic.help, 'Call cancels echo.');
      expect(fleet.spec('checkin_minutes')!.min, 1);
      expect(fleet.spec('checkin_minutes')!.max, 60);
    });

    test('fleet values fall back to the built-in defaults', () {
      expect(fleet.fleetValue('checkin_minutes'), 10);
      expect(fleet.fleetValue('mic_mode'), 'call');
      expect(fleet.fleetValue('confidence_gate'), true);
      expect(
        fleet.effectiveValue('mic_mode', {'mic_mode': 'unprocessed'}),
        'unprocessed',
      );
      expect(fleet.effectiveValue('mic_mode', const {}), 'call');
    });

    test('values are checked the way the server checks them', () {
      final mic = fleet.spec('mic_mode')!;
      final gate = fleet.spec('confidence_gate')!;
      final minutes = fleet.spec('checkin_minutes')!;
      expect(mic.accepts('recognition'), isTrue);
      expect(mic.accepts('loud'), isFalse);
      expect(gate.accepts(false), isTrue);
      expect(gate.accepts('false'), isFalse);
      expect(minutes.accepts(1), isTrue);
      expect(minutes.accepts(60), isTrue);
      expect(minutes.accepts(0), isFalse);
      expect(minutes.accepts(61), isFalse);
      expect(minutes.accepts(null), isFalse);
      expect(fleet.spec('colour')!.accepts('#000'), isFalse);
    });
  });

  test('releases read their publish target', () {
    final releases = UnitRelease.listFromJson({
      'releases': [
        {
          'version_code': 6,
          'version_name': '0.1.5',
          'size': 12345678,
          'sha256': 'ab' * 32,
          'notes': ' Fixes the mic on Android 8.1 ',
          'uploaded_by': 'admin@emam.ai',
          'uploaded_at': '2026-11-12T08:00:00+00:00',
          'published': true,
          'target': 'all',
          'published_at': '2026-11-12T09:00:00+00:00',
          'file_present': true,
        },
        {
          'version_code': 5,
          'version_name': '0.1.4',
          'published': true,
          'target': ['unit-a', 'unit-b'],
          'file_present': false,
        },
        {'version_code': 4, 'published': false, 'target': null},
      ],
    });

    expect(releases[0].targetsAll, isTrue);
    expect(releases[0].notes, 'Fixes the mic on Android 8.1');
    expect(releases[0].size, 12345678);
    expect(releases[0].canDelete, isFalse);
    expect(releases[1].targetsAll, isFalse);
    expect(releases[1].targetUnits, ['unit-a', 'unit-b']);
    expect(releases[1].filePresent, isFalse);
    expect(releases[2].versionName, '4');
    expect(releases[2].targetUnits, isEmpty);
    expect(releases[2].canDelete, isTrue);
    // The upload reply has no file_present; the file was just saved.
    expect(UnitRelease.fromJson({'version_code': 7}).filePresent, isTrue);
  });

  test('recordings read unix times and the free disk space', () {
    final data = UnitRecordings.fromJson({
      'recordings': [
        {
          'install_id': 'unit-a',
          'name': 'khutbah-1.wav',
          'size': 45200000,
          'modified': 1762941600.5,
          'complete': true,
        },
        {
          'install_id': 'unit-b',
          'name': 'khutbah-2.wav',
          'size': 1000,
          'modified': 1762941000,
          'complete': false,
        },
      ],
      'disk_free_gb': 41.7,
    });

    expect(data.diskFreeGb, 41.7);
    expect(data.recordings.first.complete, isTrue);
    expect(
      data.recordings.first.modified,
      DateTime.fromMillisecondsSinceEpoch(1762941600500, isUtc: true),
    );
    expect(data.recordings.last.complete, isFalse);
    final rest = data.without(data.recordings.first);
    expect(rest.recordings.single.name, 'khutbah-2.wav');
    expect(rest.diskFreeGb, 41.7);
  });
}
