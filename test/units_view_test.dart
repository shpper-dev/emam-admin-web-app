import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:emam_admin_web_app/features/units/models/device_unit.dart';
import 'package:emam_admin_web_app/features/units/models/unit_command.dart';
import 'package:emam_admin_web_app/features/units/models/unit_crash_report.dart';
import 'package:emam_admin_web_app/features/units/models/unit_recording.dart';
import 'package:emam_admin_web_app/features/units/models/unit_release.dart';
import 'package:emam_admin_web_app/features/units/models/unit_settings.dart';
import 'package:emam_admin_web_app/features/units/provider/units_repository_provider.dart';
import 'package:emam_admin_web_app/features/units/repository/units_repository.dart';
import 'package:emam_admin_web_app/features/units/views/unit_detail_view.dart';
import 'package:emam_admin_web_app/features/units/views/units_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

String _ago(Duration duration) =>
    DateTime.now().toUtc().subtract(duration).toIso8601String();

DeviceUnit _onlineUnit() => DeviceUnit.fromJson({
  'install_id': 'a1b2c3d4e5f60718293a4b5c',
  'name': 'Muscat 1',
  'label': 'JWD batch 1',
  'device': {'manufacturer': 'JWD', 'model': 'JWD-X1'},
  'revoked': false,
  'activated_at': _ago(const Duration(days: 10)),
  'last_seen_at': _ago(const Duration(minutes: 2)),
  'status': {
    'battery': 76,
    'charging': true,
    'online': true,
    'wifi_on': true,
    'wifi_ssid': 'MosqueNet',
    'wifi_bars': 3,
    'language': 'bn',
    'serial': 'SN123',
    'model': 'X1 Pro',
    'locked': true,
    'crashes': 2,
    'update': 'Downloading 0.1.5',
    'back_is_speech': true,
  },
  'status_at': _ago(const Duration(minutes: 2)),
  'version_code': 5,
  'version_name': '0.1.4',
  'settings': {'mic_mode': 'recognition'},
  'open_commands': 1,
});

DeviceUnit _quietUnit() => DeviceUnit.fromJson({
  'install_id': 'ffeeddccbbaa99887766',
  'name': '',
  'device': {'model': 'JWD-X1'},
  'last_seen_at': _ago(const Duration(hours: 3)),
  'status': {'online': true, 'battery': 12},
  'status_at': _ago(const Duration(hours: 3)),
  'settings': {},
});

final _fleet = FleetSettings.fromJson({
  'values': <String, Object?>{},
  'schema': {
    'mic_mode': {
      'label': 'Khutbah microphone',
      'type': 'choice',
      'choices': ['call', 'recognition', 'unprocessed'],
      'default': 'call',
      'help': 'Call cancels echo, for a speaker next to the unit.',
    },
    'confidence_gate': {
      'label': 'Hold back translations of unclear speech',
      'type': 'bool',
      'default': true,
      'help':
          'Instead of a guessed translation, the unit asks the listener '
          'to move closer.',
    },
    'checkin_minutes': {
      'label': 'Check in every (minutes)',
      'type': 'int',
      'min': 1,
      'max': 60,
      'default': 5,
      'help': 'How soon a unit sees commands and settings.',
    },
  },
  'commands': ['ping', 'reboot'],
});

class _FakeRepository implements UnitsRepository {
  List<DeviceUnit> units = [_onlineUnit(), _quietUnit()];
  final queued = <(String, String, Map<String, Object?>)>[];
  final patched = <(String, String?, Map<String, Object?>?)>[];
  final savedFleet = <Map<String, Object?>>[];
  final published = <(int, List<String>?)>[];

  @override
  Future<List<DeviceUnit>> fetchUnits() async => units;

  @override
  Future<void> updateUnit(
    String installId, {
    String? name,
    Map<String, Object?>? settings,
  }) async => patched.add((installId, name, settings));

  @override
  Future<void> revoke(String installId) async {}

  @override
  Future<void> restore(String installId) async {}

  @override
  Future<List<UnitCommand>> fetchCommands(String installId) async => [
    for (final (id, type, args) in queued)
      if (id == installId)
        UnitCommand.fromJson({
          'id': 'cmd-$type',
          'type': type,
          'args': args,
          'state': 'pending',
        }),
  ];

  @override
  Future<String> queueCommand(
    String installId,
    String type, [
    Map<String, Object?> args = const {},
  ]) async {
    queued.add((installId, type, args));
    return 'cmd-$type';
  }

  @override
  Future<void> cancelCommand(String installId, String commandId) async {}

  @override
  Future<List<UnitCrashReport>> fetchCrashReports(String installId) async =>
      const [];

  @override
  Future<FleetSettings> fetchFleetSettings() async => _fleet;

  @override
  Future<Map<String, Object?>> saveFleetSettings(
    Map<String, Object?> values,
  ) async {
    savedFleet.add(values);
    return values;
  }

