import 'package:emam_admin_web_app/features/users/models/app_user.dart';

/// Recent posts per page on the user detail endpoint.
const int kUserDetailPostsPageSize = 10;

DateTime? _parseDate(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value);
}

class UserDetailModeration {
  const UserDetailModeration({
    required this.postingRestriction,
    required this.canPost,
  });

  final String postingRestriction;
  final bool canPost;

  factory UserDetailModeration.fromJson(Map<String, dynamic> json) {
    return UserDetailModeration(
      postingRestriction: json['posting_restriction'] as String? ?? '',
      canPost: json['can_post'] as bool? ?? false,
    );
  }
}

class UserDetailStats {
  const UserDetailStats({
    required this.prayersTracked,
    required this.khutbahsAi,
    required this.tajweedScore,
    required this.qariRecitationCount,
  });

  final int prayersTracked;
  final int khutbahsAi;
  final double tajweedScore;
  final int qariRecitationCount;

  factory UserDetailStats.fromJson(Map<String, dynamic> json) {
    return UserDetailStats(
      prayersTracked: json['prayers_tracked'] as int? ?? 0,
      khutbahsAi: json['khutbahs_ai'] as int? ?? 0,
      tajweedScore: (json['tajweed_score'] as num?)?.toDouble() ?? 0,
      qariRecitationCount: json['qari_recitation_count'] as int? ?? 0,
    );
  }
}

class UserDetailRecitation {
  const UserDetailRecitation({
    required this.totalAyahsRead,
    required this.overallPercent,
    required this.surahsStarted,
    required this.surahsCompleted,
  });

  final int totalAyahsRead;
  final double overallPercent;
  final int surahsStarted;
  final int surahsCompleted;

  factory UserDetailRecitation.fromJson(Map<String, dynamic> json) {
    return UserDetailRecitation(
      totalAyahsRead: json['total_ayahs_read'] as int? ?? 0,
      overallPercent: (json['overall_percent'] as num?)?.toDouble() ?? 0,
      surahsStarted: json['surahs_started'] as int? ?? 0,
      surahsCompleted: json['surahs_completed'] as int? ?? 0,
    );
  }
}

class UserRecentPost {
  const UserRecentPost({
    required this.id,
    required this.userId,
    required this.userDisplayName,
    required this.location,
    required this.content,
    required this.ameenCount,
    required this.reportCount,
    required this.status,
    required this.hiddenReason,
    required this.hiddenBy,
    required this.hiddenAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String userDisplayName;
  final String location;
  final String content;
  final int ameenCount;
  final int reportCount;
  final String status;
  final String? hiddenReason;
  final String? hiddenBy;
  final DateTime? hiddenAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory UserRecentPost.fromJson(Map<String, dynamic> json) {
    return UserRecentPost(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      userDisplayName: json['user_display_name'] as String? ?? '',
      location: json['location'] as String? ?? '',
      content: json['content'] as String? ?? '',
      ameenCount: json['ameen_count'] as int? ?? 0,
      reportCount: json['report_count'] as int? ?? 0,
      status: json['status'] as String? ?? '',
      hiddenReason: json['hidden_reason'] as String?,
      hiddenBy: json['hidden_by'] as String?,
      hiddenAt: _parseDate(json['hidden_at']),
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }
}

class UserRecentPostsPage {
  const UserRecentPostsPage({
    required this.posts,
    required this.nextPageToken,
  });

  final List<UserRecentPost> posts;
  final String? nextPageToken;

  factory UserRecentPostsPage.fromJson(Map<String, dynamic> json) {
    final rawPosts = json['posts'] as List<dynamic>? ?? const [];
    return UserRecentPostsPage(
      posts: rawPosts
          .whereType<Map<String, dynamic>>()
          .map(UserRecentPost.fromJson)
          .toList(),
      nextPageToken: json['next_page_token'] as String?,
    );
  }
}

class UserDetailResponse {
  const UserDetailResponse({
    required this.found,
    required this.user,
    required this.moderation,
    required this.postCount,
    required this.hiddenPostCount,
    required this.stats,
    required this.recitation,
    required this.recentPosts,
  });

  final bool found;
  final AppUser user;
  final UserDetailModeration moderation;
  final int postCount;
  final int hiddenPostCount;
  final UserDetailStats stats;
  final UserDetailRecitation recitation;
  final UserRecentPostsPage recentPosts;

  factory UserDetailResponse.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];
    final moderationJson = json['moderation'];
    final statsJson = json['stats'];
    final recitationJson = json['recitation'];
    final recentPostsJson = json['recent_posts'];

    return UserDetailResponse(
      found: json['found'] as bool? ?? false,
      user: userJson is Map<String, dynamic>
          ? AppUser.fromJson(userJson)
          : AppUser.fromJson(const {}),
      moderation: moderationJson is Map<String, dynamic>
          ? UserDetailModeration.fromJson(moderationJson)
          : const UserDetailModeration(
              postingRestriction: '',
              canPost: false,
            ),
      postCount: json['post_count'] as int? ?? 0,
      hiddenPostCount: json['hidden_post_count'] as int? ?? 0,
      stats: statsJson is Map<String, dynamic>
          ? UserDetailStats.fromJson(statsJson)
          : const UserDetailStats(
              prayersTracked: 0,
              khutbahsAi: 0,
              tajweedScore: 0,
              qariRecitationCount: 0,
            ),
      recitation: recitationJson is Map<String, dynamic>
          ? UserDetailRecitation.fromJson(recitationJson)
          : const UserDetailRecitation(
              totalAyahsRead: 0,
              overallPercent: 0,
              surahsStarted: 0,
              surahsCompleted: 0,
            ),
      recentPosts: recentPostsJson is Map<String, dynamic>
          ? UserRecentPostsPage.fromJson(recentPostsJson)
          : const UserRecentPostsPage(posts: [], nextPageToken: null),
    );
  }
}
