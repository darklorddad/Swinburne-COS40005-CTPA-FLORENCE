/// Application Providers Setup for FLORENCE Digital Health Platform
/// Wires all state management providers
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Health Data
import '../../features/patient/core/providers/health_data_provider.dart';

// Services
import '../services/notifications/notification_service.dart';
import '../../features/patient/core/services/patient_profile_service.dart';

/// Create all app providers
List<ChangeNotifierProvider> createAppProviders() {
  return [
    // Health Data Provider
    ChangeNotifierProvider(
      create: (_) => HealthDataProvider(),
    ),

    // Notification Service
    ChangeNotifierProvider(
      create: (_) => NotificationService(),
    ),

    // Patient Profile Service (for demo mode)
    ChangeNotifierProvider(
      create: (_) => PatientProfileService(),
    ),
  ];
}

/// Wrap app with all providers
Widget setupProviders(Widget child) {
  return MultiProvider(
    providers: createAppProviders(),
    child: child,
  );
}

/// Provider helper extensions
extension HealthDataContext on BuildContext {
  HealthDataProvider get healthData =>
      Provider.of<HealthDataProvider>(this, listen: false);

  NotificationService get notifications =>
      Provider.of<NotificationService>(this, listen: false);

  PatientProfileService get patientProfile =>
      Provider.of<PatientProfileService>(this, listen: false);
}

/// Example usage in main.dart:
/// ```dart
/// void main() {
///   runApp(
///     setupProviders(
///       MaterialApp(
///         home: DashboardScreen(),
///       ),
///     ),
///   );
/// }
/// ```
///
/// Or accessing in widgets:
/// ```dart
/// class MyWidget extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     // Listen to changes
///     final healthData = context.watch<HealthDataProvider>();
///
///     // One-time access (no rebuild)
///     final notif = context.read<NotificationService>();
///
///     // Using extension
///     final data = context.healthData;
///
///     return Container();
///   }
/// }
/// ```
