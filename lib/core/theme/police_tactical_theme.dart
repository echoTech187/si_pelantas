import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PoliceTacticalColors {
  // Deep Command Backgrounds
  static const Color backgroundBlack = Color(0xFF060B14);
  static const Color commandNavy = Color(0xFF0A1326);
  static const Color tacticalSurface = Color(0xFF101C38);
  static const Color tacticalCard = Color(0xFF16254A);
  static const Color tacticalGlass = Color(0x331E356D);

  // High-Tech Accents
  static const Color korlantasBlue = Color(0xFF0052CC);
  static const Color electricCyan = Color(0xFF00F0FF);
  static const Color neonBlue = Color(0xFF2E86DE);
  static const Color polriGold = Color(0xFFFFD166);
  static const Color warningAmber = Color(0xFFFF9F1C);
  static const Color crimsonAlert = Color(0xFFFF3366);
  static const Color safeEmerald = Color(0xFF05FFA1);

  // Neutral Texts
  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
  static const Color borderGlow = Color(0x5500F0FF);
}

class PoliceTacticalTheme {
  static ThemeData get darkCommandTheme {
    final baseText =
        GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: PoliceTacticalColors.backgroundBlack,
      colorScheme: const ColorScheme.dark(
        primary: PoliceTacticalColors.electricCyan,
        secondary: PoliceTacticalColors.polriGold,
        surface: PoliceTacticalColors.tacticalSurface,
        error: PoliceTacticalColors.crimsonAlert,
      ),
      textTheme: baseText.copyWith(
        headlineLarge: GoogleFonts.rajdhani(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
          color: PoliceTacticalColors.textPrimary,
        ),
        titleLarge: GoogleFonts.rajdhani(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
          color: PoliceTacticalColors.textPrimary,
        ),
        titleMedium: GoogleFonts.rajdhani(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: PoliceTacticalColors.electricCyan,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: PoliceTacticalColors.commandNavy,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.rajdhani(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: PoliceTacticalColors.electricCyan,
        ),
      ),
      cardTheme: CardThemeData(
        color: PoliceTacticalColors.tacticalCard,
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
              color: PoliceTacticalColors.electricCyan.withValues(alpha: 0.2),
              width: 1.2),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: PoliceTacticalColors.tacticalSurface,
        labelStyle: const TextStyle(
            color: PoliceTacticalColors.textSecondary, fontSize: 13),
        hintStyle: const TextStyle(
            color: PoliceTacticalColors.textMuted, fontSize: 13),
        prefixIconColor: PoliceTacticalColors.electricCyan,
        suffixIconColor: PoliceTacticalColors.textSecondary,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: PoliceTacticalColors.electricCyan.withValues(alpha: 0.25)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
              color: PoliceTacticalColors.electricCyan, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
              color: PoliceTacticalColors.crimsonAlert, width: 1.5),
        ),
      ),
    );
  }
}
