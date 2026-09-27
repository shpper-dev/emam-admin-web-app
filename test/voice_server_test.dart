import 'package:emam_admin_web_app/features/voice_server/models/voice_server_status.dart';
import 'package:emam_admin_web_app/features/voice_server/provider/voice_server_repository_provider.dart';
import 'package:emam_admin_web_app/features/voice_server/repository/voice_server_repository.dart';
import 'package:emam_admin_web_app/features/voice_server/views/voice_server_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

VoiceServerStatus _status(
  String state, {
  bool ready = false,
  bool configured = true,
}) {
  return VoiceServerStatus.fromJson({
    'configured': configured,
    'state': state,
    'ready': ready,
    'running_minutes': 42,
    'estimated_cost_usd': 0.41,
    'hourly_cost_usd': 0.58,
    'idle_shutdown_minutes': 60,
    'active_sessions': 0,
  });
}

class _FakeRepository implements VoiceServerRepository {
  _FakeRepository(this.status);

  VoiceServerStatus status;
  int turnOnCalls = 0;

  @override
  Future<VoiceServerStatus> fetchStatus() async => status;

  @override
  Future<VoiceServerStatus> turnOn() async {
    turnOnCalls++;
    return status = _status('pending');
  }

  @override
  Future<VoiceServerStatus> turnOff() async => status = _status('stopping');
}

Future<void> _pumpView(WidgetTester tester, _FakeRepository repo) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [voiceServerRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: Scaffold(body: VoiceServerView())),
    ),
  );
  await tester.pump();
}

Future<void> _disposeView(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
}

void main() {
  test('backend states map to phases', () {
    expect(_status('stopped').phase, VoiceServerPhase.off);
    expect(_status('pending').phase, VoiceServerPhase.starting);
    expect(_status('running').phase, VoiceServerPhase.loadingVoice);
    expect(_status('running', ready: true).phase, VoiceServerPhase.ready);
    expect(_status('stopping').phase, VoiceServerPhase.stopping);
    expect(_status('terminated').phase, VoiceServerPhase.unavailable);
    expect(
      _status('not_configured', configured: false).phase,
      VoiceServerPhase.notConfigured,
    );
  });

  test('the switch is only offered when it can work', () {
    expect(_status('stopped').canTurnOn, isTrue);
    expect(_status('stopped').canTurnOff, isFalse);
    expect(_status('running', ready: true).canTurnOff, isTrue);
    expect(_status('pending').canTurnOn, isFalse);
    expect(_status('stopping').canTurnOff, isFalse);
  });

  testWidgets('an off server can be turned on', (tester) async {
    final repo = _FakeRepository(_status('stopped'));
    await _pumpView(tester, repo);

    expect(find.text('Off'), findsOneWidget);
    await tester.tap(find.text('Turn on'));
    await tester.pump();

    expect(repo.turnOnCalls, 1);
    expect(find.text('Starting'), findsOneWidget);
    expect(find.text('Turn on'), findsNothing);
    await _disposeView(tester);
  });

  testWidgets('a ready server shows its cost and the demo link', (
    tester,
  ) async {
    await _pumpView(tester, _FakeRepository(_status('running', ready: true)));

    expect(find.text('Ready'), findsOneWidget);
    expect(find.text('Open demo'), findsOneWidget);
    expect(find.text('Turn off'), findsOneWidget);
    expect(find.textContaining('On for 42 min'), findsOneWidget);
    await _disposeView(tester);
  });
}
