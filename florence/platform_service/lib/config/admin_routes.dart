import 'package:flutter/material.dart';
import '../features/admin/auth/screens/admin_login_screen.dart';
import '../features/admin/core/widgets/access_denied_screen.dart';
import '../features/admin/core/services/permission_service.dart';
import '../features/admin/core/models/admin_enums.dart';
import '../features/admin/patients/screens/patient_detail_screen.dart';

/// Admin Routes Configuration
/// Centralized routing for admin-side of the application
class AdminRoutes {
  // ============================================
  // ROUTE NAMES
  // ============================================

  // Auth
  static const String login = '/admin/login';

  // Dashboards
  static const String adminDashboard = '/admin/home';
  static const String hospitalAdminDashboard = '/admin/hospital-dashboard';
  static const String dashboard = '/admin/dashboard'; // Auto-redirect based on role

  // Organizations (Super Admin only)
  static const String organizations = '/admin/organizations';
  static const String organizationDetail = '/admin/organizations/:id';
  static const String createOrganization = '/admin/organizations/create';
  static const String editOrganization = '/admin/organizations/:id/edit';

  // Users
  static const String users = '/admin/users';
  static const String userDetail = '/admin/users/:id';
  static const String createUser = '/admin/users/create';
  static const String editUser = '/admin/users/:id/edit';

  // Patients
  static const String patients = '/admin/patients';
  static const String patientDetail = '/admin/patients/:id';
  static const String createPatient = '/admin/patients/create';
  static const String editPatient = '/admin/patients/:id/edit';
  static const String patientHealthData = '/admin/patients/:id/health-data';
  static const String mergePatients = '/admin/patients/merge';

  // Roles & Permissions
  static const String roles = '/admin/roles';
  static const String roleDetail = '/admin/roles/:id';
  static const String createRole = '/admin/roles/create';
  static const String editRole = '/admin/roles/:id/edit';
  static const String permissions = '/admin/permissions';

  // Medications
  static const String medications = '/admin/medications';
  static const String medicationDetail = '/admin/medications/:id';
  static const String createMedication = '/admin/medications/create';
  static const String editMedication = '/admin/medications/:id/edit';

  // Practice Groups
  static const String practiceGroups = '/admin/practice-groups';
  static const String practiceGroupDetail = '/admin/practice-groups/:id';
  static const String createPracticeGroup = '/admin/practice-groups/create';
  static const String editPracticeGroup = '/admin/practice-groups/:id/edit';

  // Appointments
  static const String appointments = '/admin/appointments';
  static const String appointmentDetail = '/admin/appointments/:id';
  static const String createAppointment = '/admin/appointments/create';
  static const String editAppointment = '/admin/appointments/:id/edit';

  // Events & Logs
  static const String events = '/admin/events';
  static const String hypoHyperEvents = '/admin/events/hypo-hyper';
  static const String patientLogbook = '/admin/events/logbook/:patientId';

  // Audit Logs (Super Admin only)
  static const String auditLogs = '/admin/audit-logs';
  static const String loginLogs = '/admin/audit-logs/login';
  static const String activityLogs = '/admin/audit-logs/activity';
  static const String deviceLogs = '/admin/audit-logs/device';

  // Settings
  static const String settings = '/admin/settings';
  static const String profile = '/admin/profile';

  // Error
  static const String accessDenied = '/admin/access-denied';
  static const String notFound = '/admin/not-found';

  // ============================================
  // ROUTE GENERATOR
  // ============================================

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final permissionService = PermissionService();

    // Parse route and arguments
    final routeName = settings.name ?? '';
    final arguments = settings.arguments;

    // Check authentication
    if (!permissionService.isAuthenticated && routeName != login) {
      return MaterialPageRoute(
        builder: (_) => const AdminLoginScreen(),
        settings: settings,
      );
    }

