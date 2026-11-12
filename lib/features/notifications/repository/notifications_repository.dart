import 'package:dio/dio.dart';
import 'package:emam_admin_web_app/core/constants/api_constants.dart';
import 'package:emam_admin_web_app/core/network/dio_client.dart';
import 'package:emam_admin_web_app/features/notifications/models/notification_models.dart';

class NotificationsRepository {
  NotificationsRepository(this._client);

  final DioClient _client;

  Future<NotificationOptions> fetchOptions() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.notificationOptions,
    );
    return NotificationOptions.fromJson(response.data ?? {});
  }

  /// Translating runs several model calls server-side, so it gets a longer
  /// receive timeout than the client default.
  Future<TranslateResult> translate({
    required String topic,
    required String title,
    required String body,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.notificationTranslate,
      data: {'topic': topic, 'title': title.trim(), 'body': body.trim()},
      options: Options(receiveTimeout: const Duration(seconds: 120)),
    );
    return TranslateResult.fromJson(response.data ?? {});
  }

  Future<SendResult> send({
    required String topic,
    required List<ReviewRow> rows,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.notificationSend,
      data: {
        'topic': topic,
        'items': [
          for (final row in rows)
            {
              'lang': row.lang,
              'title': row.title.trim(),
              'body': row.body.trim(),
            },
        ],
      },
    );
    return SendResult.fromJson(response.data ?? {});
  }
}
