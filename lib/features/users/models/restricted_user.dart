import 'package:emam_admin_web_app/features/users/models/app_user.dart';

DateTime? _parseDate(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value);
}

class UserModeration {
  const UserModeration({
    required this.userId,
    required this.postingRestriction,
    required this.restrictedUntil,
    required this.reason,
    required this.canPost,
  });

  final String userId;
  final String postingRestriction;
  final DateTime? restrictedUntil;
  final String reason;
  final bool canPost;

  bool get isTemporary => postingRestriction.toLowerCase() == 'temporary';

  bool get isPermanent => postingRestriction.toLowerCase() == 'permanent';

  factory UserModeration.fromJson(Map<String, dynamic> json) {
    return UserModeration(
      userId: json['user_id'] as String? ?? '',
      postingRestriction: json['posting_restriction'] as String? ?? '',
      restrictedUntil: _parseDate(json['restricted_until']),
      reason: json['reason'] as String? ?? '',
      canPost: json['can_post'] as bool? ?? false,
    );
  }
}

class RestrictedUser {
  const RestrictedUser({
    required this.userId,
    required this.profile,
    required this.moderation,
    required this.restrictedBy,
    required this.updatedAt,
  });

  final String userId;
  final AppUser profile;
  final UserModeration moderation;
  final String restrictedBy;
  final DateTime? updatedAt;

  factory RestrictedUser.fromJson(Map<String, dynamic> json) {
    final profileJson = json['profile'];
    final moderationJson = json['moderation'];

    return RestrictedUser(
      userId: json['user_id'] as String? ?? '',
      profile: profileJson is Map<String, dynamic>
          ? AppUser.fromJson(profileJson)
          : AppUser.fromJson(const {}),
      moderation: moderationJson is Map<String, dynamic>
          ? UserModeration.fromJson(moderationJson)
          : const UserModeration(
              userId: '',
              postingRestriction: '',
              restrictedUntil: null,
              reason: '',
              canPost: false,
            ),
      restrictedBy: json['restricted_by'] as String? ?? '',
      updatedAt: _parseDate(json['updated_at']),
    );
  }
}

class RestrictedUsersResponse {
  const RestrictedUsersResponse({
    required this.users,
    required this.nextPageToken,
    required this.count,
    required this.totalRestricted,
  });

  final List<RestrictedUser> users;
  final String? nextPageToken;
  final int count;
  final int totalRestricted;

  factory RestrictedUsersResponse.fromJson(Map<String, dynamic> json) {
    final rawUsers = json['users'] as List<dynamic>? ?? const [];
    return RestrictedUsersResponse(
      users: rawUsers
          .whereType<Map<String, dynamic>>()
          .map(RestrictedUser.fromJson)
          .toList(),
      nextPageToken: json['next_page_token'] as String?,
      count: json['count'] as int? ?? rawUsers.length,
      totalRestricted: json['total_restricted'] as int? ?? rawUsers.length,
    );
  }
}