  @override
  Future<List<UnitRelease>> fetchReleases() async => UnitRelease.listFromJson({
    'releases': [
      {
        'version_code': 6,
        'version_name': '0.1.5',
        'size': 23456789,
        'sha256': 'ab' * 32,
        'notes': 'Fixes the microphone on Android 8.1 units.',
        'uploaded_by': 'admin@emam.ai',
        'uploaded_at': _ago(const Duration(hours: 2)),
        'published': false,
        'target': null,
        'file_present': true,
      },
      {
        'version_code': 5,
        'version_name': '0.1.4',
        'size': 23000000,
        'sha256': 'cd' * 32,
        'published': true,
        'target': ['a1b2c3d4e5f60718293a4b5c'],
        'published_at': _ago(const Duration(days: 3)),
        'file_present': false,
      },
    ],
  });

  @override
  Future<UnitRelease> uploadRelease(
    Uint8List apk, {
    String notes = '',
    ProgressCallback? onProgress,
  }) => throw UnimplementedError();

  @override
  Future<void> publishRelease(int versionCode, {List<String>? unitIds}) async =>
      published.add((versionCode, unitIds));

  @override
  Future<void> unpublishRelease(int versionCode) async {}

  @override
  Future<void> deleteRelease(int versionCode) async {}

  @override
  Future<UnitRecordings> fetchRecordings() async => UnitRecordings.fromJson({
    'recordings': [
      {
        'install_id': 'a1b2c3d4e5f60718293a4b5c',
        'name': 'khutbah-2026-11-07T12-30-00.wav',
        'size': 57600000,
        'modified': 1762518600,
        'complete': true,
      },
      {
        'install_id': 'ffeeddccbbaa99887766',
        'name': 'khutbah-2026-11-12T12-30-00.wav',
        'size': 1200000,
        'modified': 1762950600,
        'complete': false,
      },
    ],
    'disk_free_gb': 41.7,
  });

  @override
  Future<Uint8List> downloadRecording(
    String installId,
    String name, {
    ProgressCallback? onProgress,
  }) => throw UnimplementedError();

  @override
  Future<void> deleteRecording(String installId, String name) async {}

  @override
  Future<List<String>> createActivationCodes({
    required int count,
    String label = '',
  }) async => [for (var i = 0; i < count; i++) 'EMAM-AAAA-BBBB-CCC$i'];
}

Future<void> _pump(WidgetTester tester, _FakeRepository repo) async {
  tester.view.physicalSize = const Size(1600, 5000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [unitsRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: Scaffold(body: UnitsView())),
    ),
  );
  await tester.pump();
  await tester.pump();
}

Future<void> _dispose(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
}

