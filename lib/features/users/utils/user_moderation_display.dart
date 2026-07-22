/// Whether the user is under a posting restriction (blocked).
bool isUserPostingRestricted({
  bool? canPost,
  String postingRestriction = '',
}) {
  if (canPost == false) return true;
  final normalized = postingRestriction.trim().toLowerCase();
  return normalized == 'temporary' || normalized == 'permanent';
}

/// Human-readable time until [restrictedUntil], or null if not in the future.
String? restrictionRemainingLabel(DateTime? restrictedUntil) {
  if (restrictedUntil == null) return null;
  final now = DateTime.now();
  if (!restrictedUntil.isAfter(now)) return null;

  var remaining = restrictedUntil.difference(now);
  final days = remaining.inDays;
  if (days >= 1) {
    final hours = remaining.inHours % 24;
    final dayPart = '$days day${days == 1 ? '' : 's'}';
    if (hours == 0) return dayPart;
    return '$dayPart, $hours hour${hours == 1 ? '' : 's'}';
  }

  final hours = remaining.inHours;
  if (hours >= 1) {
    final minutes = remaining.inMinutes % 60;
    final hourPart = '$hours hour${hours == 1 ? '' : 's'}';
    if (minutes == 0) return hourPart;
    return '$hourPart, $minutes minute${minutes == 1 ? '' : 's'}';
  }

  final minutes = remaining.inMinutes;
  if (minutes >= 1) {
    return '$minutes minute${minutes == 1 ? '' : 's'}';
  }
  return 'less than a minute';
}
