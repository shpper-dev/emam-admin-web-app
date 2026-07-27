import 'package:emam_admin_web_app/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static TextTheme get _textTheme => GoogleFonts.aBeeZeeTextTheme(
        ThemeData.dark().textTheme,
      ).apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      );

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppConstants.bgColor,
        brightness: Brightness.dark,
        fontFamily: GoogleFonts.aBeeZee().fontFamily,
        splashColor: AppConstants.primary.withValues(alpha: 0.10),
        highlightColor: AppConstants.primary.withValues(alpha: 0.05),
        hoverColor: AppConstants.primary.withValues(alpha: 0.06),
        colorScheme: const ColorScheme.dark(
          primary: AppConstants.primary,
          onPrimary: Colors.black,
          surface: AppConstants.bgColor,
          onSurface: Colors.white,
        ),
        textTheme: _textTheme,
        primaryTextTheme: _textTheme,
        appBarTheme: AppBarTheme(
          backgroundColor: AppConstants.bgColor,
          foregroundColor: AppConstants.primary,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          iconTheme: const IconThemeData(color: AppConstants.primary),
          titleTextStyle: GoogleFonts.aBeeZee(
            color: AppConstants.primary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFF1E1E20),
          thickness: 1,
          space: 1,
        ),
        dialogTheme: const DialogThemeData(
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: const CardThemeData(
          surfaceTintColor: Colors.transparent,
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppConstants.primary,
        ),
        tooltipTheme: TooltipThemeData(
          decoration: BoxDecoration(
            color: AppConstants.surfaceColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          textStyle: GoogleFonts.aBeeZee(color: Colors.white, fontSize: 12),
        ),
        scrollbarTheme: ScrollbarThemeData(
          thumbColor: WidgetStateProperty.all(
            Colors.white.withValues(alpha: 0.18),
          ),
          radius: const Radius.circular(8),
          thickness: WidgetStateProperty.all(6),
        ),
        inputDecorationTheme: InputDecorationTheme(
          labelStyle: GoogleFonts.aBeeZee(color: Colors.white),
          hintStyle: GoogleFonts.aBeeZee(color: Colors.white),
          errorStyle: GoogleFonts.aBeeZee(color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.primary,
            foregroundColor: Colors.black,
            disabledBackgroundColor: AppConstants.primary.withValues(alpha: 0.5),
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: GoogleFonts.aBeeZee(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            textStyle: GoogleFonts.aBeeZee(),
          ),
        ),
        listTileTheme: ListTileThemeData(
          titleTextStyle: GoogleFonts.aBeeZee(color: AppConstants.primary),
          iconColor: AppConstants.primary,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppConstants.surfaceColor,
          contentTextStyle: GoogleFonts.aBeeZee(color: Colors.white),
          actionTextColor: AppConstants.primary,
          behavior: SnackBarBehavior.floating,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
        ),
      );
}
