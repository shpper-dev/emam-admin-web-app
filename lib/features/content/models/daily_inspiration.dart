class DailyDua {
  const DailyDua({
    required this.textEn,
    required this.textAr,
    required this.source,
  });

  final String textEn;
  final String textAr;
  final String source;

  factory DailyDua.fromJson(Map<String, dynamic> json) {
    return DailyDua(
      textEn: json['text_en'] as String? ?? '',
      textAr: json['text_ar'] as String? ?? '',
      source: json['source'] as String? ?? '',
    );
  }
}

class AyahOfTheDay {
  const AyahOfTheDay({
    required this.textEn,
    required this.textAr,
    required this.surahInfo,
    required this.surahId,
  });

  final String textEn;
  final String textAr;
  final String surahInfo;
  final String surahId;

  factory AyahOfTheDay.fromJson(Map<String, dynamic> json) {
    return AyahOfTheDay(
      textEn: json['text_en'] as String? ?? '',
      textAr: json['text_ar'] as String? ?? '',
      surahInfo: json['surah_info'] as String? ?? '',
      surahId: json['surah_id']?.toString() ?? '',
    );
  }
}

class DailyInspiration {
  const DailyInspiration({
    required this.source,
    required this.generatedAt,
    required this.dailyDua,
    required this.ayahOfTheDay,
  });

  final String source;
  final String generatedAt;
  final DailyDua dailyDua;
  final AyahOfTheDay ayahOfTheDay;

  factory DailyInspiration.fromJson(Map<String, dynamic> json) {
    final payload = json['payload'] as Map<String, dynamic>? ?? {};

    return DailyInspiration(
      source: json['source'] as String? ?? '',
      generatedAt: payload['generated_at'] as String? ?? '',
      dailyDua: DailyDua.fromJson(
        payload['daily_dua'] as Map<String, dynamic>? ?? {},
      ),
      ayahOfTheDay: AyahOfTheDay.fromJson(
        payload['ayah_of_the_day'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}
