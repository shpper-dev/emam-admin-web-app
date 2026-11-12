import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:emam_admin_web_app/features/units/models/device_unit.dart';
import 'package:emam_admin_web_app/features/units/models/unit_settings.dart';
import 'package:emam_admin_web_app/features/units/utils/unit_display.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime.utc(2026, 11, 12, 10, 0);

DeviceUnit _unit({
  Map<String, Object?> status = const {},
  String? statusAt,
  String? lastSeenAt,
  Map<String, Object?> settings = const {},
  bool revoked = false,
  int openCommands = 0,
  String name = 'Muscat 1',
}) => DeviceUnit.fromJson({
  'install_id': 'a1b2c3d4e5f60718293a4b5c',
  'name': name,
  'label': '',
  'device': {'manufacturer': 'JWD', 'model': 'JWD-X1'},
  'revoked': revoked,
  'activated_at': '2026-11-01T08:00:00+00:00',
  'last_seen_at': lastSeenAt,
  'status': status,
  'status_at': statusAt,
  'version_code': 5,
  'version_name': '0.1.4',
  'settings': settings,
  'open_commands': openCommands,
});

void main() {
  test('relative times read naturally', () {
    String ago(Duration d) => relativeTime(_now.subtract(d), _now);
    expect(ago(const Duration(seconds: 20)), 'just now');
    expect(
      relativeTime(_now.add(const Duration(minutes: 2)), _now),
      'just now',
    );
    expect(ago(const Duration(minutes: 5)), '5 min ago');
    expect(ago(const Duration(minutes: 59)), '59 min ago');
    expect(ago(const Duration(hours: 3)), '3 h ago');
    expect(ago(const Duration(hours: 30)), '1 day ago');
    expect(ago(const Duration(days: 12)), '12 days ago');
    expect(ago(const Duration(days: 45)), startsWith('on 2026-09-'));
  });

  test('presence says online or when the unit was last seen', () {
    expect(
      presenceLabel(
        _unit(status: {'online': true}, statusAt: '2026-11-12T09:58:00Z'),
        _now,
      ),
      'Online',
    );
    expect(
      presenceLabel(
        _unit(status: {'online': true}, statusAt: '2026-11-12T09:40:00Z'),
        _now,
      ),
      'Last seen 20 min ago',
    );
    expect(
      presenceLabel(
        _unit(status: {'online': false}, statusAt: '2026-11-12T09:57:00Z'),
        _now,
      ),
      'Last seen 3 min ago',
    );
    expect(
      presenceLabel(
        _unit(
          status: {'online': true},
          statusAt: '2026-11-11T10:00:00Z',
          lastSeenAt: '2026-11-12T07:00:00Z',
        ),
        _now,
      ),
      'Last seen 3 h ago',
    );
    expect(presenceLabel(_unit(), _now), 'Not checked in yet');
  });

  test('sizes and durations', () {
    expect(formatFileSize(512), '512 B');
    expect(formatFileSize(45200), '45 KB');
    expect(formatFileSize(12345678), '12.3 MB');
    expect(formatFileSize(2500000000), '2.50 GB');
    expect(formatMegabytes(850), '850 MB');
    expect(formatMegabytes(1234), '1.2 GB');
    expect(formatUptime(42), '42 min');
    expect(formatUptime(120), '2 h');
    expect(formatUptime(125), '2 h 5 min');
    expect(formatUptime(60 * 24 + 60 * 3), '1 day 3 h');
    expect(formatUptime(60 * 48), '2 days');
  });

  test('status values get plain words', () {
    final status = <String, Object?>{
      'battery': 76,
      'charging': true,
      'online': false,
      'wifi_on': true,
      'wifi_ssid': null,
      'wifi_bars': 3,
      'language': 'bn',
      'locked': true,
      'admin_pin_set': false,
      'mic_mode': 'unprocessed',
      'back_is_speech': true,
      'uptime_min': 125,
      'free_storage_mb': 1234,
      'active': null,
      'update': null,
    };
    expect(statusValue('battery', status), '76%, charging');
    expect(statusValue('battery', {'battery': 9}), '9%');
    expect(statusValue('online', status), 'Not connected');
    expect(statusValue('wifi_on', status), 'On');
    expect(statusValue('wifi_ssid', status), 'None');
    expect(statusValue('wifi_bars', status), '3 of 4 bars');
    expect(statusValue('language', status), 'Bengali (bn)');
    expect(statusValue('locked', status), 'Locked');
    expect(statusValue('admin_pin_set', status), 'Not set');
    expect(statusValue('mic_mode', status), 'Unprocessed');
    expect(statusValue('back_is_speech', status), 'Yes');
    expect(statusValue('uptime_min', status), '2 h 5 min');
    expect(statusValue('free_storage_mb', status), '1.2 GB');
    expect(statusValue('active', status), 'None');
    expect(statusValue('update', status), 'Nothing pending');
    expect(statusValue('serial', const {}), 'Unknown');
    expect(statusLabel('free_memory_mb'), 'Free memory');
    expect(statusLabel('new_sensor_reading'), 'New sensor reading');
  });

  test('the status grid groups known keys and keeps unknown ones', () {
    final groups = describeStatus(
      _unit(
        status: {
          'battery': 50,
          'charging': false,
          'online': true,
          'model': 'X1 Pro',
          'mic_mode': 'call',
          'new_sensor_reading': 7,
        },
        statusAt: '2026-11-12T09:58:00Z',
      ),
      _now,
    );
    final titles = groups.map((g) => g.title).toList();
    expect(titles, [
      'Connection',
      'Power',
      'App',
      'Device',
      'Activation',
      'Other',
    ]);

    final labels = {
      for (final group in groups)
        for (final entry in group.entries) entry.label: entry.value,
    };
    expect(labels['Last check-in'], startsWith('2 min ago'));
    expect(labels['Internet'], 'Connected');
    expect(labels['Battery'], '50%');
    expect(labels['App version'], '0.1.4 (5)');
    expect(labels['Khutbah microphone'], 'Call');
    expect(labels['Model'], 'X1 Pro');
    expect(labels['Manufacturer'], 'JWD');
    expect(labels['Install ID'], 'a1b2c3d4e5f60718293a4b5c');
    expect(labels['New sensor reading'], '7');
    // Charging is part of the battery line, not a row of its own.
    expect(labels.containsKey('Charging'), isFalse);
  });

  test('command arguments are summarised without secrets', () {
    expect(
      describeCommandArgs('add_wifi', {
        'ssid': 'MosqueNet',
        'password': '•••',
        'security': 'wpa2',
      }),
      'MosqueNet · WPA2 · password •••',
    );
    expect(
      describeCommandArgs('add_wifi', {'ssid': 'Open', 'security': 'open'}),
      'Open · OPEN',
    );
    expect(describeCommandArgs('set_admin_pin', {'pin': '•••'}), 'PIN •••');
    expect(describeCommandArgs('lock', {'message': ''}), 'Default message');
    expect(
      describeCommandArgs('lock', {'message': 'Back soon'}),
      '"Back soon"',
    );
    expect(
      describeCommandArgs('record_khutbah', {'sessions': 3}),
      '3 sessions',
    );
    expect(describeCommandArgs('reboot', const {}), isNull);
    expect(commandLabel('reboot'), 'Restart');
    expect(commandLabel('future_thing'), 'Future thing');
  });

  test('flags show what needs attention', () {
    final unit = _unit(
      status: {
        'locked': true,
        'crashes': 2,
        'update': 'Update failed 0.1.5: download damaged',
        'back_is_speech': true,
      },
      revoked: true,
      openCommands: 1,
    );
    final flags = unitFlags(unit);
    expect(flags.map((f) => f.label), [
      'Revoked',
      'Locked',
      '2 crash reports',
      '1 open command',
      'Update failed 0.1.5: download damaged',
      'Button 3 = Back',
    ]);
    expect(flags[4].color, AppConstants.danger);
    expect(
      unitFlags(_unit(status: {'update': 'Downloading 0.1.5'})).single.color,
      AppConstants.info,
    );
    expect(unitFlags(_unit()), isEmpty);
  });

  test('queued commands say when the unit picks them up', () {
    final fleet = FleetSettings.fromJson({
      'values': {'checkin_minutes': 10},
      'schema': {
        'checkin_minutes': {'type': 'int', 'min': 1, 'max': 60, 'default': 5},
      },
    });
    final unit = _unit();
    expect(checkInMinutes(unit, fleet), 10);
    expect(checkInMinutes(_unit(settings: {'checkin_minutes': 1}), fleet), 1);
    expect(checkInMinutes(unit, null), isNull);
    expect(
      queuedMessage('reboot', unit, 10),
      'Restart queued. Muscat 1 picks it up at its next check-in '
      '(every 10 minutes).',
    );
    expect(checkInHint(null), 'every few minutes');
    expect(checkInHint(1), 'every minute');
  });

  test('summaries for the list row', () {
    expect(
      batterySummary(_unit(status: {'battery': 40, 'charging': true})),
      '40%, charging',
    );
    expect(batterySummary(_unit()), 'Battery unknown');
    expect(
      wifiSummary(
        _unit(
          status: {'wifi_on': true, 'wifi_ssid': 'MosqueNet', 'wifi_bars': 2},
        ),
      ),
      'MosqueNet · 2/4',
    );
    expect(wifiSummary(_unit(status: {'wifi_on': false})), 'Wi-Fi off');
    expect(wifiSummary(_unit(status: {'wifi_on': true})), 'No Wi-Fi network');
    expect(languageName('fil'), 'Filipino');
    expect(languageName('xx'), 'xx');
  });
}