    // Route based on path
    switch (routeName) {
      // ==================== AUTH ====================
      case AdminRoutes.login:
        return MaterialPageRoute(
          builder: (_) => const AdminLoginScreen(),
          settings: settings,
        );

      // ==================== DASHBOARDS ====================
      case AdminRoutes.dashboard:
        // Auto-redirect based on role
        return _buildDashboardRoute(settings);

      case AdminRoutes.adminDashboard:
        return _buildGuardedRoute(
          settings: settings,
          requiredRole: AdminRole.admin,
          builder: (_) => _PlaceholderScreen(
            title: 'Admin Dashboard',
            route: adminDashboard,
          ),
        );

      case AdminRoutes.hospitalAdminDashboard:
        return _buildGuardedRoute(
          settings: settings,
          requiredRole: AdminRole.hospitalAdmin,
          builder: (_) => _PlaceholderScreen(
            title: 'Hospital Admin Dashboard',
            route: hospitalAdminDashboard,
          ),
        );

      // ==================== ORGANIZATIONS ====================
      case AdminRoutes.organizations:
        return _buildGuardedRoute(
          settings: settings,
          requiredPermission: AdminPermission.viewAllOrganizations,
          builder: (_) => _PlaceholderScreen(
            title: 'Organizations',
            route: organizations,
          ),
        );

      case AdminRoutes.createOrganization:
        return _buildGuardedRoute(
          settings: settings,
          requiredPermission: AdminPermission.createOrganization,
          builder: (_) => _PlaceholderScreen(
            title: 'Create Organization',
            route: createOrganization,
          ),
        );

      // ==================== USERS ====================
      case AdminRoutes.users:
        return _buildGuardedRoute(
          settings: settings,
          anyPermissions: [
            AdminPermission.viewAllUsers,
            AdminPermission.viewOrgUsers,
          ],
          builder: (_) => _PlaceholderScreen(
            title: 'Users',
            route: users,
          ),
        );

      case AdminRoutes.createUser:
        return _buildGuardedRoute(
          settings: settings,
          requiredPermission: AdminPermission.createUser,
          builder: (_) => _PlaceholderScreen(
            title: 'Create User',
            route: createUser,
          ),
        );

      // ==================== PATIENTS ====================
      case AdminRoutes.patients:
        return _buildGuardedRoute(
          settings: settings,
          anyPermissions: [
            AdminPermission.viewAllPatients,
            AdminPermission.viewOrgPatients,
          ],
          builder: (_) => _PlaceholderScreen(
            title: 'Patients',
            route: patients,
          ),
        );

      case AdminRoutes.patientDetail:
        return _buildGuardedRoute(
          settings: settings,
          requiredPermission: AdminPermission.viewAllPatients, // or viewOrgPatients
          builder: (_) {
            final patientData = settings.arguments as Map<String, dynamic>? ?? {};
            return PatientDetailScreen(patientData: patientData);
          },
        );

      case AdminRoutes.createPatient:
        return _buildGuardedRoute(
          settings: settings,
          requiredPermission: AdminPermission.createPatient,
          builder: (_) => _PlaceholderScreen(
            title: 'Create Patient',
            route: createPatient,
          ),
        );

      case AdminRoutes.mergePatients:
        return _buildGuardedRoute(
          settings: settings,
          requiredPermission: AdminPermission.mergePatients,
          builder: (_) => _PlaceholderScreen(
            title: 'Merge Patients',
            route: mergePatients,
          ),
        );

      // ==================== ROLES & PERMISSIONS ====================
      case AdminRoutes.roles:
        return _buildGuardedRoute(
          settings: settings,
          anyPermissions: [
            AdminPermission.viewAllRoles,
            AdminPermission.viewOrgRoles,
          ],
          builder: (_) => _PlaceholderScreen(
            title: 'Roles & Permissions',
            route: roles,
          ),
        );

      case AdminRoutes.createRole:
        return _buildGuardedRoute(
          settings: settings,
          requiredPermission: AdminPermission.createRole,
          builder: (_) => _PlaceholderScreen(
            title: 'Create Role',
            route: createRole,
          ),
        );

      case AdminRoutes.permissions:
        return _buildGuardedRoute(
          settings: settings,
          requiredPermission: AdminPermission.viewAllPermissions,
          builder: (_) => _PlaceholderScreen(
            title: 'Permissions',
            route: permissions,
          ),
        );

      // ==================== MEDICATIONS ====================
      case AdminRoutes.medications:
        return _buildGuardedRoute(
          settings: settings,
          requiredPermission: AdminPermission.viewMedications,
          builder: (_) => _PlaceholderScreen(
            title: 'Medications',
            route: medications,
          ),
        );

      case AdminRoutes.createMedication:
        return _buildGuardedRoute(
          settings: settings,
          requiredPermission: AdminPermission.createMedication,
          builder: (_) => _PlaceholderScreen(
            title: 'Create Medication',
            route: createMedication,
          ),
        );

      // ==================== PRACTICE GROUPS ====================
      case AdminRoutes.practiceGroups:
        return _buildGuardedRoute(
          settings: settings,
          requiredPermission: AdminPermission.viewPracticeGroups,
          builder: (_) => _PlaceholderScreen(
            title: 'Practice Groups',
            route: practiceGroups,
          ),
        );

      case AdminRoutes.createPracticeGroup:
        return _buildGuardedRoute(
          settings: settings,
          requiredPermission: AdminPermission.createPracticeGroup,
          builder: (_) => _PlaceholderScreen(
            title: 'Create Practice Group',
            route: createPracticeGroup,
          ),
        );

      // ==================== APPOINTMENTS ====================
      case AdminRoutes.appointments:
        return _buildGuardedRoute(
          settings: settings,
          requiredPermission: AdminPermission.viewAppointments,
          builder: (_) => _PlaceholderScreen(
            title: 'Appointments',
            route: appointments,
          ),
        );

      case AdminRoutes.createAppointment:
        return _buildGuardedRoute(
          settings: settings,
          requiredPermission: AdminPermission.createAppointment,
          builder: (_) => _PlaceholderScreen(
            title: 'Create Appointment',
            route: createAppointment,
          ),
        );

      // ==================== EVENTS & LOGS ====================
      case AdminRoutes.events:
        return _buildGuardedRoute(
          settings: settings,
          anyPermissions: [
            AdminPermission.viewHypoHyperEvents,
            AdminPermission.viewPatientLogbook,
          ],
          builder: (_) => _PlaceholderScreen(
            title: 'Events & Logs',
            route: events,
          ),
        );

      case AdminRoutes.hypoHyperEvents:
        return _buildGuardedRoute(
          settings: settings,
          requiredPermission: AdminPermission.viewHypoHyperEvents,
          builder: (_) => _PlaceholderScreen(
            title: 'Hypo/Hyper Events',
            route: hypoHyperEvents,
          ),
        );

      // ==================== AUDIT LOGS ====================
      case AdminRoutes.auditLogs:
        return _buildGuardedRoute(
          settings: settings,
          requiredPermission: AdminPermission.viewAuditLogs,
          builder: (_) => _PlaceholderScreen(
            title: 'Audit Logs',
            route: auditLogs,
          ),
        );

      case AdminRoutes.loginLogs:
        return _buildGuardedRoute(
          settings: settings,
          requiredPermission: AdminPermission.viewLoginLogs,
          builder: (_) => _PlaceholderScreen(
            title: 'Login Logs',
            route: loginLogs,
          ),
        );

      case AdminRoutes.activityLogs:
        return _buildGuardedRoute(
          settings: settings,
          requiredPermission: AdminPermission.viewActivityLogs,
          builder: (_) => _PlaceholderScreen(
            title: 'Activity Logs',
            route: activityLogs,
          ),
        );

      case AdminRoutes.deviceLogs:
        return _buildGuardedRoute(
          settings: settings,
          requiredPermission: AdminPermission.viewDeviceLogs,
          builder: (_) => _PlaceholderScreen(
            title: 'Device Logs',
            route: deviceLogs,
          ),
        );

      // ==================== SETTINGS ====================
      case AdminRoutes.settings:
        return MaterialPageRoute(
          builder: (_) => _PlaceholderScreen(
            title: 'Settings',
            route: AdminRoutes.settings,
          ),
          settings: settings,
        );

      case AdminRoutes.profile:
        return MaterialPageRoute(
          builder: (_) => _PlaceholderScreen(
            title: 'My Profile',
            route: profile,
          ),
          settings: settings,
        );

      // ==================== ERROR PAGES ====================
      case AdminRoutes.accessDenied:
        return MaterialPageRoute(
          builder: (_) => const AccessDeniedScreen(),
          settings: settings,
        );

      default:
        return _buildNotFoundRoute(settings);
    }
  }

  // ============================================
  // HELPER METHODS
  // ============================================

  /// Build route with permission guards
  static Route _buildGuardedRoute({
    required RouteSettings settings,
    AdminPermission? requiredPermission,
    List<AdminPermission>? anyPermissions,
    List<AdminPermission>? allPermissions,
    AdminRole? requiredRole,
    required WidgetBuilder builder,
  }) {
    final permissionService = PermissionService();

    // Check authentication
    if (!permissionService.isAuthenticated) {
      return MaterialPageRoute(
        builder: (_) => const AdminLoginScreen(),
        settings: settings,
      );
    }

    // Check role
    if (requiredRole != null && !permissionService.hasRole(requiredRole)) {
      return MaterialPageRoute(
        builder: (_) => AccessDeniedScreen(
          requiredRole: requiredRole,
        ),
        settings: settings,
      );
    }

    // Check single permission
    if (requiredPermission != null &&
        !permissionService.hasPermission(requiredPermission)) {
      return MaterialPageRoute(
        builder: (_) => AccessDeniedScreen(
          requiredPermission: requiredPermission,
        ),
        settings: settings,
      );
    }

    // Check any permissions (OR logic)
    if (anyPermissions != null &&
        !permissionService.hasAnyPermission(anyPermissions)) {
      return MaterialPageRoute(
        builder: (_) => AccessDeniedScreen(
          message: 'You do not have the required permissions to access this page.',
        ),
        settings: settings,
      );
    }

    // Check all permissions (AND logic)
    if (allPermissions != null &&
        !permissionService.hasAllPermissions(allPermissions)) {
      return MaterialPageRoute(
        builder: (_) => AccessDeniedScreen(
          message: 'You do not have all the required permissions to access this page.',
        ),
        settings: settings,
      );
    }

    // Permission check passed - build route
    return MaterialPageRoute(
      builder: builder,
      settings: settings,
    );
  }

  /// Build dashboard route based on user role
  static Route _buildDashboardRoute(RouteSettings settings) {
    final permissionService = PermissionService();
    final currentUser = permissionService.currentUser;

    if (currentUser == null) {
      return MaterialPageRoute(
        builder: (_) => const AdminLoginScreen(),
        settings: settings,
      );
    }

    // Redirect to appropriate dashboard based on role
    String dashboardRoute;
    if (currentUser.isAdmin) {
      dashboardRoute = adminDashboard;
    } else if (currentUser.isHospitalAdmin) {
      dashboardRoute = hospitalAdminDashboard;
    } else {
      // Fallback
      dashboardRoute = settings.name ?? dashboard;
    }

    return MaterialPageRoute(
      builder: (_) => _PlaceholderScreen(
        title: 'Dashboard',
        route: dashboardRoute,
      ),
      settings: RouteSettings(name: dashboardRoute),
    );
  }

  /// Build 404 not found route
  static Route _buildNotFoundRoute(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (_) => const _NotFoundScreen(),
      settings: settings,
    );
  }

  // ============================================
  // NAVIGATION HELPERS
  // ============================================

  /// Navigate to a route
  static Future<T?> push<T>(BuildContext context, String route,
      {Object? arguments}) {
    return Navigator.of(context).pushNamed<T>(route, arguments: arguments);
  }

  /// Replace current route
  static Future<T?> pushReplacement<T, TO>(BuildContext context, String route,
      {Object? arguments, TO? result}) {
    return Navigator.of(context)
        .pushReplacementNamed<T, TO>(route, arguments: arguments, result: result);
  }

  /// Push and remove all previous routes
  static Future<T?> pushAndRemoveUntil<T>(
      BuildContext context, String route, bool Function(Route<dynamic>) predicate,
      {Object? arguments}) {
    return Navigator.of(context)
        .pushNamedAndRemoveUntil<T>(route, predicate, arguments: arguments);
  }

  /// Pop current route
  static void pop<T>(BuildContext context, [T? result]) {
    Navigator.of(context).pop<T>(result);
  }

  /// Check if can pop
  static bool canPop(BuildContext context) {
    return Navigator.of(context).canPop();
  }
}

// ============================================
// PLACEHOLDER SCREENS (for development)
// ============================================

/// Placeholder screen for routes not yet implemented
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  final String route;

  const _PlaceholderScreen({
    required this.title,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    // Import AdminScaffold when implementing actual screens
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.construction,
                size: 64,
                color: Colors.orange,
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'This screen is coming soon!',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Route: $route',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 404 Not Found Screen
class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Page Not Found'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 24),
              Text(
                '404',
                style: Theme.of(context).textTheme.displayLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Page Not Found',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'The page you are looking for does not exist.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AdminRoutes.dashboard,
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.home),
                label: const Text('Go to Dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
