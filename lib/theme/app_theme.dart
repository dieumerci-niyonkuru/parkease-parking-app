import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Brand Colors ──────────────────────────────────────────────
  static const Color primary     = Color(0xFF7A5B40); // Brown from the image
  static const Color primaryDark = Color(0xFF5D432D);
  static const Color primaryDeep = Color(0xFF453020);
  static const Color accent      = Color(0xFF7A5B40); // Standardize with brown
  static const Color accentDeep  = Color(0xFF5D432D);
  static const Color warning     = Color(0xFFFFB300);
  static const Color danger      = Color(0xFFFF4F4F);
  static const Color success     = Color(0xFF28A745);

  // ── Neutral Palette (Light Theme) ─────────────────────────────
  static const Color bgDeep      = Color(0xFFF4F6F8); // Off-white/grey background
  static const Color bgDark      = Color(0xFFEAECEF);
  static const Color bgCard      = Color(0xFFFFFFFF); // White cards
  static const Color bgSurface   = Color(0xFFFFFFFF);
  static const Color bgElevated  = Color(0xFFFFFFFF);
  static const Color border      = Color(0xFFE0E0E0);
  static const Color borderLight = Color(0xFFEEEEEE);

  // ── Text Colors ───────────────────────────────────────────────
  static const Color textPrimary  = Color(0xFF212529); // Dark grey/black
  static const Color textSecond   = Color(0xFF495057);
  static const Color textMuted    = Color(0xFF868E96);
  static const Color textHint     = Color(0xFFADB5BD);

  // ── Shadows ───────────────────────────────────────────────────
  static List<BoxShadow> glowShadow = [
    BoxShadow(
      color: primary.withValues(alpha: 0.3),
      blurRadius: 20,
      spreadRadius: -2,
      offset: const Offset(0, 10),
    ),
  ];

  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 16,
      spreadRadius: 0,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> subtleShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 8,
      spreadRadius: 0,
      offset: const Offset(0, 2),
    ),
  ];

  // ── Border Radius ─────────────────────────────────────────────
  static const double radiusSm   = 8.0;
  static const double radiusMd   = 12.0;
  static const double radiusLg   = 16.0;
  static const double radiusXl   = 20.0;
  static const double radiusXxl  = 28.0;

  // ── Typography ────────────────────────────────────────────────
  static final TextStyle heading1 = GoogleFonts.inter(
    fontSize: 28, fontWeight: FontWeight.w800,
    color: textPrimary, letterSpacing: -0.5,
  );
  static final TextStyle heading2 = GoogleFonts.inter(
    fontSize: 22, fontWeight: FontWeight.w700,
    color: textPrimary, letterSpacing: -0.3,
  );
  static final TextStyle heading3 = GoogleFonts.inter(
    fontSize: 18, fontWeight: FontWeight.w600,
    color: textPrimary, letterSpacing: -0.2,
  );
  static final TextStyle heading4 = GoogleFonts.inter(
    fontSize: 15, fontWeight: FontWeight.w600,
    color: textPrimary,
  );
  static final TextStyle body = GoogleFonts.inter(
    fontSize: 14, fontWeight: FontWeight.w500, color: textSecond,
  );
  static final TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 12, fontWeight: FontWeight.w400, color: textSecond,
  );
  static final TextStyle label = GoogleFonts.inter(
    fontSize: 11, fontWeight: FontWeight.w600,
    color: textMuted, letterSpacing: 0.8,
  );
  static const TextStyle mono = TextStyle(
    fontFamily: 'monospace',
    fontSize: 18, fontWeight: FontWeight.w700,
    color: textPrimary, letterSpacing: 2.0,
  );
  static const TextStyle monoLarge = TextStyle(
    fontFamily: 'monospace',
    fontSize: 26, fontWeight: FontWeight.w700,
    color: primary, letterSpacing: 3.0,
  );

  // ── Dark Palette ──────────────────────────────────────────────
  static const Color darkBgDeep    = Color(0xFF17120F);
  static const Color darkBgCard    = Color(0xFF241C17);
  static const Color darkBorder    = Color(0xFF3A2F28);
  static const Color darkTextPrimary = Color(0xFFF5F1ED);
  static const Color darkTextSecond  = Color(0xFFC9BFB6);
  static const Color darkTextMuted   = Color(0xFF9C8F84);

  // ── Theme Data ────────────────────────────────────────────────
  static ThemeData get theme => lightTheme;

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: bgDeep,
    colorScheme: const ColorScheme.light(
      primary: primary,
      secondary: accent,
      surface: bgCard,
      error: danger,
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: bgCard,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      titleTextStyle: GoogleFonts.inter(
        fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary,
      ),
      iconTheme: const IconThemeData(color: textPrimary),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: bgSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: danger, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: GoogleFonts.inter(color: textHint),
      labelStyle: GoogleFonts.inter(color: textSecond),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    cardTheme: CardThemeData(
      color: bgCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLg),
        side: const BorderSide(color: border, width: 0.5),
      ),
      margin: const EdgeInsets.only(bottom: 16),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: bgCard,
      selectedItemColor: primary,
      unselectedItemColor: textMuted,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    ),
    dividerTheme: const DividerThemeData(color: border, thickness: 0.5),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: textPrimary,
      contentTextStyle: GoogleFonts.inter(color: Colors.white, fontSize: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
      behavior: SnackBarBehavior.floating,
    ),
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBgDeep,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: accent,
      surface: darkBgCard,
      error: danger,
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: darkBgCard,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      titleTextStyle: GoogleFonts.inter(
        fontSize: 18, fontWeight: FontWeight.w600, color: darkTextPrimary,
      ),
      iconTheme: const IconThemeData(color: darkTextPrimary),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkBgCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: darkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: danger, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: GoogleFonts.inter(color: darkTextMuted),
      labelStyle: GoogleFonts.inter(color: darkTextSecond),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    cardTheme: CardThemeData(
      color: darkBgCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLg),
        side: const BorderSide(color: darkBorder, width: 0.5),
      ),
      margin: const EdgeInsets.only(bottom: 16),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: darkBgCard,
      selectedItemColor: primary,
      unselectedItemColor: darkTextMuted,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    ),
    dividerTheme: const DividerThemeData(color: darkBorder, thickness: 0.5),
    dialogTheme: DialogThemeData(
      backgroundColor: darkBgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusXxl)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: darkTextPrimary,
      contentTextStyle: GoogleFonts.inter(color: darkBgDeep, fontSize: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
      behavior: SnackBarBehavior.floating,
    ),
  );

  // ── System UI Overlay ─────────────────────────────────────────
  static void setSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }
}
