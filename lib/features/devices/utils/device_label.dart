import 'package:flutter/material.dart';

/// Best-effort OS + browser name parsed from a `navigator.userAgent`
/// string, for display in the "Signed-in devices" tab only.
class DeviceLabel {
  const DeviceLabel({required this.os, required this.browser});

  final String os;
  final String browser;

  factory DeviceLabel.fromUserAgent(String userAgent) {
    return DeviceLabel(
      os: _parseOs(userAgent),
      browser: _parseBrowser(userAgent),
    );
  }

  String get title => browser == _unknownBrowser ? os : '$os · $browser';

  IconData get icon => os == 'Android' || os == 'iOS'
      ? Icons.smartphone_rounded
      : Icons.computer_rounded;

  static const _unknownBrowser = 'Unknown browser';

  static String _parseOs(String ua) {
    if (ua.contains('Windows')) return 'Windows';
    if (ua.contains('Mac OS X') || ua.contains('Macintosh')) return 'macOS';
    if (ua.contains('Android')) return 'Android';
    if (ua.contains('iPhone') || ua.contains('iPad')) return 'iOS';
    if (ua.contains('Linux')) return 'Linux';
    return 'Unknown OS';
  }

  static String _parseBrowser(String ua) {
    if (ua.contains('Edg/')) return 'Edge';
    if (ua.contains('OPR/') || ua.contains('Opera')) return 'Opera';
    if (ua.contains('Chrome/')) return 'Chrome';
    if (ua.contains('Firefox/')) return 'Firefox';
    if (ua.contains('Safari/')) return 'Safari';
    return _unknownBrowser;
  }
}
