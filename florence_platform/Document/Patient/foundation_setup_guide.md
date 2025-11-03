# 🚀 Foundation Setup - Complete Implementation Guide

## Phase 1: Project Creation & Structure

### Step 1: Create Flutter Project

```bash
# Create new Flutter project
flutter create biotective_patient

# Navigate to project
cd biotective_patient

# Verify Flutter installation
flutter doctor
```

### Step 2: Update pubspec.yaml

Replace the entire `pubspec.yaml` with dependencies we'll need:

```yaml
name: biotective_patient
description: BioTective Patient Dashboard - Digital Health Platform for Chronic Disease Monitoring

publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # State Management
  provider: ^6.1.1
  
  # Backend & API
  supabase_flutter: ^2.3.4
  http: ^1.2.0
  
  # Data Visualization
  fl_chart: ^0.66.0
  
  # Data Serialization
  json_annotation: ^4.8.1
  
  # Date & Time
  intl: ^0.19.0
  
  # Image Handling
  image_picker: ^1.0.7
  cached_network_image: ^3.3.1
  
  # Icons
  cupertino_icons: ^1.0.6

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1
  
  # Code Generation
  build_runner: ^2.4.8
  json_serializable: ^6.7.1

flutter:
  uses-material-design: true
  
  # Assets (we'll add these later if needed)
  # assets:
  #   - assets/images/
  #   - assets/icons/
```

### Step 3: Install Dependencies

```bash
flutter pub get
```

---

## Phase 2: Project Structure

### Step 4: Create Folder Structure

Create this exact folder structure in `lib/`:

```bash
# Run these commands from the lib/ directory

mkdir -p config
mkdir -p core/models
mkdir -p core/services
mkdir -p core/utils
mkdir -p core/widgets
mkdir -p features/auth/screens
mkdir -p features/auth/widgets
mkdir -p features/auth/providers
mkdir -p features/patient/dashboard/screens
mkdir -p features/patient/dashboard/widgets
mkdir -p features/patient/dashboard/providers
mkdir -p features/patient/trends/screens
mkdir -p features/patient/trends/widgets
mkdir -p features/patient/trends/providers
mkdir -p features/patient/logging/screens
mkdir -p features/patient/logging/widgets
mkdir -p features/patient/logging/providers
mkdir -p features/patient/chat/screens
mkdir -p features/patient/chat/widgets
mkdir -p features/patient/chat/providers
mkdir -p features/patient/profile/screens
mkdir -p features/patient/profile/widgets
mkdir -p features/patient/profile/providers
mkdir -p features/patient/recommendations/screens
mkdir -p features/patient/recommendations/widgets
mkdir -p features/patient/recommendations/providers
mkdir -p shared/widgets
```

Your `lib/` folder should now look like this:

```
lib/
├── main.dart (already exists)
├── app.dart (we'll create)
├── config/
├── core/
│   ├── models/
│   ├── services/
│   ├── utils/
│   └── widgets/
├── features/
│   ├── auth/
│   │   ├── screens/
│   │   ├── widgets/
│   │   └── providers/
│   └── patient/
│       ├── dashboard/
│       ├── trends/
│       ├── logging/
│       ├── chat/
│       ├── profile/
│       └── recommendations/
└── shared/
    └── widgets/
```

---

## Phase 3: Configuration Files

Now let's create the core configuration files that everything else will depend on.

### File 1: `lib/config/env.dart`

```dart
/// Environment configuration
/// Store your API keys and URLs here
/// 
/// IMPORTANT: In production, use flutter_dotenv or similar
/// to keep secrets out of source control

class Env {
  // Supabase Configuration
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'YOUR_SUPABASE_URL_HERE',
  );
  
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'YOUR_SUPABASE_ANON_KEY_HERE',
  );
  
  // Backend API Configuration
  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://your-api-url.com',
  );
  
  // Feature Flags
  static const bool enableAIFeatures = true;
  static const bool enableOfflineMode = false;
  static const bool enableAnalytics = false;
  
  // App Configuration
  static const String appName = 'BioTective Health';
  static const String appVersion = '1.0.0';
  
  // Validation
  static bool get isConfigured {
    return supabaseUrl != 'YOUR_SUPABASE_URL_HERE' &&
           supabaseAnonKey != 'YOUR_SUPABASE_ANON_KEY_HERE';
  }
}
```

