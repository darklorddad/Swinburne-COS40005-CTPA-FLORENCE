import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminTheme {
  // Brand Colors
  static const Color surface = Color(0xFFFAF9F6);
  static const Color surfaceContainer = Color(0xFFEEEEEB);
  static const Color primary = Color(0xFF3B5A36); // Original: 0xFF456551
  static const Color primaryContainer = Color(0xFF9CBFA7);
  static const Color onPrimaryContainer = Color(0xFF2F4E3C);
  static const Color secondary = Color(0xFF446650);
  
  // Semantic Colors
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);
  
  // Text Colors
  static const Color onSurface = Color(0xFF1A1C1A);
  static const Color onSurfaceVariant = Color(0xFF424843);
  static const Color outline = Color(0xFF727973);
  static const Color outlineVariant = Color(0xFFC2C8C1);

  static const Color surfaceContainerHighest = Color(0xFFE3E3DF);
  static const Color primaryFixed = Color(0xFFC7EBD2);
  static const Color onPrimaryFixed = Color(0xFF012111);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: surface,
      colorScheme: const ColorScheme.light(
        primary: primary,
        primaryContainer: primaryContainer,
        secondary: secondary,
        surface: surface,
        error: error,
        errorContainer: errorContainer,
        onSurface: onSurface,
        onSurfaceVariant: onSurfaceVariant,
        outline: outline,
        outlineVariant: outlineVariant,
      ),
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displaySmall: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w600, letterSpacing: -0.64, color: onSurface), // h1
        headlineMedium: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: -0.24, color: onSurface), // h2
        titleLarge: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w500, color: onSurface), // h3
        bodyLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, height: 1.6, color: onSurfaceVariant), // body-lg
        bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5, color: onSurfaceVariant), // body-sm
        labelSmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: outline), // label-caps
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: outlineVariant, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryContainer,
          foregroundColor: onPrimaryContainer,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primaryContainer, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}