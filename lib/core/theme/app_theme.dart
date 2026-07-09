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
          iconTheme: const IconThemeData(color: AppConstants.primary),
          titleTextStyle: GoogleFonts.aBeeZee(
            color: AppConstants.primary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
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
          contentTextStyle: GoogleFonts.aBeeZee(color: Colors.black),
        ),
      );
}
