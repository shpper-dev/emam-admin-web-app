class PracticeCard {
  const PracticeCard({
    required this.id,
    required this.isRecommended,
    required this.surahNumber,
    required this.surahName,
    required this.verseNumber,
    required this.arabicText,
    required this.focusTopic,
    required this.audioSampleUrl,
    required this.dateDubai,
    required this.generatedAt,
    required this.source,
  });

  final String id;
  final bool isRecommended;
  final int surahNumber;
  final String surahName;
  final int verseNumber;
  final String arabicText;
  final String focusTopic;
  final String audioSampleUrl;
  final String dateDubai;
  final String generatedAt;
  final String source;

  factory PracticeCard.fromJson(Map<String, dynamic> json) {
    final payload = json['payload'] as Map<String, dynamic>? ?? json;
    final isRecommended = payload['is_recommended'];

    return PracticeCard(
      source: json['source'] as String? ?? '',
      generatedAt: payload['generated_at'] as String? ?? '',
      dateDubai: payload['date_dubai'] as String? ?? '',
      id: payload['id'] as String? ?? '',
      isRecommended: isRecommended == true || isRecommended == 'is_recommended',
      surahNumber: payload['surah_number'] as int? ?? 0,
      surahName: payload['surah_name'] as String? ?? '',
      verseNumber: payload['verse_number'] as int? ?? 0,
      arabicText: payload['arabic_text'] as String? ?? '',
      focusTopic: payload['focus_topic'] as String? ?? '',
      audioSampleUrl: payload['audio_sample_url'] as String? ?? '',
    );
  }
}
