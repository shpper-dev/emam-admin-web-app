/// Limits enforced by the backend; mirrored here so the admin gets feedback
/// before a request is made. The server re-validates everything.
class NotificationLimits {
  NotificationLimits._();

  static const int titleMax = 120;
  static const int bodyMax = 500;
}

class NotificationTopic {
  const NotificationTopic({required this.id, required this.label});

  factory NotificationTopic.fromJson(Map<String, dynamic> json) =>
      NotificationTopic(
        id: json['id'] as String,
        label: (json['label'] as String?) ?? json['id'] as String,
      );

  final String id;
  final String label;
}

class NotificationOptions {
  const NotificationOptions({required this.topics});

  factory NotificationOptions.fromJson(Map<String, dynamic> json) {
    final topics = json['topics'];
    return NotificationOptions(
      topics: [
        if (topics is List)
          for (final t in topics)
            if (t is Map<String, dynamic>) NotificationTopic.fromJson(t),
      ],
    );
  }

  final List<NotificationTopic> topics;
}

/// One language row of the translate response, plus the admin's edits and
/// whether it is ticked for sending.
class ReviewRow {
  const ReviewRow({
    required this.lang,
    required this.label,
    required this.title,
    required this.body,
    required this.selected,
    this.error,
  });

  factory ReviewRow.fromJson(Map<String, dynamic> json) {
    final ok = json['status'] == 'ok';
    final lang = json['lang'] as String;
    return ReviewRow(
      lang: lang,
      label: (json['label'] as String?) ?? lang,
      title: (json['title'] as String?) ?? '',
      body: (json['body'] as String?) ?? '',
      // Failed translations stay unticked until the admin writes them.
      selected: ok,
      error: ok ? null : json['error'] as String?,
    );
  }

  final String lang;
  final String label;
  final String title;
  final String body;
  final bool selected;
  final String? error;

  bool get titleValid {
    final length = title.trim().length;
    return length > 0 && length <= NotificationLimits.titleMax;
  }

  bool get bodyValid {
    final length = body.trim().length;
    return length > 0 && length <= NotificationLimits.bodyMax;
  }

  bool get isValid => titleValid && bodyValid;

  /// Ticked and complete: will be included in the send.
  bool get willSend => selected && isValid;

  ReviewRow copyWith({String? title, String? body, bool? selected}) =>
      ReviewRow(
        lang: lang,
        label: label,
        title: title ?? this.title,
        body: body ?? this.body,
        selected: selected ?? this.selected,
        error: error,
      );
}

class TranslateResult {
  const TranslateResult({required this.topic, required this.rows});

  factory TranslateResult.fromJson(Map<String, dynamic> json) {
    final languages = json['languages'];
    return TranslateResult(
      topic: json['topic'] as String,
      rows: [
        if (languages is List)
          for (final l in languages)
            if (l is Map<String, dynamic>) ReviewRow.fromJson(l),
      ],
    );
  }

  final String topic;
  final List<ReviewRow> rows;
}

class SendResult {
  const SendResult({required this.sent, required this.failed});

  factory SendResult.fromJson(Map<String, dynamic> json) => SendResult(
    sent: _strings(json['sent']),
    failed: _strings(json['failed']),
  );

  final List<String> sent;
  final List<String> failed;

  static List<String> _strings(Object? value) => [
    if (value is List)
      for (final v in value)
        if (v is String) v,
  ];
}
