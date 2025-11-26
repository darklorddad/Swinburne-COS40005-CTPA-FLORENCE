import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Patient dashboard color palette
  static const Color primaryColor = Color(0xFF2F70F8); // Primary blue from patient dashboard
  static const Color secondaryColor = Color(0xFF1A73E8); // Secondary blue
  static const Color accentColor = Color(0xFFF59E0B); // Amber/Orange
  
  static const Color highRiskColor = Color(0xFFF44336); // Red
  static const Color mediumRiskColor = Color(0xFFFFC107); // Yellow/Amber
  static const Color lowRiskColor = Color(0xFF4CAF50); // Green
  static const Color automatedActionColor = Color(0xFF9C27B0); // Purple for automated actions
  
  static const Color textPrimary = Color(0xFF212121); // Dark gray/black
  static const Color textSecondary = Color(0xFF70757A); // Medium gray
  static const Color textTertiary = Color(0xFF999999); // Light gray
  static const Color dividerColor = Color(0xFFE0E0E0); // Light gray divider
  
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    primaryColor: primaryColor,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      secondary: secondaryColor,
      surface: Colors.white,
      surfaceTint: Colors.transparent,
    ),
    scaffoldBackgroundColor: const Color(0xFFF5F5F5), // Light gray background like patient dashboard
    textTheme: GoogleFonts.interTextTheme().copyWith(
      bodyMedium: GoogleFonts.inter(
        color: textSecondary,
        fontSize: 14,
        height: 1.4,
      ),
      bodyLarge: GoogleFonts.inter(
        color: textPrimary,
        fontSize: 16,
        height: 1.5,
      ),
      titleMedium: GoogleFonts.inter(
        color: textPrimary,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: GoogleFonts.inter(
        color: textPrimary,
        fontWeight: FontWeight.w700,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: textPrimary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 18,
        color: textPrimary,
      ),
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      elevation: 0, // Minimal elevation as per screenshots
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20), // More rounded corners
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: dividerColor, width: 1),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    iconTheme: const IconThemeData(color: textSecondary),
    inputDecorationTheme: InputDecorationTheme(
      fillColor: Colors.white,
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: dividerColor, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: dividerColor, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: const TextStyle(color: textSecondary, fontSize: 14),
    ),
    dataTableTheme: DataTableThemeData(
      headingRowColor: const WidgetStatePropertyAll(Color(0xFFEFF6FF)),
      dividerThickness: 1,
      headingTextStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFFF5F5F5), // Light gray background
      labelStyle: GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        fontSize: 12,
        color: textPrimary,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8), // Pill shape
        side: BorderSide.none,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: const CircleBorder(),
    ),
    dividerTheme: const DividerThemeData(color: dividerColor, thickness: 1),
    tabBarTheme: TabBarThemeData(
      labelColor: primaryColor,
      unselectedLabelColor: textSecondary,
      labelStyle: GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
      unselectedLabelStyle: GoogleFonts.inter(
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
      indicator: const UnderlineTabIndicator(
        borderSide: BorderSide(color: primaryColor, width: 3),
      ),
      indicatorSize: TabBarIndicatorSize.tab,
    ),
  );

  static Color getRiskColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'high':
        return highRiskColor;
      case 'medium':
        return mediumRiskColor;
      case 'low':
        return lowRiskColor;
      default:
        return Colors.grey;
    }
  }
}