### File 2: `lib/config/constants.dart`

```dart
/// Application-wide constants

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
```

### File 3: `lib/config/theme.dart`

This is our complete design system:

```dart
import 'package:flutter/material.dart';

/// Application theme configuration
/// Implements Material Design 3 principles
class AppTheme {
  // ============================================
  // COLOR PALETTE
  // ============================================
  
  // Primary Colors
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color primaryGreen = Color(0xFF10B981);
  static const Color primaryRed = Color(0xFFEF4444);
  
  // Glucose Level Colors
  static const Color glucoseLow = Color(0xFFFBBF24);
  static const Color glucoseNormal = Color(0xFF10B981);
  static const Color glucoseHigh = Color(0xFFEF4444);
  
  // UI Colors
  static const Color backgroundColor = Color(0xFFF9FAFB);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color textPrimaryColor = Color(0xFF111827);
  static const Color textSecondaryColor = Color(0xFF6B7280);
  static const Color borderColor = Color(0xFFE5E7EB);
  
  // Status Colors
  static const Color successColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color infoColor = Color(0xFF3B82F6);
  
  // Category Colors (for icons and badges)
  static const Color mealColor = Color(0xFFF59E0B);
  static const Color activityColor = Color(0xFF10B981);
  static const Color medicationColor = Color(0xFF3B82F6);
  static const Color sleepColor = Color(0xFF8B5CF6);
  
  // ============================================
  // LIGHT THEME
  // ============================================
  
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    
    // Color Scheme
    colorScheme: const ColorScheme.light(
      primary: primaryBlue,
      secondary: primaryGreen,
      tertiary: primaryRed,
      error: errorColor,
      background: backgroundColor,
      surface: surfaceColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onError: Colors.white,
      onBackground: textPrimaryColor,
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
      ),
    ),
    
    // Card Theme
    cardTheme: CardTheme(
      color: surfaceColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      shadowColor: Colors.black.withOpacity(0.05),
    ),
    
    // Button Themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryBlue,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        side: const BorderSide(color: primaryBlue, width: 1.5),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryBlue,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    
    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: const TextStyle(color: textSecondaryColor),
    ),
    
    // Chip Theme
    chipTheme: ChipThemeData(
      backgroundColor: backgroundColor,
      selectedColor: primaryBlue,
      labelStyle: const TextStyle(fontSize: 14),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    
    // Bottom Navigation Bar Theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surfaceColor,
      selectedItemColor: primaryBlue,
      unselectedItemColor: textSecondaryColor,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 12),
    ),
    
    // Divider Theme
    dividerTheme: const DividerThemeData(
      color: borderColor,
      thickness: 1,
      space: 1,
    ),
    
    // Dialog Theme
    dialogTheme: DialogTheme(
      backgroundColor: surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 8,
    ),
    
    // Typography
    textTheme: const TextTheme(
      // Display
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
        height: 1.2,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
        height: 1.2,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
        height: 1.3,
      ),
      
      // Headline
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimaryColor,
        height: 1.3,
      ),
      
      // Title
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimaryColor,
        height: 1.4,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: textPrimaryColor,
        height: 1.4,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textPrimaryColor,
        height: 1.4,
      ),
      
      // Body
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: textPrimaryColor,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: textPrimaryColor,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: textSecondaryColor,
        height: 1.5,
      ),
      
      // Label
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textPrimaryColor,
        letterSpacing: 0.1,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: textPrimaryColor,
        letterSpacing: 0.5,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: textSecondaryColor,
        letterSpacing: 0.5,
      ),
    ),
  );
  
  // ============================================
  // DARK THEME (Optional for future)
  // ============================================
  
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: primaryBlue,
      secondary: primaryGreen,
      background: Color(0xFF111827),
      surface: Color(0xFF1F2937),
    ),
    // Add dark theme customization here
  );
  
  // ============================================
  // HELPER METHODS
  // ============================================
  
  /// Get color based on glucose level
  static Color getGlucoseColor(double value, double min, double max) {
    if (value < min) return glucoseLow;
    if (value > max) return glucoseHigh;
    return glucoseNormal;
  }
  
  /// Get status color
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'success':
        return successColor;
      case 'warning':
        return warningColor;
      case 'error':
      case 'danger':
        return errorColor;
      case 'info':
        return infoColor;
      default:
        return textSecondaryColor;
    }
  }
}
```

