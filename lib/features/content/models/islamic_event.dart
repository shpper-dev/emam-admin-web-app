class IslamicEvent {
  const IslamicEvent({
    required this.slug,
    required this.name,
    required this.arabicName,
    required this.description,
    required this.hijriDate,
    required this.gregorianDate,
    required this.daysRemaining,
    required this.isToday,
  });

  final String slug;
  final String name;
  final String arabicName;
  final String description;
  final String hijriDate;
  final String gregorianDate;
  final int daysRemaining;
  final bool isToday;

  factory IslamicEvent.fromJson(Map<String, dynamic> json) {
    return IslamicEvent(
      slug: json['slug'] as String? ?? '',
      name: json['name'] as String? ?? '',
      arabicName: json['arabic_name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      hijriDate: json['hijri_date'] as String? ?? '',
      gregorianDate: json['gregorian_date'] as String? ?? '',
      daysRemaining: json['days_remaining'] as int? ?? 0,
      isToday: json['is_today'] as bool? ?? false,
    );
  }
}

class IslamicEventsResponse {
  const IslamicEventsResponse({
    required this.count,
    required this.events,
  });

  final int count;
  final List<IslamicEvent> events;

  factory IslamicEventsResponse.fromJson(Map<String, dynamic> json) {
    final events = json['events'] as List<dynamic>? ?? [];

    return IslamicEventsResponse(
      count: json['count'] as int? ?? events.length,
      events: events
          .whereType<Map<String, dynamic>>()
          .map(IslamicEvent.fromJson)
          .toList(),
    );
  }
}
