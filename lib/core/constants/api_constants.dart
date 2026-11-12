class ApiConstants {
  ApiConstants._();

  static const String apiBaseUrl = 'https://pathway.emam.ai';

  /// IDs come from backend responses; encode them so a malformed value can't
  /// add path segments or a query string to an `/admin/*` request.
  static String _seg(String value) => Uri.encodeComponent(value);

  static const String authMe = '/admin/auth/me';

  static const String users = '/admin/users';
  static const String usersSearch = '/admin/users/search';
  static const String restrictedUsers = '/admin/users/restricted';

  static String userDetail(String userId) => '$users/${_seg(userId)}/detail';
  static String userPosts(String userId) => '$users/${_seg(userId)}/posts';
  static String userRestriction(String userId) =>
      '$users/${_seg(userId)}/restriction';
  static String userUnblock(String userId) => '$users/${_seg(userId)}/unblock';
  static String userReportsFiled(String userId) =>
      '$users/${_seg(userId)}/reports-filed';
  static String userReportsReceived(String userId) =>
      '$users/${_seg(userId)}/reports-received';
  static String userQuotaReset(String userId) =>
      '$users/${_seg(userId)}/quota/reset';
  static const String moderationReports = '/admin/moderation/reports';
  static String resolveReport(String reportId) =>
      '$moderationReports/${_seg(reportId)}/resolve';
  static const String moderationQueue = '/admin/moderation/queue';
  static String moderationPost(String postId) =>
      '/admin/moderation/posts/${_seg(postId)}';
  static const String hiddenPosts = '/admin/moderation/posts/hidden';
  static String hideDuaPost(String postId) =>
      '/admin/moderation/posts/${_seg(postId)}/hide';
  static String restoreDuaPost(String postId) =>
      '/admin/moderation/posts/${_seg(postId)}/restore';

  static const String islamicNews = '/admin/content/islamic-news';
  static const String islamicEvents = '/admin/content/islamic-events';
  static const String practiceCard = '/admin/content/practice-card';
  static const String scholarlyInsights = '/admin/content/scholarly-insights';
  static const String dailyInspiration = '/admin/content/daily-inspiration';

  static const String demoSession = '/api/auth/demo-session';
  static const String authSessionsAll = '/admin/auth/sessions/all';
  static String authSession(String sessionId) =>
      '/admin/auth/sessions/${_seg(sessionId)}';

  static const String auditLog = '/admin/audit';

  static const String notificationOptions = '/admin/notifications/options';
  static const String notificationTranslate = '/admin/notifications/translate';
  static const String notificationSend = '/admin/notifications/send';

  static const String voiceServer = '/admin/system/voice-server';
  static String voiceServerSwitch(String action) => '$voiceServer/$action';
  static const String voiceDemoUrl =
      '$apiBaseUrl/arabic-accent-mirror-gpt-live-rvc';

  static const String cacheInvalidate = '/admin/system/cache/invalidate';
  static const String ragReload = '/admin/system/rag/reload';

  // E-mam handheld units; the backend calls them devices.
  static const String units = '/api/admin/devices';
  static String unit(String installId) => '$units/${_seg(installId)}';
  static String unitRevoke(String installId) => '${unit(installId)}/revoke';
  static String unitRestore(String installId) => '${unit(installId)}/restore';
  static String unitCommands(String installId) => '${unit(installId)}/commands';
  static String unitCommand(String installId, String commandId) =>
      '${unitCommands(installId)}/${_seg(commandId)}';
  static String unitCrashes(String installId) => '${unit(installId)}/crashes';
  static const String unitSettings = '/api/admin/device-settings';
  static const String unitReleases = '/api/admin/device-releases';
  static String unitRelease(int versionCode) => '$unitReleases/$versionCode';
  static String unitReleasePublish(int versionCode) =>
      '${unitRelease(versionCode)}/publish';
  static String unitReleaseUnpublish(int versionCode) =>
      '${unitRelease(versionCode)}/unpublish';
  static const String unitRecordings = '/api/admin/device-recordings';
  static String unitRecording(String installId, String name) =>
      '$unitRecordings/${_seg(installId)}/${_seg(name)}';
  static const String unitActivationCodes = '/api/admin/device-codes';

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
