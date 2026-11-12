import 'package:dio/dio.dart';
import 'package:emam_admin_web_app/features/notifications/models/notification_models.dart';
import 'package:emam_admin_web_app/features/notifications/provider/notifications_provider.dart';
import 'package:emam_admin_web_app/features/notifications/provider/notifications_repository_provider.dart';
import 'package:emam_admin_web_app/features/notifications/repository/notifications_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepository implements NotificationsRepository {
  List<ReviewRow>? sentRows;
  int sendCalls = 0;
  bool failSend = false;

  @override
  Future<NotificationOptions> fetchOptions() async =>
      const NotificationOptions(topics: []);

  @override
  Future<TranslateResult> translate({
    required String topic,
    required String title,
    required String body,
  }) async => TranslateResult.fromJson({
    'topic': topic,
    'languages': [
      {
        'lang': 'en',
        'label': 'English',
        'title': 'T',
        'body': 'B',
        'status': 'ok',
      },
      {
        'lang': 'ja',
        'label': 'Japanese',
        'title': '',
        'body': '',
        'status': 'failed',
        'error': 'Write it by hand.',
      },
    ],
  });

  @override
  Future<SendResult> send({
    required String topic,
    required List<ReviewRow> rows,
  }) async {
    sendCalls++;
    if (failSend) {
      throw DioException(requestOptions: RequestOptions(path: '/x'));
    }
    sentRows = rows;
    return const SendResult(sent: ['en'], failed: []);
  }
}

void main() {
  late _FakeRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = _FakeRepository();
    container = ProviderContainer(
      overrides: [notificationsRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    container.listen(notificationsProvider, (_, _) {});
  });

  NotificationsNotifier notifier() =>
      container.read(notificationsProvider.notifier);
  NotificationsState state() => container.read(notificationsProvider);

  test('failed translations are unticked and cannot be sent empty', () async {
    await notifier().translate(topic: 'jumuah', title: 't', body: 'b');
    expect(state().rows.map((r) => r.selected), [true, false]);
    notifier().setAll(true);
    expect(state().toSend.map((r) => r.lang), ['en']);
  });

  test('a hand-written row becomes sendable', () async {
    await notifier().translate(topic: 'jumuah', title: 't', body: 'b');
    notifier().edit('ja', title: 'タイトル', body: '本文');
    notifier().toggle('ja', true);
    expect(state().toSend.map((r) => r.lang), ['en', 'ja']);
  });

  test('over-length text is excluded from the send', () async {
    await notifier().translate(topic: 'jumuah', title: 't', body: 'b');
    notifier().edit('en', title: 'x' * 121);
    expect(state().toSend, isEmpty);
  });

  test('send happens once and then locks the rows', () async {
    await notifier().translate(topic: 'jumuah', title: 't', body: 'b');
    await Future.wait([notifier().send(), notifier().send()]);
    await notifier().send();
    expect(repo.sendCalls, 1);
    expect(repo.sentRows!.map((r) => r.lang), ['en']);
    expect(state().result!.sent, ['en']);
    notifier().edit('en', title: 'changed');
    expect(state().rows.first.title, 'T');
  });

  test('network failure on send warns it may have been delivered', () async {
    repo.failSend = true;
    await notifier().translate(topic: 'jumuah', title: 't', body: 'b');
    await notifier().send();
    expect(state().result, isNull);
    expect(state().error, contains('may already have been delivered'));
    expect(state().rows, isNotEmpty);
  });
}
