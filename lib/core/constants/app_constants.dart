import 'package:flutter/material.dart';

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

  /// Standard bordered card look shared by user/moderation list cards and
  /// content thumbnail cards.
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: bgColor,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.25),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static const String emamLogo = 'assets/images/emam.png';

  static const String feedbackUrl = 'https://crisp.chat/en/';
}
