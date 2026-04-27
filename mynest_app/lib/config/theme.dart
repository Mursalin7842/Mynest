import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ─────────────────────────────────────────────
/// MyNest V1.2.0 — Premium Museum Theme
/// Fixed for Android color rendering
/// ─────────────────────────────────────────────

class NestTheme {
  // ── Brand Colors ──
  static const Color cream = Color(0xFFFAF6F0);
  static const Color warmWhite = Color(0xFFFFF8F0);
  static const Color parchment = Color(0xFFF5EDE3);
  static const Color amber = Color(0xFFD4A574);
  static const Color deepAmber = Color(0xFFC48B4F);
  static const Color warmBrown = Color(0xFF8B6914);
  static const Color darkBrown = Color(0xFF3E2723);
  static const Color charcoal = Color(0xFF2C2C2C);
  static const Color softGold = Color(0xFFE8D5B7);
  static const Color sage = Color(0xFF7A8B6F);
  static const Color dustyRose = Color(0xFFB88B8B);
  static const Color mist = Color(0xFFD4D0CC);
  static const Color deepTeal = Color(0xFF2C4A4A);

  // ── Gradients ──
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3E2723), Color(0xFF5D4037), Color(0xFF4E342E)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFF8F0), Color(0xFFF5EDE3)],
  );

  static const LinearGradient amberGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD4A574), Color(0xFFC48B4F)],
  );

  // ── Shadows ──
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: const Color(0x0F000000),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: const Color(0x14000000),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  // ── Border Radius ──
  static BorderRadius cardRadius = BorderRadius.circular(20);
  static BorderRadius buttonRadius = BorderRadius.circular(16);
  static BorderRadius inputRadius = BorderRadius.circular(14);
  static BorderRadius chipRadius = BorderRadius.circular(24);

  // ── Theme Data — FIXED for Android ──
  static ThemeData get lightTheme {
    // Build explicit color scheme to prevent dynamic color injection on Android
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: deepAmber,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFFFE0B2),
      onPrimaryContainer: darkBrown,
      secondary: amber,
      onSecondary: charcoal,
      secondaryContainer: parchment,
      onSecondaryContainer: charcoal,
      tertiary: sage,
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFFDCE8D4),
      onTertiaryContainer: charcoal,
      error: Color(0xFFBA1A1A),
      onError: Colors.white,
      errorContainer: Color(0xFFFFDAD6),
      onErrorContainer: Color(0xFF410002),
      surface: warmWhite,
      onSurface: charcoal,
      surfaceContainerHighest: parchment,
      outline: mist,
      outlineVariant: Color(0xFFE8E4E0),
      shadow: Color(0x29000000),
      scrim: Colors.black,
      inverseSurface: charcoal,
      onInverseSurface: cream,
      inversePrimary: softGold,
      surfaceTint: Colors.transparent, // ← KEY: Prevents Material3 tinting
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: cream,
      canvasColor: cream,
      cardColor: Colors.white,
      // Disable Material3 surface tint that causes dark overlay
      applyElevationOverlayColor: false,
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.playfairDisplay(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          color: darkBrown,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.playfairDisplay(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: darkBrown,
          letterSpacing: -0.3,
        ),
        headlineLarge: GoogleFonts.playfairDisplay(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: darkBrown,
        ),
        headlineMedium: GoogleFonts.playfairDisplay(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: darkBrown,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: charcoal,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: charcoal,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: charcoal,
          height: 1.6,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Color(0xCC2C2C2C),
          height: 1.5,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: Color(0x992C2C2C),
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: cream,
        foregroundColor: darkBrown,
        elevation: 0,
        surfaceTintColor: Colors.transparent, // ← Prevents dark tint on scroll
        centerTitle: true,
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: darkBrown,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: deepAmber,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: buttonRadius),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: deepAmber,
          side: const BorderSide(color: amber, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: buttonRadius),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: inputRadius,
          borderSide: BorderSide(color: mist.withAlpha(128)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: inputRadius,
          borderSide: BorderSide(color: mist.withAlpha(128)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: inputRadius,
          borderSide: const BorderSide(color: deepAmber, width: 2),
        ),
        hintStyle: GoogleFonts.inter(
          color: const Color(0x592C2C2C),
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.inter(
          color: const Color(0x992C2C2C),
          fontSize: 14,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        surfaceTintColor: Colors.transparent, // ← Prevents dark tint
        shape: RoundedRectangleBorder(borderRadius: cardRadius),
        color: Colors.white,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: const Color(0x1AC48B4F),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: deepAmber,
        unselectedItemColor: const Color(0x662C2C2C),
        type: BottomNavigationBarType.fixed,
        elevation: 20,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 11),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: deepAmber,
        foregroundColor: Colors.white,
        elevation: 8,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: DividerThemeData(color: mist.withAlpha(102)),
      popupMenuTheme: const PopupMenuThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}
