import 'package:dio/dio.dart';
import 'package:emam_admin_web_app/core/network/api_error.dart';
import 'package:emam_admin_web_app/features/notifications/models/notification_models.dart';
import 'package:emam_admin_web_app/features/notifications/provider/notifications_repository_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final notificationOptionsProvider =
    FutureProvider.autoDispose<NotificationOptions>(
      (ref) => ref.watch(notificationsRepositoryProvider).fetchOptions(),
    );

class NotificationsState {
  const NotificationsState({
    this.topic,
    this.rows = const [],
    this.translating = false,
    this.sending = false,
    this.error,
    this.result,
  });

  /// Topic the current [rows] were translated for. Null while composing.
  final String? topic;
  final List<ReviewRow> rows;
  final bool translating;
  final bool sending;
  final String? error;
  final SendResult? result;

  bool get isReviewing => rows.isNotEmpty && result == null;
  List<ReviewRow> get toSend => rows.where((r) => r.willSend).toList();
  bool get busy => translating || sending;

  String labelFor(String lang) {
    for (final row in rows) {
      if (row.lang == lang) return row.label;
    }
    return lang;
  }
}

final notificationsProvider =
    NotifierProvider.autoDispose<NotificationsNotifier, NotificationsState>(
      NotificationsNotifier.new,
    );

class NotificationsNotifier extends Notifier<NotificationsState> {
  @override
  NotificationsState build() => const NotificationsState();

  Future<void> translate({
    required String topic,
    required String title,
    required String body,
  }) async {
    if (state.busy) return;
    state = NotificationsState(translating: true, topic: state.topic);
    try {
      final result = await ref
          .read(notificationsRepositoryProvider)
          .translate(topic: topic, title: title, body: body);
      if (!ref.mounted) return;
      state = result.rows.isEmpty
          ? const NotificationsState(error: 'No translations were returned.')
          : NotificationsState(topic: result.topic, rows: result.rows);
    } on DioException catch (error) {
      if (ref.mounted) state = NotificationsState(error: parseApiError(error));
    } catch (_) {
      if (ref.mounted) {
        state = const NotificationsState(
          error: 'Unexpected response from the server.',
        );
      }
    }
  }

  void toggle(String lang, bool selected) =>
      _update(lang, (r) => r.copyWith(selected: selected));

  void setAll(bool selected) {
    if (state.busy) return;
    state = NotificationsState(
      topic: state.topic,
      rows: [
        for (final r in state.rows)
          // Never tick a row that is incomplete.
          r.copyWith(selected: selected && r.isValid),
      ],
    );
  }

  void edit(String lang, {String? title, String? body}) =>
      _update(lang, (r) => r.copyWith(title: title, body: body));

  void _update(String lang, ReviewRow Function(ReviewRow) change) {
    if (state.busy || state.result != null) return;
    state = NotificationsState(
      topic: state.topic,
      rows: [for (final r in state.rows) r.lang == lang ? change(r) : r],
    );
  }

  /// Sends the ticked, valid rows. Guarded so a double click can never send
  /// twice; there is no way to undo a push.
  Future<void> send() async {
    final topic = state.topic;
    final rows = state.toSend;
    if (state.busy || state.result != null || topic == null || rows.isEmpty) {
      return;
    }
    state = NotificationsState(topic: topic, rows: state.rows, sending: true);
    try {
      final result = await ref
          .read(notificationsRepositoryProvider)
          .send(topic: topic, rows: rows);
      if (!ref.mounted) return;
      state = NotificationsState(
        topic: topic,
        rows: state.rows,
        result: result,
      );
    } on DioException catch (error) {
      if (ref.mounted) {
        state = NotificationsState(
          topic: topic,
          rows: state.rows,
          error: error.type == DioExceptionType.badResponse
              ? parseApiError(error)
              // No server answer: it may still have gone out, so warn
              // before the admin presses send again.
              : '${parseApiError(error)} The notification may already have '
                    'been delivered; confirm before sending again.',
        );
      }
    } catch (_) {
      if (ref.mounted) {
        state = NotificationsState(
          topic: topic,
          rows: state.rows,
          error: 'Unexpected response from the server.',
        );
      }
    }
  }

  void reset() => state = const NotificationsState();
}
