import 'package:flutter/material.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/patient/dashboard/screens/dashboard_screen.dart';
import '../features/patient/logging/screens/log_glucose_screen.dart';
import '../features/patient/logging/screens/log_activity_screen.dart';
import '../features/patient/logging/screens/log_medication_screen.dart';
import '../features/patient/logging/screens/log_meal_screen.dart';
import '../features/patient/profile/screens/profile_screen.dart';
import '../features/patient/trends/screens/trends_screen.dart';
import '../features/patient/chat/screens/chat_screen.dart';
import '../features/patient/recommendations/screens/recommendations_screen.dart';

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

  // Clinician routes
  static const String clinicianDashboard = '/clinician/dashboard';

  // Logging routes
  static const String logGlucose = '/log/glucose';
  static const String logMeal = '/log/meal';
  static const String logActivity = '/log/activity';
  static const String logMedication = '/log/medication';

  /// Generate routes
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final routeName = settings.name ?? '';

    // Intercept deep links from auth providers. They can come in various forms:
    // - /#access_token=... (older implicit grant flow)
    // - /?code=... (newer PKCE flow for verification)
    // - /?error=... (when a link is invalid, expired, or used)
    // - /login-callback... (a specific path we might have configured)
    //
    // By checking for these key parameters, we can direct all auth-related deep
    // links to a neutral loading screen (SplashScreen). This prevents the "No route
    // defined" error while the central auth listener in app.dart securely
    // processes the link in the background.
    if (routeName.contains('access_token=') ||
        routeName.contains('code=') ||
        routeName.contains('error=') ||
        routeName.startsWith('/login-callback')) {
      return _buildRoute(const SplashScreen(), settings);
    }

    // Parse route arguments if any
    final args = settings.arguments;

    switch (routeName) {
      case splash:
        return _buildRoute(const SplashScreen(), settings);

      case login:
        return _buildRoute(const LoginScreen(), settings);

      case register:
        return _buildRoute(const RegisterScreen(), settings);

      case clinicianDashboard:
        return _buildRoute(const _PlaceholderScreen(title: 'Clinician Dashboard'));

      case onboarding:
        return _buildRoute(const _PlaceholderScreen(title: 'Onboarding'));

      case dashboard:
        return _buildRoute(const DashboardScreen(), settings);

      case trends:
        return _buildRoute(const TrendsScreen(), settings);

      case chat:
        return _buildRoute(const ChatScreen(), settings);

      case recommendations:
        return _buildRoute(const RecommendationsScreen(), settings);

      case profile:
        return _buildRoute(const ProfileScreen(), settings);

      case logGlucose:
        return _buildRoute(const LogGlucoseScreen(), settings);

      case logMeal:
        return _buildRoute(const LogMealScreen(), settings);

      case logActivity:
        return _buildRoute(const LogActivityScreen(), settings);

      case logMedication: 
        return _buildRoute(const LogMedicationScreen(), settings);

      default:
        return _buildRoute(
          Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }

  /// Helper method to build routes with transitions
  static MaterialPageRoute _buildRoute(Widget page, [RouteSettings? settings]) {
    return MaterialPageRoute(builder: (_) => page, settings: settings);
  }

  /// Navigation helpers
  static Future<T?> push<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushNamed<T>(context, routeName, arguments: arguments);
  }

  static Future<T?> pushReplacement<T, TO>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushReplacementNamed<T, TO>(
      context,
      routeName,
      arguments: arguments,
    );
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
