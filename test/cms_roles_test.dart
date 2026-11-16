import 'package:emam_admin_web_app/features/cms/models/cms_entry.dart';
import 'package:emam_admin_web_app/features/cms/models/staff_session.dart';
import 'package:emam_admin_web_app/features/cms/repository/cms_repository.dart';
import 'package:emam_admin_web_app/features/cms/views/widgets/cms_common.dart';
import 'package:flutter_test/flutter_test.dart';

StaffSession staff(List<String> roles, {bool platform = false}) =>
    StaffSession.fromJson({
      'uid': 'u1',
      'staff_roles': roles,
      'is_platform_admin': platform,
    });

void main() {
  test('unknown roles are dropped', () {
    final s = staff(['editor', 'superuser']);
    expect(s.roles, {'editor'});
    expect(s.canReview, isFalse);
    expect(s.canManageStaff, isFalse);
  });

  test('editor can submit/publish a draft but not approve', () {
    final a = availableActions(staff(['editor']), CmsStatus.draft);
    expect(a, [CmsAction.submit, CmsAction.publish]);
    expect(
      availableActions(staff(['editor']), CmsStatus.pendingReview),
      isEmpty,
    );
  });

  test('only reviewers approve/reject, and nobody edits published', () {
    final r = staff(['scholar_reviewer']);
    expect(availableActions(r, CmsStatus.pendingReview), [
      CmsAction.approve,
      CmsAction.reject,
    ]);
    expect(canPatch(staff([], platform: true), CmsStatus.published), isFalse);
    expect(canPatch(staff(['editor']), CmsStatus.pendingReview), isFalse);
  });

  test('input validators', () {
    expect(CmsLimits.slug.hasMatch('ramadan-guide'), isTrue);
    expect(CmsLimits.slug.hasMatch('../admin'), isFalse);
    expect(CmsLimits.validHttpsUrl('javascript:alert(1)'), isFalse);
    expect(CmsLimits.validHttpsUrl('http://x.com/a.jpg'), isFalse);
    expect(CmsLimits.validHttpsUrl('https://x.com/a.jpg'), isTrue);
    expect(CmsLimits.validDate('2026-13-45'), isFalse);
  });
}