### File 4: `lib/config/routes.dart`

```dart
import 'package:flutter/material.dart';

/// Application routing configuration
/// Centralized navigation management
class AppRoutes {
  // Route names
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String onboarding = '/onboarding';
  
  // Main app routes
  static const String dashboard = '/dashboard';
  static const String trends = '/trends';
  static const String trendsDetail = '/trends/detail';
  static const String mealImpact = '/trends/meal-impact';
  static const String activityImpact = '/trends/activity-impact';
  static const String weeklyReport = '/trends/weekly-report';
  
  static const String chat = '/chat';
  static const String recommendations = '/recommendations';
  static const String recommendationDetail = '/recommendations/detail';
  
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String notifications = '/notifications';
  static const String calendar = '/calendar';
  static const String achievements = '/achievements';
  static const String education = '/education';
  static const String help = '/help';
  
  // Logging routes
  static const String logGlucose = '/log/glucose';
  static const String logMeal = '/log/meal';
  static const String logActivity = '/log/activity';
  static const String logMedication = '/log/medication';
  
  /// Generate routes
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Parse route arguments if any
    final args = settings.arguments;
    
    switch (settings.name) {
      case splash:
        return _buildRoute(const _PlaceholderScreen(title: 'Splash'));
        
      case login:
        return _buildRoute(const _PlaceholderScreen(title: 'Login'));
        
      case register:
        return _buildRoute(const _PlaceholderScreen(title: 'Register'));
        
      case onboarding:
        return _buildRoute(const _PlaceholderScreen(title: 'Onboarding'));
        
      case dashboard:
        return _buildRoute(const _PlaceholderScreen(title: 'Dashboard'));
        
      case trends:
        return _buildRoute(const _PlaceholderScreen(title: 'Trends'));
        
      case chat:
        return _buildRoute(const _PlaceholderScreen(title: 'Chat'));
        
      case recommendations:
        return _buildRoute(const _PlaceholderScreen(title: 'Recommendations'));
        
      case profile:
        return _buildRoute(const _PlaceholderScreen(title: 'Profile'));
        
      default:
        return _buildRoute(
          Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
  
  /// Helper method to build routes with transitions
  static MaterialPageRoute _buildRoute(Widget page) {
    return MaterialPageRoute(builder: (_) => page);
  }
  
  /// Navigation helpers
  static Future<T?> push<T>(BuildContext context, String routeName, {Object? arguments}) {
    return Navigator.pushNamed<T>(context, routeName, arguments: arguments);
  }
  
  static Future<T?> pushReplacement<T, TO>(BuildContext context, String routeName, {Object? arguments}) {
    return Navigator.pushReplacementNamed<T, TO>(context, routeName, arguments: arguments);
  }
  
  static void pop<T>(BuildContext context, [T? result]) {
    Navigator.pop(context, result);
  }
  
  static Future<T?> pushAndRemoveUntil<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
    bool Function(Route<dynamic>)? predicate,
  }) {
    return Navigator.pushNamedAndRemoveUntil(
      context,
      routeName,
      predicate ?? (route) => false,
      arguments: arguments,
    );
  }
}

/// Temporary placeholder screen for routes
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  
  const _PlaceholderScreen({required this.title});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              '$title Screen',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            const Text('Coming soon...'),
          ],
        ),
      ),
    );
  }
}
```

---

## ✅ Checklist

After completing this phase, you should have:

- [x] Flutter project created
- [x] All dependencies installed
- [x] Complete folder structure
- [x] Environment configuration (env.dart)
- [x] App constants (constants.dart)
- [x] Complete theme system (theme.dart)
- [x] Routing system (routes.dart)

## 🎯 Next Steps

Ready to continue with Phase 4? Let me know and I'll provide:
- Core utilities (`lib/core/utils/`)
- Core widgets (`lib/core/widgets/`)
- Shared widgets (`lib/shared/widgets/`)
- Main app entry point (`app.dart` and updated `main.dart`)

Type "Continue" and I'll provide the next set of files! 🚀