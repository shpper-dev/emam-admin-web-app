class RamadanSettings {
  const RamadanSettings({
    required this.enabled,
    required this.hijriYear,
    required this.bannerTitle,
    required this.bannerBody,
    required this.featuredSlugs,
    required this.modules,
  });

  final bool enabled;
  final int? hijriYear;
  final String bannerTitle;
  final String bannerBody;
  final List<String> featuredSlugs;
  final Map<String, bool> modules;

  factory RamadanSettings.fromJson(Map<String, dynamic> json) {
    final mods = json['modules'];
    final slugs = json['featured_article_slugs'];
    return RamadanSettings(
      enabled: json['enabled'] == true,
      hijriYear: json['hijri_year'] is int ? json['hijri_year'] as int : null,
      bannerTitle: (json['home_banner_title'] as String?) ?? '',
      bannerBody: (json['home_banner_body'] as String?) ?? '',
      featuredSlugs: [
        if (slugs is List)
          for (final s in slugs)
            if (s is String) s,
      ],
      modules: {
        if (mods is Map)
          for (final e in mods.entries)
            if (e.key is String && e.value is bool)
              e.key as String: e.value as bool,
      },
    );
  }
}
