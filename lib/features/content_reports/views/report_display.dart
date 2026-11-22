import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:emam_admin_web_app/core/utils/formatters.dart';
import 'package:flutter/material.dart';

Color reportStatusColor(String status) => switch (status) {
  'new' => AppConstants.warning,
  'in_review' => AppConstants.info,
  'fixed' => AppConstants.success,
  'rejected' => AppConstants.danger,
  _ => AppConstants.textMuted,
};

IconData reportTypeIcon(String type) => switch (type) {
  'quran_ayah' => Icons.menu_book_rounded,
  'quran_translation' => Icons.translate_rounded,
  'tafsir' => Icons.auto_stories_rounded,
  'hadith' => Icons.format_quote_rounded,
  'dua' => Icons.volunteer_activism_rounded,
  'lesson' => Icons.school_rounded,
  _ => Icons.spellcheck_rounded,
};

bool isRtlLang(String lang) => const {'ar', 'ur', 'fa', 'he'}.contains(lang);

/// "just now", "5m ago", "3h ago", "2d ago", then the calendar date.
String relativeTime(DateTime? date) {
  if (date == null) return 'unknown';
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return formatAdminDate(date);
}
