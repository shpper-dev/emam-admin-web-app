class ScholarlyInsight {
  const ScholarlyInsight({
    required this.id,
    required this.title,
    required this.author,
    required this.type,
    required this.thumbnailUrl,
    required this.externalLink,
    required this.audioUrl,
  });

  final String id;
  final String title;
  final String author;
  final String type;
  final String thumbnailUrl;
  final String externalLink;
  final String audioUrl;

  factory ScholarlyInsight.fromJson(Map<String, dynamic> json) {
    return ScholarlyInsight(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      author: json['author'] as String? ?? '',
      type: json['type'] as String? ?? '',
      thumbnailUrl: json['thumbnail_url'] as String? ?? '',
      externalLink: json['external_link'] as String? ?? '',
      audioUrl: json['audio_url'] as String? ?? '',
    );
  }
}

class ScholarlyInsightsResponse {
  const ScholarlyInsightsResponse({
    required this.source,
    required this.generatedAt,
    required this.insights,
  });

  final String source;
  final String generatedAt;
  final List<ScholarlyInsight> insights;

  factory ScholarlyInsightsResponse.fromJson(Map<String, dynamic> json) {
    final payload = json['payload'] as Map<String, dynamic>? ?? {};
    final items = payload['scholarly_insights'] as List<dynamic>? ?? [];

    return ScholarlyInsightsResponse(
      source: json['source'] as String? ?? '',
      generatedAt: payload['generated_at'] as String? ?? '',
      insights: items
          .whereType<Map<String, dynamic>>()
          .map(ScholarlyInsight.fromJson)
          .toList(),
    );
  }
}
