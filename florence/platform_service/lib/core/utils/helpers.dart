import 'package:flutter/material.dart';

/// Helper functions and utilities
/// Provides common helper methods used across the app

class Helpers {
  // ============================================
  // SNACKBAR HELPERS
  // ============================================
  
  /// Show success snackbar
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
  
  /// Show error snackbar
  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }
  
  /// Show info snackbar
  static void showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
  
  /// Show warning snackbar
  static void showWarning(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
  
  // ============================================
  // DIALOG HELPERS
  // ============================================
  
  /// Show confirmation dialog
  static Future<bool> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDangerous = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: isDangerous ? Colors.red : null,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }
  
  /// Show loading dialog
  static void showLoadingDialog(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(message),
            ],
          ],
        ),
      ),
    );
  }
  
  /// Hide loading dialog
  static void hideLoadingDialog(BuildContext context) {
    Navigator.pop(context);
  }
  
  // ============================================
  // BOTTOM SHEET HELPERS
  // ============================================
  
  /// Show bottom sheet
  static Future<T?> showBottomSheet<T>(
    BuildContext context, {
    required Widget child,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => child,
    );
  }
  
  // ============================================
  // KEYBOARD HELPERS
  // ============================================
  
  /// Hide keyboard
  static void hideKeyboard(BuildContext context) {
    FocusScope.of(context).unfocus();
  }
  
  // ============================================
  // RESPONSIVE HELPERS
  // ============================================
  
  /// Check if device is mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }
  
  /// Check if device is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 600 && width < 1024;
  }
  
  /// Check if device is desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1024;
  }
  
  /// Get responsive value based on screen size
  static T responsive<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context) && desktop != null) return desktop;
    if (isTablet(context) && tablet != null) return tablet;
    return mobile;
  }
  
  // ============================================
  // COLOR HELPERS
  // ============================================
  
  /// Get contrasting text color (black or white) based on background
  static Color getContrastingTextColor(Color backgroundColor) {
    // Calculate relative luminance
    final luminance = backgroundColor.computeLuminance();
    // Return white for dark backgrounds, black for light backgrounds
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
  
  /// Lighten a color
  static Color lighten(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }
  
  /// Darken a color
  static Color darken(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }
  
  // ============================================
  // DATE HELPERS
  // ============================================
  
  /// Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
  
  /// Check if date is yesterday
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }
  
  /// Get start of day
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
  
  /// Get end of day
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }
  
  /// Get start of week (Monday)
  static DateTime startOfWeek(DateTime date) {
    final weekday = date.weekday;
    return startOfDay(date.subtract(Duration(days: weekday - 1)));
  }
  
  /// Get end of week (Sunday)
  static DateTime endOfWeek(DateTime date) {
    final weekday = date.weekday;
    return endOfDay(date.add(Duration(days: 7 - weekday)));
  }
  
  /// Get start of month
  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }
  
  /// Get end of month
  static DateTime endOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0, 23, 59, 59, 999);
  }
  
  /// Get days in month
  static int daysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }
  
  // ============================================
  // LIST HELPERS
  // ============================================
  
  /// Group list by a key function
  static Map<K, List<T>> groupBy<T, K>(
    Iterable<T> list,
    K Function(T) keyFunction,
  ) {
    final map = <K, List<T>>{};
    for (final item in list) {
      final key = keyFunction(item);
      map.putIfAbsent(key, () => []).add(item);
    }
    return map;
  }
  
  /// Get unique items from list
  static List<T> unique<T>(List<T> list) {
    return list.toSet().toList();
  }
  
  // ============================================
  // HEALTH CALCULATION HELPERS
  // ============================================
  
  /// Calculate BMI
  static double calculateBMI(double weightKg, double heightCm) {
    final heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }
  
  /// Get BMI category
  static String getBMICategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }
  
  /// Calculate glucose average
  static double calculateGlucoseAverage(List<double> readings) {
    if (readings.isEmpty) return 0;
    return readings.reduce((a, b) => a + b) / readings.length;
  }
  
  /// Calculate glucose standard deviation
  static double calculateGlucoseStdDev(List<double> readings) {
    if (readings.isEmpty) return 0;
    final mean = calculateGlucoseAverage(readings);
    final variance = readings
        .map((x) => (x - mean) * (x - mean))
        .reduce((a, b) => a + b) / readings.length;
    return variance.sqrt();
  }
  
  /// Calculate time in range percentage
  static double calculateTimeInRange(
    List<double> readings,
    double minValue,
    double maxValue,
  ) {
    if (readings.isEmpty) return 0;
    final inRange = readings.where((r) => r >= minValue && r <= maxValue).length;
    return (inRange / readings.length) * 100;
  }
  
  // ============================================
  // STRING HELPERS
  // ============================================
  
  /// Check if string is null or empty
  static bool isNullOrEmpty(String? value) {
    return value == null || value.isEmpty;
  }
  
  /// Get initials from name
  static String getInitials(String name, {int maxLength = 2}) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    
    if (parts.length == 1) {
      return parts[0].substring(0, maxLength).toUpperCase();
    }
    
    return parts
        .take(maxLength)
        .map((part) => part.isNotEmpty ? part[0].toUpperCase() : '')
        .join();
  }
  
  // ============================================
  // URL HELPERS
  // ============================================
  
  /// Check if string is valid URL
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }
}

// Extension on double for convenience
extension DoubleExtension on double {
  double sqrt() {
    if (this < 0) return 0;
    // Newton's method for square root
    double x = this;
    double y = 1.0;
    final e = 0.000001;
    
    while ((x - y).abs() > e) {
      x = (x + y) / 2;
      y = this / x;
    }
    
    return x;
  }
}