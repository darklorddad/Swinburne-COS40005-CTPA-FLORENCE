import 'package:flutter/material.dart';
import '../../../../config/admin_theme.dart';
import '../../core/widgets/admin_scaffold.dart';
import '../../core/services/permission_service.dart';
import '../../core/services/admin_auth_service.dart';
import '../../../../config/admin_routes.dart';

/// Hospital Admin Dashboard
/// Organization-scoped dashboard for hospital administrators
class HospitalAdminDashboardScreen extends StatefulWidget {
  const HospitalAdminDashboardScreen({super.key});

  @override
  State<HospitalAdminDashboardScreen> createState() =>
      _HospitalAdminDashboardScreenState();
}

class _HospitalAdminDashboardScreenState
    extends State<HospitalAdminDashboardScreen> {
  final _permissionService = PermissionService();
  final _authService = AdminAuthService();
  bool _isLoading = false;

  // Organization-specific metrics
  Map<String, dynamic> _orgMetrics = {};

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 500)); // Simulate API

    final currentUser = _permissionService.currentUser;
    final org = currentUser?.organization;

    if (org != null) {
      // Get users in this organization
      final orgUsers = _authService
          .getAllUsers()
          .where((u) => u.organizationId == org.id)
          .toList();

      setState(() {
        _orgMetrics = {
          'totalUsers': orgUsers.length,
          'activeUsers': orgUsers.where((u) => u.isActive).length,
          'totalPatients': org.patientCount ?? 0,
          'activePatients': ((org.patientCount ?? 0) * 0.95).round(), // Mock
          'todayAppointments': 15, // Mock
          'upcomingAppointments': 42, // Mock
          'pendingReviews': 8, // Mock
          'criticalAlerts': 2, // Mock
        };
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _permissionService.currentUser;
    final org = currentUser?.organization;

    if (org == null) {
      return const Scaffold(
        body: Center(
          child: Text('Organization not found'),
        ),
      );
    }

    return AdminScaffold(
      title: 'Dashboard',
      currentRoute: AdminRoutes.hospitalAdminDashboard,
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Header
              _buildWelcomeHeader(currentUser, org),

              const SizedBox(height: 32),

              // Organization Metrics
              _buildOrganizationMetrics(),

              const SizedBox(height: 32),

              // Two-column layout
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left column - Stats & Actions
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        _buildQuickStats(),
                        const SizedBox(height: 24),
                        _buildQuickActions(),
                      ],
                    ),
                  ),

                  const SizedBox(width: 24),

                  // Right column - Recent Activity
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        _buildRecentActivity(),
                        const SizedBox(height: 24),
                        _buildUpcomingAppointments(),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(dynamic currentUser, dynamic org) {
    final now = DateTime.now();
    final hour = now.hour;
    String greeting;

    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 18) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$greeting, ${currentUser?.firstName ?? 'Admin'}!',
                    style:
                        Theme.of(context).textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Here\'s what\'s happening at ${org.name}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AdminTheme.textSecondaryColor,
                        ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AdminTheme.primaryIndigo.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.business,
                size: 32,
                color: AdminTheme.primaryIndigo,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOrganizationMetrics() {
    return ResponsiveGrid(
      minChildWidth: 250,
      spacing: 20,
      children: [
        StatCard(
          title: 'Patients',
          value: _orgMetrics['totalPatients']?.toString() ?? '0',
          icon: Icons.personal_injury,
          color: AdminTheme.successColor,
          subtitle: '${_orgMetrics['activePatients'] ?? 0} active',
          onTap: () {
            AdminRoutes.push(context, AdminRoutes.patients);
          },
        ),
        StatCard(
          title: 'Staff Members',
          value: _orgMetrics['totalUsers']?.toString() ?? '0',
          icon: Icons.people,
          color: AdminTheme.accentTeal,
          subtitle: '${_orgMetrics['activeUsers'] ?? 0} active',
          onTap: () {
            AdminRoutes.push(context, AdminRoutes.users);
          },
        ),
        StatCard(
          title: 'Today\'s Appointments',
          value: _orgMetrics['todayAppointments']?.toString() ?? '0',
          icon: Icons.calendar_today,
          color: AdminTheme.warningColor,
          subtitle: '${_orgMetrics['upcomingAppointments'] ?? 0} upcoming',
          onTap: () {
            AdminRoutes.push(context, AdminRoutes.appointments);
          },
        ),
        StatCard(
          title: 'Critical Alerts',
          value: _orgMetrics['criticalAlerts']?.toString() ?? '0',
          icon: Icons.warning,
          color: AdminTheme.errorColor,
          subtitle: 'Requires attention',
          onTap: () {
            AdminRoutes.push(context, AdminRoutes.events);
          },
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Statistics',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 20),
            _buildStatRow(
              'Pending Reviews',
              _orgMetrics['pendingReviews']?.toString() ?? '0',
              Icons.rate_review,
              AdminTheme.infoColor,
            ),
            const Divider(height: 24),
            _buildStatRow(
              'New Patients (This Week)',
              '12',
              Icons.person_add,
              AdminTheme.successColor,
            ),
            const Divider(height: 24),
            _buildStatRow(
              'Completed Appointments',
              '87',
              Icons.check_circle,
              AdminTheme.primaryIndigo,
            ),
            const Divider(height: 24),
            _buildStatRow(
              'Cancelled Appointments',
              '5',
              Icons.cancel,
              AdminTheme.errorColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildActionButton(
                  icon: Icons.person_add,
                  label: 'Add Staff',
                  onPressed: () {
                    AdminRoutes.push(context, AdminRoutes.createUser);
                  },
                ),
                _buildActionButton(
                  icon: Icons.personal_injury_outlined,
                  label: 'Add Patient',
                  onPressed: () {
                    AdminRoutes.push(context, AdminRoutes.createPatient);
                  },
                ),
                _buildActionButton(
                  icon: Icons.calendar_month,
                  label: 'Schedule Appointment',
                  onPressed: () {
                    AdminRoutes.push(context, AdminRoutes.createAppointment);
                  },
                ),
                _buildActionButton(
                  icon: Icons.groups,
                  label: 'Manage Practice Groups',
                  onPressed: () {
                    AdminRoutes.push(context, AdminRoutes.practiceGroups);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 16),
            _buildActivityItem(
              icon: Icons.person_add,
              title: 'New Staff Member',
              subtitle: 'Dr. Sarah Williams joined',
              time: '1 hour ago',
              color: AdminTheme.successColor,
            ),
            _buildActivityItem(
              icon: Icons.personal_injury,
              title: 'Patient Registered',
              subtitle: 'John Doe completed registration',
              time: '3 hours ago',
              color: AdminTheme.infoColor,
            ),
            _buildActivityItem(
              icon: Icons.edit,
              title: 'Appointment Updated',
              subtitle: 'Consultation rescheduled',
              time: '5 hours ago',
              color: AdminTheme.warningColor,
            ),
            _buildActivityItem(
              icon: Icons.check_circle,
              title: 'Appointment Completed',
              subtitle: 'Follow-up with Jane Smith',
              time: '1 day ago',
              color: AdminTheme.primaryIndigo,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AdminTheme.textSecondaryColor,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AdminTheme.textLightColor,
                        fontSize: 11,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingAppointments() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Upcoming Appointments',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    AdminRoutes.push(context, AdminRoutes.appointments);
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildAppointmentItem(
              patientName: 'John Doe',
              doctorName: 'Dr. James Johnson',
              time: 'Today, 10:00 AM',
              type: 'Consultation',
            ),
            const Divider(height: 24),
            _buildAppointmentItem(
              patientName: 'Jane Smith',
              doctorName: 'Dr. Priya Patel',
              time: 'Today, 2:30 PM',
              type: 'Follow-up',
            ),
            const Divider(height: 24),
            _buildAppointmentItem(
              patientName: 'Robert Brown',
              doctorName: 'Dr. James Johnson',
              time: 'Tomorrow, 9:00 AM',
              type: 'Check-up',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentItem({
    required String patientName,
    required String doctorName,
    required String time,
    required String type,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                patientName,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AdminTheme.infoColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                type,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AdminTheme.infoColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              Icons.person_outline,
              size: 14,
              color: AdminTheme.textSecondaryColor,
            ),
            const SizedBox(width: 4),
            Text(
              doctorName,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AdminTheme.textSecondaryColor,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              Icons.access_time,
              size: 14,
              color: AdminTheme.textSecondaryColor,
            ),
            const SizedBox(width: 4),
            Text(
              time,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AdminTheme.textSecondaryColor,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}