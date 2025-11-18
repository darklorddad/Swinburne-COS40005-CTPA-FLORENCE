import '../features/clinician/screens/clinician_profile_screen.dart';
import '../features/clinician/screens/patient_detail_screen.dart';
import 'package:flutter/material.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/patient/dashboard/screens/dashboard_screen.dart';
import '../features/patient/logging/screens/log_bmi_screen.dart';
import '../features/patient/logging/screens/log_blood_pressure_screen.dart';
import '../features/patient/logging/screens/log_cholesterol_screen.dart';
import '../features/patient/logging/screens/log_glucose_screen.dart';
import '../features/patient/logging/screens/log_activity_screen.dart';
import '../features/patient/logging/screens/log_medication_screen.dart';
import '../features/patient/logging/screens/log_meal_screen.dart';
import '../features/patient/profile/screens/profile_screen.dart';
import '../features/patient/trends/screens/trends_screen.dart';
import '../features/patient/trends/screens/glucose_trends_detail_screen.dart';
import '../features/patient/trends/screens/meal_impact_screen.dart';
import '../features/patient/trends/screens/activity_impact_screen.dart';
import '../features/patient/chat/screens/chat_screen.dart';
import '../features/patient/recommendations/screens/recommendations_screen.dart';
import '../features/patient/summaries/screens/weekly_summaries_screen.dart';
import '../features/clinician/screens/clinician_home_screen.dart';
import '../features/admin/dashboard/screens/super_admin_dashboard_screen.dart';

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
  static const String logBloodPressure = '/log/blood-pressure';
  static const String logCholesterol = '/log/cholesterol';
  static const String logBmi = '/log/bmi';

  // Clinician/Admin routes
  static const String clinicianDashboard = '/clinician-dashboard';
  static const String clinicianPatientDetail = '/clinician/patient-detail';
  static const String clinicianProfile = '/clinician/profile';
  static const String adminDashboard = '/admin-dashboard';

  /// Generate routes
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // The router can receive the full path including the fragment from a deep link.
    // We parse the URI to extract just the path for routing.
    final routePath = settings.name ?? '';
    final uri = Uri.parse(routePath);
    final routeName = uri.path;

    // Parse route arguments if any
    final args = settings.arguments;

    switch (routeName) {
      case splash:
        return _buildRoute(const SplashScreen(), settings);

      case login:
        return _buildRoute(const LoginScreen(), settings);

      case register:
        return _buildRoute(const RegisterScreen(), settings);

      case onboarding:
        return _buildRoute(const _PlaceholderScreen(title: 'Onboarding'));

      case dashboard:
        return _buildRoute(const DashboardScreen(), settings);

      case trends:
        return _buildRoute(const TrendsScreen(), settings);

      case trendsDetail:
        return _buildRoute(const GlucoseTrendsDetailScreen());

      case mealImpact:
        return _buildRoute(const MealImpactScreen());

      case activityImpact:
        return _buildRoute(const ActivityImpactScreen());

      case weeklyReport:
        return _buildRoute(const WeeklySummariesScreen());

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

      case logBloodPressure:
        return _buildRoute(const LogBloodPressureScreen(), settings);

      case logCholesterol:
        return _buildRoute(const LogCholesterolScreen(), settings);

      case logBmi:
        return _buildRoute(const LogBmiScreen(), settings);

      case clinicianDashboard:
        return _buildRoute(const ClinicianHomeScreen(), settings);

      case clinicianPatientDetail:
        return _buildRoute(const PatientDetailScreen(patientId:   ''), settings);

      case clinicianProfile:
        return _buildRoute(const ClinicianProfileScreen(), settings);

      case adminDashboard:
        return _buildRoute(const SuperAdminDashboardScreen(), settings);

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
