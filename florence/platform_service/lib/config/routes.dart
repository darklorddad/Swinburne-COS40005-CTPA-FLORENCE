import 'package:flutter/material.dart';

// Admin-side imports
import '../features/admin/dashboard/screens/admin_dashboard_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/clinician/screens/clinician_home_screen.dart';
import '../features/clinician/screens/clinician_profile_screen.dart';
import '../features/clinician/screens/patient_detail_screen.dart';
import '../features/patient/bottom_navigation/patient_bottom_nav_bar_shell.dart';
import '../features/patient/chat/screens/chat_screen.dart';
import '../features/patient/dashboard/screens/activity_detail_screen.dart';
import '../features/patient/dashboard/screens/blood_pressure_detail_screen.dart';
import '../features/patient/dashboard/screens/bmi_detail_screen.dart';
import '../features/patient/dashboard/screens/glucose_detail_screen.dart';
import '../features/patient/dashboard/screens/hba1c_detail_screen.dart';
import '../features/patient/logging/screens/log_activity_screen.dart';
import '../features/patient/logging/screens/log_blood_pressure_screen.dart';
import '../features/patient/logging/screens/log_bmi_screen.dart';
import '../features/patient/logging/screens/log_cholesterol_screen.dart';
import '../features/patient/logging/screens/log_glucose_screen.dart';
import '../features/patient/logging/screens/log_hba1c_screen.dart';
import '../features/patient/logging/screens/log_meal_screen.dart';
import '../features/patient/medication/screens/medication_logging_screen.dart';
import '../features/patient/profile/screens/profile_screen.dart';
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
  static const String bloodPressureDetail = '/trends/blood-pressure';
  static const String activityDetail = '/trends/activity-detail';
  static const String bmiDetail = '/bmi-detail';
  static const String hba1cDetail = '/hba1c-detail';

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
  static const String addMedication = '/add-medication';
  static const String logBloodPressure = '/log/blood-pressure';
  static const String logCholesterol = '/log/cholesterol';
  static const String logBmi = '/log/bmi';
  static const String logHba1c = '/log/Hba1c';

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
        return _buildRoute(const PatientBottomNavBarShell(), settings);

      case trends:
        return _buildRoute(const GlucoseDetailScreen(), settings);

      case trendsDetail:
        return _buildRoute(
            const GlucoseDetailScreen());

      case bloodPressureDetail:
        return _buildRoute(const BloodPressureDetailScreen());

      case activityDetail:
        return _buildRoute(const ActivityDetailScreen());

      case bmiDetail:
        return _buildRoute(const BmiDetailScreen());

      case hba1cDetail:
        return _buildRoute(const HbA1cDetailScreen());

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
        return _buildRoute(const MedicationLoggingScreen(), settings);

      case logBloodPressure:
        return _buildRoute(const LogBloodPressureScreen(), settings);

      case logCholesterol:
        return _buildRoute(const LogCholesterolScreen(), settings);

      case logBmi:
        return _buildRoute(const LogBmiScreen(), settings);

      case logHba1c:
        return _buildRoute(const LogHba1cScreen(), settings);

      case clinicianDashboard:
        return _buildRoute(const ClinicianHomeScreen(), settings);

      case clinicianPatientDetail:
        return _buildRoute(const PatientDetailScreen(patientId: ''), settings);

      case clinicianProfile:
        return _buildRoute(const ClinicianProfileScreen(), settings);

      case adminDashboard:
        return _buildRoute(const AdminDashboardScreen(), settings);

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
