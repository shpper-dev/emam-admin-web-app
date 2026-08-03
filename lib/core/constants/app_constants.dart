import 'package:flutter/material.dart';

/// Central design tokens for the admin panel: brand palette, semantic
/// colors, and the spacing/radius scale. Keep raw color/number literals out
/// of feature widgets — add a token here instead so the visual language
/// stays consistent across the app.
class AppConstants {
  AppConstants._();

  // --- Brand ---------------------------------------------------------
  /// Deep charcoal base, echoing the near-black of the Emam wordmark card.
  static const Color bgColor = Color(0xFF0A0A0C);

  /// Brand gold, lifted from the Emam mark.
  static const Color primary = Color(0xFFD4AF37);

  /// Lighter gold used for hover/emphasis states.
  static const Color primaryLight = Color(0xFFE4C767);

  /// Deeper gold used for pressed states.
  static const Color primaryDark = Color(0xFFB6912A);

  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // --- Surfaces --------------------------------------------------------
  /// Card / panel surface, lifted slightly off [bgColor].
  static final Color surfaceColor = Color.lerp(bgColor, white, 0.07)!;

  /// Higher surface for popovers, dialogs and hovered rows.
  static final Color surfaceElevated = Color.lerp(bgColor, white, 0.12)!;

  /// Input fill, lifted just enough to separate it from the page background.
  static final Color inputFillColor = Color.lerp(bgColor, white, 0.045)!;

  /// Hairline divider between grouped content.
  static const Color dividerColor = Color(0xFF212226);

  /// Standard hairline border used around cards and tiles.
  static final Color borderColor = Colors.white.withValues(alpha: 0.08);

  /// Stronger border for hovered/selected/emphasized containers.
  static final Color borderColorStrong = Colors.white.withValues(alpha: 0.16);

  // --- Text --------------------------------------------------------------
  static const Color textPrimary = white;
  static const Color textSecondary = Color(0xBDFFFFFF); // ~74% white
  static const Color textMuted = Color(0x99FFFFFF); // ~60% white
  static const Color textFaint = Color(0x75FFFFFF); // ~46% white

  // --- Semantic status colors ---------------------------------------
  /// Positive / success state (unblock, restore, active, can-post).
  static const Color success = Color(0xFF4ADE80);

  /// Destructive / negative state (block, hide, permanent restriction).
  static const Color danger = Color(0xFFEF5A5A);

  /// Caution state (temporary restriction, pending review).
  static const Color warning = Color(0xFFF5A94E);

  /// Informational accents (links, neutral highlights).
  static const Color info = Color(0xFF5B9DF5);

  // --- Spacing scale (use with SizedBox/Padding for consistent rhythm) --
  static const double space4 = 4;
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space32 = 32;
  static const double space40 = 40;

  // --- Radius scale -------------------------------------------------
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radiusPill = 999;

  /// Standard bordered card look shared by user/moderation list cards and
  /// content thumbnail cards.
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: surfaceColor,
    borderRadius: BorderRadius.circular(radiusMd),
    border: Border.all(color: borderColor),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.28),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
    ],
  );

  static const String emamLogo = 'assets/images/emam.png';

  static const String feedbackUrl = 'https://crisp.chat/en/';
}
