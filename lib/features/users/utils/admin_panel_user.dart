import 'package:emam_admin_web_app/features/users/models/app_user.dart';
import 'package:emam_admin_web_app/features/users/models/restricted_user.dart';
import 'package:emam_admin_web_app/features/users/models/user_detail.dart';

/// Signed-in admin; excluded from all user listings in this panel.
const String kAdminPanelUserEmail = 'safaandsafa4@gmail.com';

bool isAdminPanelUserEmail(String email) {
  return email.trim().toLowerCase() == kAdminPanelUserEmail.toLowerCase();
}

bool isAdminPanelAppUser(AppUser user) => isAdminPanelUserEmail(user.email);

bool isAdminPanelRestrictedUser(RestrictedUser user) =>
    isAdminPanelUserEmail(user.profile.email);

UsersResponse withoutAdminPanelUsers(UsersResponse response) {
  final users =
      response.users.where((u) => !isAdminPanelAppUser(u)).toList();
  if (users.length == response.users.length) return response;
  final removed = response.users.length - users.length;
  return UsersResponse(
    users: users,
    nextPageToken: response.nextPageToken,
    count: (response.count - removed).clamp(0, response.count),
  );
}

RestrictedUsersResponse withoutAdminPanelRestrictedUsers(
  RestrictedUsersResponse response,
) {
  final users = response.users
      .where((u) => !isAdminPanelRestrictedUser(u))
      .toList();
  if (users.length == response.users.length) return response;
  final removed = response.users.length - users.length;
  return RestrictedUsersResponse(
    users: users,
    nextPageToken: response.nextPageToken,
    count: (response.count - removed).clamp(0, response.count),
    totalRestricted:
        (response.totalRestricted - removed).clamp(0, response.totalRestricted),
  );
}

UserDetailResponse hideAdminPanelUserDetail(UserDetailResponse detail) {
  if (!isAdminPanelAppUser(detail.user)) return detail;
  return UserDetailResponse(
    found: false,
    user: detail.user,
    moderation: detail.moderation,
    postCount: 0,
    hiddenPostCount: 0,
    stats: detail.stats,
    recitation: detail.recitation,
    recentPosts: const UserRecentPostsPage(posts: [], nextPageToken: null),
  );
}
