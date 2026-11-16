enum CmsStatus {
  draft('draft', 'Draft'),
  pendingReview('pending_review', 'Pending review'),
  approved('approved', 'Approved'),
  rejected('rejected', 'Rejected'),
  published('published', 'Published');

  const CmsStatus(this.wire, this.label);
  final String wire;
  final String label;

  static CmsStatus parse(Object? raw) => CmsStatus.values.firstWhere(
    (s) => s.wire == raw,
    orElse: () => CmsStatus.draft,
  );
}

/// The four daily modules. The slug is a closed set so it can never be
/// built from free text into a request path.
enum CmsModule {
  dailyInspiration('daily-inspiration', 'Daily inspiration'),
  islamicNews('islamic-news', 'Islamic news'),
  practiceCard('practice-card', 'Practice card'),
  scholarlyInsights('scholarly-insights', 'Scholarly insights');

  const CmsModule(this.slug, this.label);
  final String slug;
  final String label;

  /// Starter payload matching what the public API returns.
  Map<String, dynamic> get template => switch (this) {
    dailyInspiration => {
      'daily_dua': {'text_en': '', 'text_ar': '', 'source': ''},
      'ayah_of_the_day': {
        'text_en': '',
        'text_ar': '',
        'surah_info': '',
        'surah_id': '',
      },
    },
    islamicNews => {'news_feed': <Object>[]},
    practiceCard => {
      'arabic_text': '',
      'focus_topic': '',
      'audio_sample_url': '',
      'surah_number': 1,
      'verse_number': 1,
      'date_dubai': '',
    },
    scholarlyInsights => {'scholarly_insights': <Object>[]},
  };
}

Map<String, dynamic> _map(Object? v) =>
    v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

class CmsEntry {
  const CmsEntry({
    required this.id,
    required this.status,
    required this.scheduledFor,
    required this.payload,
    required this.reviewNote,
    required this.updatedAt,
  });

  final String id;
  final CmsStatus status;
  final String scheduledFor;
  final Map<String, dynamic> payload;
  final String reviewNote;
  final String updatedAt;

  factory CmsEntry.fromJson(Map<String, dynamic> json) => CmsEntry(
    id: (json['id'] as String?) ?? '',
    status: CmsStatus.parse(json['status']),
    scheduledFor: (json['scheduled_for'] as String?) ?? '',
    payload: _map(json['payload']),
    reviewNote: (json['review_note'] as String?) ?? '',
    updatedAt: (json['updated_at'] as String?) ?? '',
  );
}

class CmsArticle {
  const CmsArticle({
    required this.id,
    required this.slug,
    required this.contentType,
    required this.status,
    required this.locales,
    required this.heroImageUrl,
    required this.reviewNote,
    required this.updatedAt,
  });

  final String id;
  final String slug;
  final String contentType;
  final CmsStatus status;
  final Map<String, Map<String, dynamic>> locales;
  final String heroImageUrl;
  final String reviewNote;
  final String updatedAt;

  factory CmsArticle.fromJson(Map<String, dynamic> json) => CmsArticle(
    id: (json['id'] as String?) ?? '',
    slug: (json['slug'] as String?) ?? '',
    contentType: (json['content_type'] as String?) ?? 'guide',
    status: CmsStatus.parse(json['status']),
    locales: {
      for (final e in _map(json['locales']).entries) e.key: _map(e.value),
    },
    heroImageUrl: (json['hero_image_url'] as String?) ?? '',
    reviewNote: (json['review_note'] as String?) ?? '',
    updatedAt: (json['updated_at'] as String?) ?? '',
  );

  String get title {
    final en = locales['en']?['title'];
    if (en is String && en.isNotEmpty) return en;
    return slug;
  }
}

class PublishResult {
  const PublishResult({required this.redisOk});
  final bool redisOk;
}
