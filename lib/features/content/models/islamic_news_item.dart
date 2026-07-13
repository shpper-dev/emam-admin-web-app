class IslamicNewsItem {
  const IslamicNewsItem({
    required this.id,
    required this.title,
    required this.category,
    required this.publishedAt,
    required this.sourceUrl,
    required this.imageUrl,
  });

  final String id;
  final String title;
  final String category;
  final String publishedAt;
  final String sourceUrl;
  final String imageUrl;

  factory IslamicNewsItem.fromJson(Map<String, dynamic> json) {
    return IslamicNewsItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      category: json['category'] as String? ?? '',
      publishedAt: json['published_at'] as String? ?? '',
      sourceUrl: json['source_url'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
    );
  }
}

class IslamicNewsResponse {
  const IslamicNewsResponse({
    required this.source,
    required this.generatedAt,
    required this.newsFeed,
  });

  final String source;
  final String generatedAt;
  final List<IslamicNewsItem> newsFeed;

  factory IslamicNewsResponse.fromJson(Map<String, dynamic> json) {
    final payload = json['payload'] as Map<String, dynamic>? ?? {};
    final feed = payload['news_feed'] as List<dynamic>? ?? [];

    return IslamicNewsResponse(
      source: json['source'] as String? ?? '',
      generatedAt: payload['generated_at'] as String? ?? '',
      newsFeed: feed
          .whereType<Map<String, dynamic>>()
          .map(IslamicNewsItem.fromJson)
          .toList(),
    );
  }
}
