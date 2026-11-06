import 'package:emam_admin_web_app/features/devices/models/signed_in_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('admin list is read from a top-level sessions array', () {
    final parsed = SignedInSessions.fromJson({
      'sessions': [
        {
          'id': 'sess-1',
          'admin_user_id': 'uid-1',
          'admin_email': 'boss@emam.ai',
          'device_name': 'Chrome',
          'ip_address': '1.2.3.4',
          'started_at': '2026-11-06T06:00:00Z',
          'last_accessed_at': '2026-11-06T07:00:00Z',
          'expires_at': '2026-11-06T16:00:00Z',
          'is_current': true,
        },
      ],
    });

    expect(parsed.sessions, hasLength(1));
    final session = parsed.sessions.single;
    expect(session.id, 'sess-1');
    expect(session.adminUserId, 'uid-1');
    expect(session.adminEmail, 'boss@emam.ai');
    expect(session.deviceName, 'Chrome');
    expect(session.isCurrent, isTrue);
    expect(session.ipAddress, '1.2.3.4');
    expect(session.startedAt, isNotNull);
  });

  test('student envelope data.sessions is still accepted', () {
    final parsed = SignedInSessions.fromJson({
      'code': 200,
      'status': 'success',
      'data': {
        'sessions': [
          {'session_id': 'sess-2', 'device_name': 'Safari'},
        ],
        'current_session_id': 'sess-2',
      },
    });

    expect(parsed.sessions.single.id, 'sess-2');
    expect(parsed.sessions.single.isCurrent, isTrue);
  });

  test('rows that are not Map<String, dynamic> are kept', () {
    final parsed = SignedInSessions.fromJson({
      'sessions': [
        Map<dynamic, dynamic>.from({
          'id': 'sess-3',
          'uid': 'uid-3',
          'email': 'other@emam.ai',
          'device_name': 'Firefox',
        }),
      ],
    });

    expect(parsed.sessions.single.id, 'sess-3');
    expect(parsed.sessions.single.adminUserId, 'uid-3');
    expect(parsed.sessions.single.adminEmail, 'other@emam.ai');
  });

  test(
    'stored portal session id marks this browser when is_current is absent',
    () {
      final parsed = SignedInSessions.fromJson({
        'sessions': [
          {'id': 'mine', 'device_name': 'Chrome'},
          {'id': 'other', 'device_name': 'Safari'},
        ],
      }).withCurrent('mine');

      expect(parsed.sessions.first.isCurrent, isTrue);
      expect(parsed.sessions.last.isCurrent, isFalse);
    },
  );
}
