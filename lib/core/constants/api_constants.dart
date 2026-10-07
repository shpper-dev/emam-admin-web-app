class ApiConstants {
  ApiConstants._();

  static const String apiBaseUrl = 'https://pathway.emam.ai';

  static const String authMe = '/admin/auth/me';

  static const String users = '/admin/users';
  static const String usersSearch = '/admin/users/search';
  static const String restrictedUsers = '/admin/users/restricted';

  static String userDetail(String userId) => '$users/$userId/detail';
  static String userPosts(String userId) => '$users/$userId/posts';
  static String userRestriction(String userId) => '$users/$userId/restriction';
  static String userUnblock(String userId) => '$users/$userId/unblock';
  static String userReportsFiled(String userId) =>
      '$users/$userId/reports-filed';
  static String userReportsReceived(String userId) =>
      '$users/$userId/reports-received';
  static String userQuotaReset(String userId) => '$users/$userId/quota/reset';
  static const String moderationReports = '/admin/moderation/reports';
  static String resolveReport(String reportId) =>
      '$moderationReports/$reportId/resolve';
  static const String hiddenPosts = '/admin/moderation/posts/hidden';
  static String hideDuaPost(String postId) =>
      '/admin/moderation/posts/$postId/hide';
  static String restoreDuaPost(String postId) =>
      '/admin/moderation/posts/$postId/restore';

  static const String islamicNews = '/admin/content/islamic-news';
  static const String islamicEvents = '/admin/content/islamic-events';
  static const String practiceCard = '/admin/content/practice-card';
  static const String scholarlyInsights = '/admin/content/scholarly-insights';
  static const String dailyInspiration = '/admin/content/daily-inspiration';

  static const String auditLog = '/admin/audit';

  static const String voiceServer = '/admin/system/voice-server';
  static String voiceServerSwitch(String action) => '$voiceServer/$action';
  static const String voiceDemoUrl =
      '$apiBaseUrl/arabic-accent-mirror-gpt-live-rvc';

  static const String firebaseWebApiKey =
      'AIzaSyDSxatz31b4auOeKlHD9svES3zxsVqOHAU';

  static const String identityToolkitBaseUrl =
      'https://identitytoolkit.googleapis.com/v1';

  static const String secureTokenBaseUrl =
      'https://securetoken.googleapis.com/v1';

  static String get signInUrl =>
      '$identityToolkitBaseUrl/accounts:signInWithPassword?key=$firebaseWebApiKey';

  static String get refreshTokenUrl =>
      '$secureTokenBaseUrl/token?key=$firebaseWebApiKey';
}
