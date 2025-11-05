import 'package:flutter/material.dart';

/// Admin Theme Configuration
/// Professional styling for admin dashboard
/// Optimized for desktop-first, data-dense interfaces
class AdminTheme {
  // ============================================
  // PRIMARY COLORS - Professional & Authoritative
  // ============================================

  static const Color primaryIndigo = Color(0xFF3F51B5); // Deep Blue/Indigo
  static const Color primaryDark = Color(0xFF303F9F);
  static const Color primaryLight = Color(0xFF7986CB);
  static const Color accentTeal = Color(0xFF009688);

  // ============================================
  // BACKGROUND COLORS
  // ============================================

  static const Color backgroundColor = Color(0xFFF5F7FA); // Light gray-blue
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color sidebarColor = Color(0xFF1E293B); // Dark sidebar
  static const Color sidebarHoverColor = Color(0xFF334155);

  // ============================================
  // TEXT COLORS
  // ============================================

  static const Color textPrimaryColor = Color(0xFF1F2937);
  static const Color textSecondaryColor = Color(0xFF6B7280);
  static const Color textLightColor = Color(0xFF9CA3AF);
  static const Color textOnDark = Color(0xFFFFFFFF);

  // ============================================
  // STATUS COLORS
  // ============================================

  static const Color successColor = Color(0xFF10B981); // Green
  static const Color warningColor = Color(0xFFF59E0B); // Amber
  static const Color errorColor = Color(0xFFEF4444); // Red
  static const Color infoColor = Color(0xFF3B82F6); // Blue

  // ============================================
  // ROLE COLORS - Visual identification
  // ============================================

  static const Color superAdminColor = Color(0xFF8B5CF6); // Purple
  static const Color hospitalAdminColor = Color(0xFF3F51B5); // Indigo
  static const Color doctorColor = Color(0xFF059669); // Green

  // ============================================
  // ORGANIZATION STATUS COLORS
  // ============================================

  static const Color orgActiveColor = Color(0xFF10B981);
  static const Color orgInactiveColor = Color(0xFF6B7280);
  static const Color orgSuspendedColor = Color(0xFFEF4444);

  // ============================================
  // DATA TABLE COLORS
  // ============================================

  static const Color tableHeaderColor = Color(0xFFF9FAFB);
  static const Color tableRowHoverColor = Color(0xFFF3F4F6);
  static const Color tableBorderColor = Color(0xFFE5E7EB);
  static const Color tableSelectedColor = Color(0xFFEEF2FF);

  // ============================================
  // CHART COLORS (for admin analytics)
  // ============================================

  static const Color chartBlue = Color(0xFF3B82F6);
  static const Color chartGreen = Color(0xFF10B981);
  static const Color chartYellow = Color(0xFFF59E0B);
  static const Color chartRed = Color(0xFFEF4444);
  static const Color chartPurple = Color(0xFF8B5CF6);
  static const Color chartOrange = Color(0xFFF97316);

  // ============================================
  // BORDER & DIVIDER COLORS
  // ============================================

  static const Color borderColor = Color(0xFFE5E7EB);
  static const Color dividerColor = Color(0xFFE5E7EB);

  // ============================================
  // LIGHT THEME (Primary Theme)
  // ============================================

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,

    // Color Scheme
    colorScheme: const ColorScheme.light(
      primary: primaryIndigo,
      secondary: accentTeal,
      tertiary: primaryLight,
      error: errorColor,
      surface: surfaceColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onError: Colors.white,
      onSurface: textPrimaryColor,
    ),

    // Scaffold
    scaffoldBackgroundColor: backgroundColor,

