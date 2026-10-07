import 'package:emam_admin_web_app/features/users/models/app_user.dart';
import 'package:emam_admin_web_app/features/users/models/restricted_user.dart';
import 'package:emam_admin_web_app/features/users/models/user_detail.dart';

/// The signed-in admin (identity from `/admin/auth/me`) is excluded from all
/// user listings in this panel.
bool isAdminPanelUserEmail(String email, String? adminEmail) {
  if (adminEmail == null || adminEmail.trim().isEmpty) return false;
  return email.trim().toLowerCase() == adminEmail.trim().toLowerCase();
}

/// Matches by uid first (always present, unlike a profile's email), then email.
bool isAdminPanelUser(AppUser user, {String? adminEmail, String? adminUserId}) {
  final id = adminUserId?.trim() ?? '';
  if (id.isNotEmpty && user.id.trim() == id) return true;
  return isAdminPanelUserEmail(user.email, adminEmail);
}

UsersResponse withoutAdminPanelUsers(
  UsersResponse response,
  String? adminEmail, {
  String? adminUserId,
}) {
  final users = response.users
      .where(
        (u) => !isAdminPanelUser(
          u,
          adminEmail: adminEmail,
          adminUserId: adminUserId,
        ),
      )
      .toList();
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
  String? adminEmail, {
  String? adminUserId,
}) {
  final users = response.users
      .where(
        (u) =>
            !isAdminPanelUser(
              u.profile,
              adminEmail: adminEmail,
              adminUserId: adminUserId,
            ) &&
            (adminUserId == null ||
                adminUserId.isEmpty ||
                u.userId != adminUserId),
      )
      .toList();
  if (users.length == response.users.length) return response;
  final removed = response.users.length - users.length;
  return RestrictedUsersResponse(
    users: users,
    nextPageToken: response.nextPageToken,
    count: (response.count - removed).clamp(0, response.count),
    totalRestricted: (response.totalRestricted - removed).clamp(
      0,
      response.totalRestricted,
    ),
  );
}

UserDetailResponse hideAdminPanelUserDetail(
  UserDetailResponse detail,
  String? adminEmail, {
  String? adminUserId,
}) {
  if (!isAdminPanelUser(
    detail.user,
    adminEmail: adminEmail,
    adminUserId: adminUserId,
  )) {
    return detail;
  }
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
