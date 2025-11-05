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
    // Parse route arguments if any
    final args = settings.arguments;

    switch (settings.name) {
      case splash:
        return _buildRoute(const SplashScreen());

      case login:
        return _buildRoute(const LoginScreen());

      case register:
        return _buildRoute(const RegisterScreen());

      case clinicianDashboard:
        return _buildRoute(const _PlaceholderScreen(title: 'Clinician Dashboard'));

      case onboarding:
        return _buildRoute(const _PlaceholderScreen(title: 'Onboarding'));

      case dashboard:
        return _buildRoute(const DashboardScreen());

      case trends:
        return _buildRoute(const TrendsScreen());

      case chat:
        return _buildRoute(const ChatScreen());

      case recommendations:
        return _buildRoute(const RecommendationsScreen());

      case profile:
        return _buildRoute(const ProfileScreen());

      case logGlucose:
        return _buildRoute(const LogGlucoseScreen());

      case logMeal:
        return _buildRoute(const LogMealScreen());

      case logActivity:
        return _buildRoute(const LogActivityScreen());

      case logMedication: 
        return _buildRoute(const LogMedicationScreen());

      default:
        return _buildRoute(
          Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }

  /// Helper method to build routes with transitions
  static MaterialPageRoute _buildRoute(Widget page) {
    return MaterialPageRoute(builder: (_) => page);
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
