import 'package:emam_admin_web_app/features/moderation/models/moderation_report.dart';

bool isReportedPostHidden(
  ModerationReport report,
  Set<String> hiddenPostIds, [
  Set<String> moreHiddenPostIds = const {},
]) {
  if (report.isPostHidden) return true;
  final postId = report.postId.trim();
  if (postId.isEmpty) return false;
  return hiddenPostIds.contains(postId) || moreHiddenPostIds.contains(postId);
}
