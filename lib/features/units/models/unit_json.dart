/// Lenient readers for the device fleet API, whose values come from
/// Firestore documents and from whatever a unit reported.
String? readString(Object? value) {
  if (value is String) return value.isEmpty ? null : value;
  if (value is num || value is bool) return value.toString();
  return null;
}

int? readInt(Object? value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

double? readDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

bool? readBool(Object? value) {
  if (value is bool) return value;
  if (value == 'true') return true;
  if (value == 'false') return false;
  return null;
}

DateTime? readDate(Object? value) {
  if (value is String) return DateTime.tryParse(value);
  return null;
}

/// Unix seconds, as file modification times are sent.
DateTime? readEpochSeconds(Object? value) {
  if (value is! num) return null;
  return DateTime.fromMillisecondsSinceEpoch(
    (value * 1000).round(),
    isUtc: true,
  );
}

Map<String, Object?> readMap(Object? value) {
  if (value is! Map) return const {};
  return {
    for (final entry in value.entries)
      if (entry.key is String) entry.key as String: entry.value,
  };
}

List<Map<String, Object?>> readMaps(Object? value) {
  if (value is! List) return const [];
  return [
    for (final item in value)
      if (item is Map) readMap(item),
  ];
}

List<String> readStrings(Object? value) {
  if (value is! List) return const [];
  return [
    for (final item in value)
      if (item is String) item,
  ];
}
