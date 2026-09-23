import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tokens.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final headingFont = GoogleFonts.fraunces();
    final bodyFont = GoogleFonts.ibmPlexSans();

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: TnnColors.paper,
      colorScheme: ColorScheme.fromSeed(
        seedColor: TnnColors.ink,
        brightness: Brightness.light,
        primary: TnnColors.ink,
        secondary: TnnColors.gold,
        error: TnnColors.brick,
        surface: TnnColors.card,
      ),
      fontFamily: bodyFont.fontFamily,
    );

    return base.copyWith(
      textTheme: base.textTheme
          .apply(bodyColor: TnnColors.ink, displayColor: TnnColors.ink)
          .copyWith(
            headlineLarge: GoogleFonts.fraunces(fontSize: 26, fontWeight: FontWeight.w600, color: TnnColors.ink),
            headlineMedium: GoogleFonts.fraunces(fontSize: 21, fontWeight: FontWeight.w600, color: TnnColors.ink),
            headlineSmall: GoogleFonts.fraunces(fontSize: 18, fontWeight: FontWeight.w600, color: TnnColors.ink),
            titleLarge: GoogleFonts.fraunces(fontSize: 16, fontWeight: FontWeight.w600, color: TnnColors.ink),
            bodyLarge: bodyFont.copyWith(fontSize: 14, color: TnnColors.ink),
            bodyMedium: bodyFont.copyWith(fontSize: 13, color: TnnColors.inkSoft),
            labelLarge: bodyFont.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
          ),
      appBarTheme: AppBarTheme(
        backgroundColor: TnnColors.ink,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: headingFont.copyWith(fontSize: 19, fontWeight: FontWeight.w600, color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: TnnColors.gold,
          foregroundColor: TnnColors.ink,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TnnRadius.md)),
          textStyle: bodyFont.copyWith(fontWeight: FontWeight.w700, fontSize: 14),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: TnnColors.brick,
          side: const BorderSide(color: TnnColors.line),
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TnnRadius.md)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: TnnColors.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(TnnRadius.md), borderSide: const BorderSide(color: TnnColors.line)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(TnnRadius.md), borderSide: const BorderSide(color: TnnColors.line)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(TnnRadius.md), borderSide: const BorderSide(color: TnnColors.gold, width: 1.5)),
      ),
      cardTheme: CardThemeData(
        color: TnnColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TnnRadius.lg), side: const BorderSide(color: TnnColors.lineSoft)),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(color: TnnColors.lineSoft, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: TnnColors.ink,
        contentTextStyle: bodyFont.copyWith(color: Colors.white, fontSize: 13),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TnnRadius.md)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: TnnColors.card,
        selectedItemColor: TnnColors.ink,
        unselectedItemColor: Color(0xFF9AA3B5),
        selectedIconTheme: IconThemeData(color: TnnColors.goldDeep),
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
