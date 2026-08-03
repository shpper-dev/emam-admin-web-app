import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static TextTheme get _textTheme =>
      GoogleFonts.interTextTheme(ThemeData.dark().textTheme)
          .apply(
            bodyColor: AppConstants.textPrimary,
            displayColor: AppConstants.textPrimary,
          )
          .copyWith(
            headlineMedium: GoogleFonts.inter(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
              color: AppConstants.textPrimary,
            ),
            headlineSmall: GoogleFonts.inter(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: AppConstants.textPrimary,
            ),
            titleLarge: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppConstants.textPrimary,
            ),
            titleMedium: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppConstants.textPrimary,
            ),
            titleSmall: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AppConstants.textPrimary,
            ),
            bodyLarge: GoogleFonts.inter(
              fontSize: 15,
              height: 1.5,
              color: AppConstants.textPrimary,
            ),
            bodyMedium: GoogleFonts.inter(
              fontSize: 14,
              height: 1.45,
              color: AppConstants.textPrimary,
            ),
            bodySmall: GoogleFonts.inter(
              fontSize: 12.5,
              height: 1.4,
              color: AppConstants.textSecondary,
            ),
            labelLarge: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
            labelMedium: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
            labelSmall: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              color: AppConstants.textMuted,
            ),
          );

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppConstants.bgColor,
    brightness: Brightness.dark,
    fontFamily: GoogleFonts.inter().fontFamily,
    splashColor: AppConstants.primary.withValues(alpha: 0.10),
    highlightColor: AppConstants.primary.withValues(alpha: 0.05),
    hoverColor: AppConstants.primary.withValues(alpha: 0.06),
    colorScheme: ColorScheme.dark(
      primary: AppConstants.primary,
      onPrimary: AppConstants.black,
      secondary: AppConstants.success,
      onSecondary: AppConstants.black,
      surface: AppConstants.surfaceColor,
      onSurface: AppConstants.textPrimary,
      error: AppConstants.danger,
      onError: AppConstants.black,
    ),
    textTheme: _textTheme,
    primaryTextTheme: _textTheme,
    iconTheme: IconThemeData(color: AppConstants.textSecondary, size: 22),
    appBarTheme: AppBarTheme(
      backgroundColor: AppConstants.bgColor,
      foregroundColor: AppConstants.primary,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      iconTheme: const IconThemeData(color: AppConstants.primary),
      titleTextStyle: GoogleFonts.inter(
        color: AppConstants.primary,
        fontSize: 19,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppConstants.dividerColor,
      thickness: 1,
      space: 1,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppConstants.surfaceElevated,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        side: BorderSide(color: AppConstants.borderColor),
      ),
    ),
    cardTheme: CardThemeData(
      color: AppConstants.surfaceColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        side: BorderSide(color: AppConstants.borderColor),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppConstants.primary,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: AppConstants.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppConstants.borderColor),
      ),
      textStyle: GoogleFonts.inter(
        color: AppConstants.textPrimary,
        fontSize: 12,
      ),
    ),
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStateProperty.all(Colors.white.withValues(alpha: 0.18)),
      radius: const Radius.circular(8),
      thickness: WidgetStateProperty.all(6),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      side: BorderSide(color: AppConstants.borderColorStrong),
    ),
    inputDecorationTheme: InputDecorationTheme(
      labelStyle: GoogleFonts.inter(color: AppConstants.textSecondary),
      hintStyle: GoogleFonts.inter(color: AppConstants.textFaint),
      errorStyle: GoogleFonts.inter(color: AppConstants.danger),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppConstants.primary,
        foregroundColor: AppConstants.black,
        disabledBackgroundColor: AppConstants.primary.withValues(alpha: 0.5),
        minimumSize: const Size(double.infinity, 52),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppConstants.black,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppConstants.primary,
        side: BorderSide(color: AppConstants.primary.withValues(alpha: 0.55)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusSm),
        ),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppConstants.primary,
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
      ),
    ),
    listTileTheme: ListTileThemeData(
      titleTextStyle: GoogleFonts.inter(
        color: AppConstants.primary,
        fontWeight: FontWeight.w600,
      ),
      iconColor: AppConstants.primary,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppConstants.surfaceElevated,
      contentTextStyle: GoogleFonts.inter(color: AppConstants.textPrimary),
      actionTextColor: AppConstants.primary,
      behavior: SnackBarBehavior.floating,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        side: BorderSide(color: AppConstants.borderColor),
      ),
    ),
  );
}
