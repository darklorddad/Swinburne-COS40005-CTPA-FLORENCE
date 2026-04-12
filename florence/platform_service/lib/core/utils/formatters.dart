import 'package:intl/intl.dart';

/// Data formatting utilities
/// Provides consistent formatting across the app

class Formatters {
  // ============================================
  // DATE & TIME FORMATTERS
  // ============================================
  
  /// Format: Jan 15, 2025
  static String date(DateTime dateTime) {
    return DateFormat('MMM d, y').format(dateTime);
  }
  
  /// Format: January 15, 2025
  static String dateLong(DateTime dateTime) {
    return DateFormat('MMMM d, y').format(dateTime);
  }
  
  /// Format: 15/01/2025
  static String dateShort(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy').format(dateTime);
  }
  
  /// Format: 2:30 PM
  static String time(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime);
  }
  
  /// Format: 14:30
  static String time24(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }
  
  /// Format: Jan 15, 2025 at 2:30 PM
  static String dateTime(DateTime dateTime) {
    return DateFormat('MMM d, y \'at\' h:mm a').format(dateTime);
  }
  
  /// Format: Today, Yesterday, or date
  static String relativeDate(DateTime dateTime) {
    // Ensure we work with local time for day comparison
    final localDateTime = dateTime.toLocal();
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    // Use components from the local time
    final dateOnly = DateTime(localDateTime.year, localDateTime.month, localDateTime.day);
    
    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else if (dateOnly.isAfter(today.subtract(const Duration(days: 7)))) {
      return DateFormat('EEEE').format(localDateTime); // Monday, Tuesday, etc.
    } else {
      return date(localDateTime);
    }
  }
  
  /// Format: 2 hours ago, 5 minutes ago, Just now
  static String timeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }
  
  // ============================================
  // NUMBER FORMATTERS
  // ============================================
  
  /// Format: 123.45
  static String decimal(double value, {int decimals = 2}) {
    return value.toStringAsFixed(decimals);
  }
  
  /// Format: 123.5 (removes trailing zeros)
  static String decimalCompact(double value, {int decimals = 2}) {
    final formatted = value.toStringAsFixed(decimals);
    return formatted.replaceAll(RegExp(r'\.?0+$'), '');
  }
  
  /// Format: 1,234.56
  static String number(num value, {int decimals = 0}) {
    final formatter = NumberFormat('#,##0${decimals > 0 ? '.${'0' * decimals}' : ''}');
    return formatter.format(value);
  }
  
  /// Format: 1.2K, 1.5M
  static String numberCompact(num value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toString();
  }
  
  // ============================================
  // HEALTH DATA FORMATTERS
  // ============================================
  
  /// Format glucose: 120 mg/dL
  static String glucose(double value, {bool includeUnit = true}) {
    final formatted = decimalCompact(value, decimals: 1);
    return includeUnit ? '$formatted mg/dL' : formatted;
  }
  
  /// Format HbA1c: 6.5%
  static String hba1c(double value, {bool includeUnit = true}) {
    final formatted = decimalCompact(value, decimals: 1);
    return includeUnit ? '$formatted%' : formatted;
  }
  
  /// Format weight: 70.5 kg
  static String weight(double value, {bool includeUnit = true}) {
    final formatted = decimalCompact(value, decimals: 1);
    return includeUnit ? '$formatted kg' : formatted;
  }
  
  /// Format BMI: 22.5
  static String bmi(double value) {
    return decimalCompact(value, decimals: 1);
  }
  
  /// Format blood pressure: 120/80 mmHg
  static String bloodPressure(int systolic, int diastolic, {bool includeUnit = true}) {
    return includeUnit ? '$systolic/$diastolic mmHg' : '$systolic/$diastolic';
  }
  
  /// Format heart rate: 72 bpm
  static String heartRate(int value, {bool includeUnit = true}) {
    return includeUnit ? '$value bpm' : value.toString();
  }
  
  // ============================================
  // ACTIVITY FORMATTERS
  // ============================================
  
  /// Format duration: 45 min or 1h 30min
  static String duration(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    } else {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      if (mins == 0) {
        return '$hours${hours == 1 ? 'h' : 'h'}';
      }
      return '${hours}h ${mins}min';
    }
  }
  
  /// Format duration in seconds: 45s or 2m 30s or 1h 15m
  static String durationFromSeconds(int seconds) {
    if (seconds < 60) {
      return '${seconds}s';
    } else if (seconds < 3600) {
      final minutes = seconds ~/ 60;
      final secs = seconds % 60;
      return secs == 0 ? '${minutes}m' : '${minutes}m ${secs}s';
    } else {
      final hours = seconds ~/ 3600;
      final minutes = (seconds % 3600) ~/ 60;
      return minutes == 0 ? '${hours}h' : '${hours}h ${minutes}m';
    }
  }
  
  /// Format calories: 250 kcal
  static String calories(int value, {bool includeUnit = true}) {
    return includeUnit ? '$value kcal' : value.toString();
  }
  
  /// Format distance: 5.2 km
  static String distance(double kilometers, {bool includeUnit = true}) {
    final formatted = decimalCompact(kilometers, decimals: 1);
    return includeUnit ? '$formatted km' : formatted;
  }
  
  // ============================================
  // PERCENTAGE FORMATTERS
  // ============================================
  
  /// Format percentage: 75%
  static String percentage(double value, {int decimals = 0}) {
    return '${value.toStringAsFixed(decimals)}%';
  }
  
  /// Format percentage from ratio: 0.75 -> 75%
  static String percentageFromRatio(double ratio, {int decimals = 0}) {
    return percentage(ratio * 100, decimals: decimals);
  }
  
  // ============================================
  // PHONE FORMATTERS
  // ============================================
  
  /// Format phone: +60 12-345 6789
  static String phone(String phone) {
    // Remove all non-digit characters
    final digitsOnly = phone.replaceAll(RegExp(r'\D'), '');
    
    // Malaysian format
    if (digitsOnly.startsWith('60')) {
      // +60 12-345 6789
      if (digitsOnly.length >= 11) {
        return '+${digitsOnly.substring(0, 2)} ${digitsOnly.substring(2, 4)}-${digitsOnly.substring(4, 7)} ${digitsOnly.substring(7)}';
      }
    } else if (digitsOnly.startsWith('0')) {
      // 012-345 6789
      if (digitsOnly.length >= 10) {
        return '${digitsOnly.substring(0, 3)}-${digitsOnly.substring(3, 6)} ${digitsOnly.substring(6)}';
      }
    }
    
    return phone; // Return original if doesn't match pattern
  }
  
  // ============================================
  // CURRENCY FORMATTERS
  // ============================================
  
  /// Format currency: RM 123.45
  static String currency(double amount, {String symbol = 'RM', int decimals = 2}) {
    final formatter = NumberFormat('#,##0.${('0' * decimals)}');
    return '$symbol ${formatter.format(amount)}';
  }
  
  // ============================================
  // TEXT FORMATTERS
  // ============================================
  
  /// Capitalize first letter
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
  
  /// Title case: "hello world" -> "Hello World"
  static String titleCase(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) => capitalize(word)).join(' ');
  }
  
  /// Truncate text with ellipsis
  static String truncate(String text, int maxLength, {String suffix = '...'}) {
    if (text.length <= maxLength) return text;
    return text.substring(0, maxLength - suffix.length) + suffix;
  }
  
  // ============================================
  // ORDINAL NUMBERS
  // ============================================
  
  /// Get ordinal: 1st, 2nd, 3rd, 4th
  static String ordinal(int number) {
    if (number % 100 >= 11 && number % 100 <= 13) {
      return '${number}th';
    }
    
    switch (number % 10) {
      case 1:
        return '${number}st';
      case 2:
        return '${number}nd';
      case 3:
        return '${number}rd';
      default:
        return '${number}th';
    }
  }
}