    // AppBar Theme
    appBarTheme: const AppBarTheme(
      backgroundColor: surfaceColor,
      foregroundColor: textPrimaryColor,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: textPrimaryColor,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ),
      iconTheme: IconThemeData(color: textPrimaryColor),
    ),

    // Card Theme - More subtle for data tables
    cardTheme: CardThemeData(
      color: surfaceColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: borderColor, width: 1),
      ),
      margin: const EdgeInsets.all(0),
    ),

    // Button Themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryIndigo,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryIndigo,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: const BorderSide(color: primaryIndigo, width: 1.5),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryIndigo,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    ),

    // Input Field Theme - Cleaner for forms
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryIndigo, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: errorColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: errorColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: const TextStyle(color: textSecondaryColor, fontSize: 14),
      hintStyle: const TextStyle(color: textLightColor, fontSize: 14),
    ),

    // Data Table Theme
    dataTableTheme: DataTableThemeData(
      headingRowColor: WidgetStateProperty.all(tableHeaderColor),
      dataRowColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return tableSelectedColor;
        }
        if (states.contains(WidgetState.hovered)) {
          return tableRowHoverColor;
        }
        return null;
      }),
      headingTextStyle: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: textPrimaryColor,
        letterSpacing: 0.5,
      ),
      dataTextStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textPrimaryColor,
      ),
      dividerThickness: 1,
      decoration: BoxDecoration(
        border: Border.all(color: tableBorderColor),
        borderRadius: BorderRadius.circular(8),
      ),
    ),

    // Divider Theme
    dividerTheme: const DividerThemeData(
      color: dividerColor,
      thickness: 1,
      space: 1,
    ),

    // Chip Theme - For tags, filters, status badges
    chipTheme: ChipThemeData(
      backgroundColor: backgroundColor,
      deleteIconColor: textSecondaryColor,
      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: const BorderSide(color: borderColor),
      ),
    ),

    // Typography - Optimized for data density
    textTheme: const TextTheme(
      // Display styles - Large headings
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: textPrimaryColor,
        letterSpacing: -1,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: textPrimaryColor,
        letterSpacing: -0.5,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textPrimaryColor,
        letterSpacing: -0.5,
      ),

      // Headline styles - Section headers
      headlineLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: textPrimaryColor,
        letterSpacing: -0.5,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimaryColor,
        letterSpacing: -0.5,
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimaryColor,
      ),

      // Title styles - Card titles, subsections
      titleLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textPrimaryColor,
        letterSpacing: 0.15,
      ),
      titleMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: textPrimaryColor,
        letterSpacing: 0.15,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textPrimaryColor,
        letterSpacing: 0.1,
      ),

      // Body styles - Main content
      bodyLarge: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: textPrimaryColor,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textPrimaryColor,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: textSecondaryColor,
        height: 1.4,
      ),

      // Label styles - Buttons, form labels
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textPrimaryColor,
        letterSpacing: 0.5,
      ),
      labelMedium: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: textPrimaryColor,
        letterSpacing: 0.5,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: textSecondaryColor,
        letterSpacing: 0.5,
      ),
    ),
  );

  // ============================================
  // DARK THEME (Optional - for future)
  // ============================================

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: primaryLight,
      secondary: accentTeal,
      // background: Color(0xFF0F172A),
      surface: Color(0xFF1E293B),
    ),
    scaffoldBackgroundColor: const Color(0xFF0F172A),
  );

  // ============================================
  // HELPER METHODS
  // ============================================

  /// Get color based on admin role
  static Color getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'super admin':
      case 'superadmin':
        return superAdminColor;
      case 'hospital admin':
      case 'hospitaladmin':
        return hospitalAdminColor;
      case 'doctor':
      case 'physician':
        return doctorColor;
      default:
        return textSecondaryColor;
    }
  }

  /// Get color based on organization status
  static Color getOrgStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return orgActiveColor;
      case 'inactive':
        return orgInactiveColor;
      case 'suspended':
        return orgSuspendedColor;
      default:
        return textSecondaryColor;
    }
  }

  /// Get color based on generic status
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'success':
      case 'active':
      case 'completed':
      case 'approved':
        return successColor;
      case 'warning':
      case 'pending':
      case 'in progress':
        return warningColor;
      case 'error':
      case 'failed':
      case 'rejected':
      case 'critical':
        return errorColor;
      case 'info':
      case 'scheduled':
        return infoColor;
      default:
        return textSecondaryColor;
    }
  }

  /// Get chart color by index (for multi-series charts)
  static Color getChartColor(int index) {
    final colors = [
      chartBlue,
      chartGreen,
      chartYellow,
      chartRed,
      chartPurple,
      chartOrange,
    ];
    return colors[index % colors.length];
  }

  /// Get role badge widget
  static Widget getRoleBadge(String role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: getRoleColor(role).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: getRoleColor(role).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: getRoleColor(role),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  /// Get status badge widget
  static Widget getStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: getStatusColor(status).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: getStatusColor(status).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: getStatusColor(status),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
