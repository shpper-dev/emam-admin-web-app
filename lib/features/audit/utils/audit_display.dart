import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:emam_admin_web_app/core/utils/formatters.dart';
import 'package:emam_admin_web_app/features/audit/models/audit_entry.dart';
import 'package:flutter/material.dart';

/// Human-readable presentation of a raw audit action.
class AuditActionInfo {
  const AuditActionInfo({
    required this.title,
    required this.icon,
    required this.color,
    this.detail,
  });

  final String title;
  final IconData icon;
  final Color color;
  final String? detail;
}

/// Actions offered as filter chips: action key -> (label, icon).
const Map<String, (String, IconData)> kAuditFilters = {
  'voice_server.start': ('Voice on', Icons.play_circle_outline_rounded),
  'voice_server.stop': ('Voice off', Icons.stop_circle_outlined),
  'users.list': ('User lists', Icons.people_outline_rounded),
  'user.view_detail': ('Profile views', Icons.person_search_outlined),
};

AuditActionInfo describeAudit(AuditEntry e) {
  final target = e.targetId.isEmpty || e.targetId == 'all'
      ? null
      : shortId(e.targetId);
  final count = e.metadata['count'];

  switch (e.action) {
    case 'voice_server.start':
      return const AuditActionInfo(
        title: 'Turned the voice server on',
        icon: Icons.play_circle_rounded,
        color: AppConstants.success,
      ).withDetail(target == null ? null : 'Instance $target');
    case 'voice_server.stop':
      return const AuditActionInfo(
        title: 'Turned the voice server off',
        icon: Icons.stop_circle_rounded,
        color: AppConstants.danger,
      ).withDetail(target == null ? null : 'Instance $target');
    case 'users.list':
      return const AuditActionInfo(
        title: 'Viewed the users list',
        icon: Icons.people_rounded,
        color: AppConstants.primary,
      ).withDetail(count == null ? null : '$count users returned');
    case 'user.view_detail':
      return const AuditActionInfo(
        title: 'Opened a user profile',
        icon: Icons.person_search_rounded,
        color: AppConstants.primary,
      ).withDetail(target == null ? null : 'User $target');
  }

  final a = e.action.toLowerCase();
  final color = a.contains('restore') || a.contains('unblock')
      ? AppConstants.success
      : a.contains('block') || a.contains('hide') || a.contains('delete')
      ? AppConstants.danger
      : AppConstants.primary;
  final icon = a.contains('block')
      ? Icons.block_rounded
      : a.contains('hide')
      ? Icons.visibility_off_rounded
      : a.contains('restore')
      ? Icons.restore_rounded
      : Icons.bolt_rounded;
  final extras = [
    if (target != null) '${titleCase(e.targetType)} $target',
    for (final m in e.metadata.entries) '${m.key}: ${m.value}',
  ];
  return AuditActionInfo(
    title: titleCase(e.action.replaceAll(RegExp(r'[._]'), ' ')),
    icon: icon,
    color: color,
    detail: extras.isEmpty ? null : extras.join(' · '),
  );
}

extension on AuditActionInfo {
  AuditActionInfo withDetail(String? detail) =>
      AuditActionInfo(title: title, icon: icon, color: color, detail: detail);
}

/// "Today", "Yesterday", or e.g. "27 Sep 2026".
String dayHeading(DateTime? date, {DateTime? now}) {
  if (date == null) return 'Unknown date';
  final local = date.toLocal();
  final today = _midnight(now ?? DateTime.now());
  final diff = today.difference(_midnight(local)).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${local.day} ${months[local.month - 1]} ${local.year}';
}

DateTime _midnight(DateTime d) => DateTime(d.year, d.month, d.day);

bool sameDay(DateTime? a, DateTime? b) =>
    a != null && b != null && _midnight(a.toLocal()) == _midnight(b.toLocal());

String timeOfDay(DateTime? date) {
  if (date == null) return '';
  final l = date.toLocal();
  return '${l.hour.toString().padLeft(2, '0')}:'
      '${l.minute.toString().padLeft(2, '0')}';
}
