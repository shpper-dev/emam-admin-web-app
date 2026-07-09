import 'dart:ui';

class AppConstants {
  AppConstants._();

  static const Color bgColor = Color(0xFF0A0A0B);
  static const Color primary = Color(0xFFD4AF37);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  /// Slightly lifted surface derived from [bgColor] and [white].
  static final Color surfaceColor = Color.lerp(bgColor, white, 0.08)!;

  /// Input fill derived from [bgColor] and [white].
  static final Color inputFillColor = Color.lerp(bgColor, white, 0.04)!;

  static const String emamLogo = 'assets/images/emam.png';
}