Future<void> _openUnit(WidgetTester tester) async {
  await tester.tap(find.text('Muscat 1'));
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('the list shows each unit\'s state and flags', (tester) async {
    await _pump(tester, _FakeRepository());

    expect(find.text('Muscat 1'), findsOneWidget);
    expect(find.text('Online'), findsOneWidget);
    expect(find.text('Serial SN123 · X1 Pro · App 0.1.4 (5)'), findsOneWidget);
    expect(find.text('76%, charging'), findsOneWidget);
    expect(find.text('MosqueNet · 3/4'), findsOneWidget);
    expect(find.text('Bengali'), findsOneWidget);
    for (final flag in [
      'Locked',
      '2 crash reports',
      '1 open command',
      'Downloading 0.1.5',
      'Button 3 = Back',
    ]) {
      expect(find.text(flag), findsOneWidget, reason: flag);
    }

    // No name: the short install ID; its check-in is too old to be online.
    expect(find.text('ffeeddcc…'), findsOneWidget);
    expect(find.text('Last seen 3 h ago'), findsOneWidget);
    expect(find.text('2 units · 1 online'), findsOneWidget);
    await _dispose(tester);
  });

  testWidgets('restarting a unit asks first, then queues the command', (
    tester,
  ) async {
    final repo = _FakeRepository();
    await _pump(tester, repo);
    await _openUnit(tester);

    expect(find.text('Settings for this unit'), findsOneWidget);
    expect(find.text('Command history'), findsOneWidget);

    await tester.tap(find.text('Restart unit'));
    await tester.pumpAndSettle();
    expect(find.text('Restart this unit?'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Restart unit').last);
    await tester.pumpAndSettle();

    expect(repo.queued.single.$2, 'reboot');
    expect(
      find.text(
        'Restart queued. Muscat 1 picks it up at its next check-in '
        '(every 5 minutes).',
      ),
      findsOneWidget,
    );
    await _dispose(tester);
  });

  testWidgets('"Use fleet setting" removes the unit\'s own value', (
    tester,
  ) async {
    final repo = _FakeRepository();
    await _pump(tester, repo);
    await _openUnit(tester);

    expect(find.text('Use fleet setting (Call)'), findsOneWidget);
    await tester.tap(find.text('Use fleet setting (Call)'));
    await tester.pump();
    await tester.tap(find.text('Save settings'));
    await tester.pumpAndSettle();

    final (installId, name, settings) = repo.patched.single;
    expect(installId, 'a1b2c3d4e5f60718293a4b5c');
    expect(name, isNull);
    expect(settings, {'mic_mode': null});
    await _dispose(tester);
  });

  testWidgets('a unit can get its own value for a fleet setting', (
    tester,
  ) async {
    final repo = _FakeRepository();
    await _pump(tester, repo);
    await _openUnit(tester);

    await tester.tap(find.text('Use fleet setting (On)'));
    await tester.pump();
    await tester.tap(find.byType(Switch));
    await tester.pump();
    await tester.tap(find.text('Save settings'));
    await tester.pumpAndSettle();

    expect(repo.patched.single.$3, {'confidence_gate': false});
    await _dispose(tester);
  });

  testWidgets('a PIN is queued only once it has 6 to 12 digits', (
    tester,
  ) async {
    final repo = _FakeRepository();
    await _pump(tester, repo);
    await _openUnit(tester);

    await tester.tap(find.text('Set admin PIN'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '12345');
    await tester.pump();
    final setPin = find.widgetWithText(TextButton, 'Set PIN');
    expect(tester.widget<TextButton>(setPin).onPressed, isNull);

    await tester.enterText(find.byType(TextField).last, '123456');
    await tester.pump();
    await tester.tap(setPin);
    await tester.pumpAndSettle();

    expect(repo.queued.single.$2, 'set_admin_pin');
    expect(repo.queued.single.$3, {'pin': '123456'});
    await _dispose(tester);
  });

  testWidgets('fleet settings show their help and save what changed', (
    tester,
  ) async {
    final repo = _FakeRepository();
    await _pump(tester, repo);

    await tester.tap(find.text('Fleet settings'));
    await tester.pump();
    await tester.pump();

    expect(
      find.text('How soon a unit sees commands and settings.'),
      findsOneWidget,
    );
    expect(
      find.text('Built-in default: Call. 1 unit has its own value.'),
      findsOneWidget,
    );
    expect(find.textContaining('overrides the fleet one'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '10');
    await tester.pump();
    await tester.tap(find.text('Save fleet settings'));
    await tester.pumpAndSettle();

    expect(repo.savedFleet.single, {'checkin_minutes': 10});
    await _dispose(tester);
  });

  testWidgets('a release can be published to chosen units', (tester) async {
    final repo = _FakeRepository();
    await _pump(tester, repo);

    await tester.tap(find.text('Updates'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Version 0.1.5'), findsOneWidget);
    expect(find.text('Not published'), findsOneWidget);
    expect(find.text('Published to 1 unit'), findsOneWidget);
    expect(find.text('APK file missing'), findsOneWidget);
    expect(find.text('Units: Muscat 1'), findsOneWidget);
    expect(find.text('Upload APK'), findsOneWidget);

    await tester.tap(find.text('Publish to selected units').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('ffeeddcc…').last);
    await tester.pump();
    await tester.tap(find.text('Publish to 1 unit'));
    await tester.pumpAndSettle();

    expect(repo.published.single.$1, 6);
    expect(repo.published.single.$2, ['ffeeddccbbaa99887766']);
    expect(find.text('Published version 0.1.5 to 1 unit.'), findsOneWidget);
    await _dispose(tester);
  });

  testWidgets('recordings show their unit and only complete ones act', (
    tester,
  ) async {
    await _pump(tester, _FakeRepository());

    await tester.tap(find.text('Recordings'));
    await tester.pump();
    await tester.pump();

    expect(find.text('2 recordings · 41.7 GB free on the server'), findsOne);
    expect(find.text('Complete'), findsOneWidget);
    expect(find.text('Still uploading'), findsOneWidget);
    expect(find.text('Download'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
    expect(find.text('Muscat 1'), findsOneWidget);
    await _dispose(tester);
  });

  testWidgets('on a phone every tab fits and the unit has its own page', (
    tester,
  ) async {
    final repo = _FakeRepository();
    tester.view.physicalSize = const Size(375, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [unitsRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: Scaffold(body: UnitsView())),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Units (2)'), findsOneWidget);
    expect(find.text('Muscat 1'), findsOneWidget);
    for (final tab in [
      'Fleet settings',
      'Updates',
      'Recordings',
      'Activation codes',
    ]) {
      await tester.tap(find.text(tab));
      await tester.pump();
      await tester.pump();
    }
    expect(find.text('Create activation codes'), findsOneWidget);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [unitsRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(
          home: Scaffold(
            body: UnitDetailView(installId: 'a1b2c3d4e5f60718293a4b5c'),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Back to units'), findsOneWidget);
    expect(find.text('Restart unit'), findsOneWidget);
    expect(find.text('Serial number'), findsOneWidget);
    await _dispose(tester);
  });

  testWidgets('new activation codes are shown once with a warning', (
    tester,
  ) async {
    await _pump(tester, _FakeRepository());

    await tester.tap(find.text('Activation codes'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, '2');
    await tester.pump();
    await tester.tap(find.text('Create 2 codes'));
    await tester.pump();
    await tester.pump();

    expect(find.text('EMAM-AAAA-BBBB-CCC0'), findsOneWidget);
    expect(find.text('EMAM-AAAA-BBBB-CCC1'), findsOneWidget);
    expect(find.textContaining('shown only once'), findsOneWidget);
    expect(find.text('Copy all codes'), findsOneWidget);
    await _dispose(tester);
  });
}
