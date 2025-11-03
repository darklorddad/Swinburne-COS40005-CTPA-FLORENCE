// Application-wide constants

class AppConstants {
  // Glucose Thresholds (mg/dL)
  static const double defaultGlucoseMin = 70.0;
  static const double defaultGlucoseMax = 180.0;
  static const double hypoglycemiaThreshold = 70.0;
  static const double hyperglycemiaThreshold = 180.0;
  static const double criticalLowThreshold = 54.0;
  static const double criticalHighThreshold = 250.0;
  
  // Activity Goals
  static const int defaultDailyActivityGoal = 60; // minutes
  static const int defaultWeeklyActivityGoal = 420; // 7 hours
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // Cache Durations
  static const Duration shortCacheDuration = Duration(minutes: 5);
  static const Duration mediumCacheDuration = Duration(minutes: 15);
  static const Duration longCacheDuration = Duration(hours: 1);
  
  // API Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration longApiTimeout = Duration(minutes: 2);
  
  // Gamification
  static const int pointsPerGlucoseLog = 10;
  static const int pointsPerMealLog = 5;
  static const int pointsPerActivityLog = 15;
  static const int pointsPerMedicationLog = 5;
  
  // File Upload
  static const int maxImageSizeMB = 10;
  static const int maxImageSizeBytes = 10 * 1024 * 1024;
  static const List<String> allowedImageTypes = [
    'image/jpeg',
    'image/png',
    'image/webp'
  ];
  
  // Chart Settings
  static const int maxChartDataPoints = 100;
  static const int defaultChartAnimationDuration = 300; // milliseconds
  
  // Validation
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  
  // Responsive Breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1440;
}