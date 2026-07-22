import 'package:emam_admin_web_app/features/moderation/models/moderation_report.dart';

bool isReportedPostHidden(
  ModerationReport report,
  Set<String> hiddenPostIds,
) {
  if (report.isPostHidden) return true;
  final postId = report.postId.trim();
  if (postId.isEmpty) return false;
  if (hiddenPostIds.contains(postId)) return true;
  return hiddenPostIds.any(
    (id) => id.trim().toLowerCase() == postId.toLowerCase(),
  );
}
