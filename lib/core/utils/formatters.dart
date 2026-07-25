/// Capitalizes the first letter and lowercases the rest, e.g. `PERMANENT` ->
/// `Permanent`. Returns [value] unchanged when empty.
String titleCase(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1).toLowerCase();
}

/// Truncates long ids for display, e.g. `abcdefghijklmnop` -> `abcdefgh…`.
/// Returns [value] unchanged when it's already short.
String shortId(String value) {
  if (value.length <= 10) return value;
  return '${value.substring(0, 8)}…';
}

/// Formats [date] in local time as `YYYY-MM-DD` (or `YYYY-MM-DD HH:MM` when
/// [includeTime] is true), or [unknownLabel] when [date] is null.
String formatAdminDate(
  DateTime? date, {
  String unknownLabel = 'unknown',
  bool includeTime = false,
}) {
  if (date == null) return unknownLabel;

  final local = date.toLocal();
  final datePart =
      '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
  if (!includeTime) return datePart;

  return '$datePart '
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}
