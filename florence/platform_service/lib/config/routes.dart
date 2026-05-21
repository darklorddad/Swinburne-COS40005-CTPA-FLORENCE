import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

// Admin-side imports
import 'package:florence/features/admin/dashboard/screens/admin_dashboard_screen.dart';
import 'package:florence/features/admin/auth/screens/admin_login_screen.dart';
import 'package:florence/features/admin/core/widgets/admin_sidebar.dart';
// Note: We are using the new PatientDirectoryScreen instead of the old PatientsListScreen
import 'package:florence/features/admin/patients/screens/patient_directory_screen.dart'; 

import 'package:florence/features/auth/screens/login_screen.dart';
import 'package:florence/features/auth/screens/register_screen.dart';
import 'package:florence/features/auth/screens/splash_screen.dart';
import 'package:florence/features/clinician/screens/clinician_home_screen.dart';
import 'package:florence/features/clinician/screens/clinician_profile_screen.dart';
import 'package:florence/features/clinician/screens/patient_detail_screen.dart';
import 'package:florence/features/patient/bottom_navigation/patient_bottom_nav_bar_shell.dart';
import 'package:florence/features/patient/chat/screens/chat_screen.dart';
import 'package:florence/features/patient/activity/screens/activity_unified_container.dart';
import 'package:florence/features/patient/blood_pressure/screens/blood_pressure_unified_container.dart';
import 'package:florence/features/patient/bmi/screens/bmi_unified_container.dart';
import 'package:florence/features/patient/cholesterol/screens/cholesterol_unified_container.dart';
import 'package:florence/features/patient/diet/screens/diet_unified_container.dart';
import 'package:florence/features/patient/glucose/screens/glucose_unified_container.dart';
import 'package:florence/features/patient/hba1c/screens/hba1c_unified_container.dart';
import 'package:florence/features/patient/medication/screens/medication_logging_screen.dart';
import 'package:florence/features/patient/notifications/screens/notifications_screen.dart';
import 'package:florence/features/patient/profile/screens/profile_screen.dart';
import 'package:florence/features/patient/profile/screens/settings_screen.dart';
import 'package:florence/features/patient/recommendations/screens/recommendations_screen.dart';

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
  static const String cholesterolDetail = '/cholesterol-detail';
  static const String mealDetail = '/meal-detail';

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

  // Clinician routes
  static const String clinicianDashboard = '/clinician-dashboard';
  static const String clinicianPatientDetail = '/clinician/patient-detail';
  static const String clinicianProfile = '/clinician/profile';

  // Admin routes
  static const String adminDashboard = '/admin-dashboard';
  static const String adminLogin = '/admin/login';
  static const String adminPatientList = '/admin/patients';
  static const String adminPatientDetail = '/admin/patient-detail';

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
        return _buildRoute(const GlucoseUnifiedContainer(initialTab: 0), settings);

      case trendsDetail:
        return _buildRoute(const GlucoseUnifiedContainer(initialTab: 0), settings);

      case bloodPressureDetail:
        return _buildRoute(const BloodPressureUnifiedContainer(initialTab: 0));

      case activityDetail:
        return _buildRoute(const ActivityUnifiedContainer(initialTab: 0));

      case bmiDetail:
        return _buildRoute(const BmiUnifiedContainer(initialTab: 0));

      case hba1cDetail:
        return _buildRoute(const HbA1cUnifiedContainer(initialTab: 0));

      case cholesterolDetail:
        return _buildRoute(const CholesterolUnifiedContainer(initialTab: 0));

      case mealDetail:
        return _buildRoute(const DietUnifiedContainer(initialTab: 0));

      case notifications:
        return _buildRoute(const NotificationsScreen());

      case chat:
        return _buildRoute(const ChatScreen(), settings);

      case recommendations:
        return _buildRoute(const RecommendationsScreen(), settings);

      case profile:
        return _buildRoute(const ProfileScreen(), settings);

      case AppRoutes.settings:
        return _buildRoute(const SettingsScreen(), settings);

      case logGlucose:
        return _buildRoute(const GlucoseUnifiedContainer(initialTab: 1), settings);

      case logMeal:
        return _buildRoute(const DietUnifiedContainer(initialTab: 1), settings);

      case logActivity:
        return _buildRoute(const ActivityUnifiedContainer(initialTab: 1), settings);

      case logMedication:
        return _buildRoute(const MedicationLoggingScreen(), settings);

      case logBloodPressure:
        return _buildRoute(const BloodPressureUnifiedContainer(initialTab: 1), settings);

      case logCholesterol:
        return _buildRoute(const CholesterolUnifiedContainer(initialTab: 1), settings);

      case logBmi:
        return _buildRoute(const BmiUnifiedContainer(initialTab: 1), settings);

      case logHba1c:
        return _buildRoute(const HbA1cUnifiedContainer(initialTab: 1), settings);

      case clinicianDashboard:
        return _buildRoute(const ClinicianHomeScreen(), settings);

      case clinicianPatientDetail:
        return _buildRoute(const PatientDetailScreen(patientId: ''), settings);

      case clinicianProfile:
        return _buildRoute(const ClinicianProfileScreen(), settings);

      // --- ADMIN ROUTES ---
      case adminDashboard:
        return _buildRoute(const AdminDashboardScreen(), settings);

      case adminLogin:
        return _buildRoute(const AdminLoginScreen(), settings);

      case adminPatientList:
        return _buildRoute(const PatientDirectoryScreen(), settings);

      case adminPatientDetail:
        // Routed to a placeholder until the new Admin Patient Detail screen is built
        return _buildRoute(const _PlaceholderScreen(title: 'Admin Patient Detail'), settings);

      default:
        return _buildRoute(
          Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }

  /// Helper method to build routes with premium iOS-style transitions
  static Route<dynamic> _buildRoute(Widget page, [RouteSettings? settings]) {
    return CupertinoPageRoute(builder: (_) => page, settings: settings);
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