class RoutePaths {
  RoutePaths._();

  static const String signIn = '/sign-in';
  static const String dashboard = '/dashboard';
  static const String content = '/content';
  static const String voiceDemo = '/voice-demo';
  static const String units = '/units';
  static String unit(String installId) =>
      '$units/${Uri.encodeComponent(installId)}';
  static const String devices = '/devices';
  static const String audit = '/audit';
  static const String notifications = '/notifications';
  static const String systemTools = '/system-tools';
}
