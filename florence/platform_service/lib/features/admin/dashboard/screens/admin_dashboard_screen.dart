import 'package:flutter/material.dart';
import '../../../../config/admin_theme.dart';
import '../../core/widgets/admin_scaffold.dart';
import '../../core/services/admin_auth_service.dart';
import '../../core/services/permission_service.dart';
import '../../../../config/admin_routes.dart';

/// Admin Dashboard (Global)
/// System-wide overview with metrics, recent activity, and quick actions
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _authService = AdminAuthService();
  bool _isLoading = false;

  // Mock data - will be replaced with real data from backend
  final Map<String, dynamic> _systemMetrics = {
    'totalOrganizations': 3,
    'activeOrganizations': 3,
    'totalUsers': 6,
    'activeUsers': 6,
    'totalPatients': 1098, // Sum of all org patients
    'activePatients': 1042,
    'totalAppointments': 156,
    'todayAppointments': 23,
  };

  @override
  Widget build(BuildContext context) {
    final currentUser = PermissionService().currentUser;
    final isMobile = MediaQuery.of(context).size.width < 600;
    final padding = isMobile ? 16.0 : 24.0;

    return AdminScaffold(
      title: 'Admin Dashboard',
      currentRoute: AdminRoutes.adminDashboard,
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Header
              _buildWelcomeHeader(currentUser, isMobile),

              SizedBox(height: isMobile ? 24 : 32),

              // System Metrics
              _buildSystemMetrics(isMobile),

              SizedBox(height: isMobile ? 24 : 32),

              // Organizations Overview & Recent Activity
              LayoutBuilder(
                builder: (context, constraints) {
                  // Mobile/Tablet: Stack vertically
                  if (constraints.maxWidth < 900) {
                    return Column(
                      children: [
                        _buildOrganizationsOverview(isMobile),
                        SizedBox(height: isMobile ? 16 : 24),
                        _buildRecentActivity(isMobile),
                      ],
                    );
                  }

                  // Desktop: Side-by-side
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Organizations Overview
                      Expanded(
                        flex: 2,
                        child: _buildOrganizationsOverview(isMobile),
                      ),

                      const SizedBox(width: 24),

                      // Recent Activity
                      Expanded(
                        flex: 1,
                        child: _buildRecentActivity(isMobile),
                      ),
                    ],
                  );
                },
              ),

              SizedBox(height: isMobile ? 24 : 32),

              // Quick Actions
              _buildQuickActions(isMobile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(dynamic currentUser, bool isMobile) {
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
        Text(
          '$greeting, ${currentUser?.firstName ?? 'Admin'}!',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: isMobile ? 24 : 32,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Here\'s an overview of your system',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AdminTheme.textSecondaryColor,
                fontSize: isMobile ? 14 : 16,
              ),
        ),
      ],
    );
  }

  Widget _buildSystemMetrics(bool isMobile) {
    return ResponsiveGrid(
      minChildWidth: isMobile ? 150 : 250,
      spacing: isMobile ? 12 : 20,
      runSpacing: isMobile ? 12 : 20,
      children: [
        StatCard(
          title: 'Organizations',
          value: _systemMetrics['totalOrganizations'].toString(),
          icon: Icons.business,
          color: AdminTheme.primaryIndigo,
          subtitle: '${_systemMetrics['activeOrganizations']} active',
          onTap: () {
            AdminRoutes.push(context, AdminRoutes.organizations);
          },
        ),
        StatCard(
          title: 'Total Users',
          value: _systemMetrics['totalUsers'].toString(),
          icon: Icons.people,
          color: AdminTheme.accentTeal,
          subtitle: '${_systemMetrics['activeUsers']} active',
          onTap: () {
            AdminRoutes.push(context, AdminRoutes.users);
          },
        ),
        StatCard(
          title: 'Total Patients',
          value: _systemMetrics['totalPatients'].toString(),
          icon: Icons.personal_injury,
          color: AdminTheme.successColor,
          subtitle: '${_systemMetrics['activePatients']} active',
          onTap: () {
            AdminRoutes.push(context, AdminRoutes.patients);
          },
        ),
        StatCard(
          title: 'Appointments',
          value: _systemMetrics['totalAppointments'].toString(),
          icon: Icons.calendar_today,
          color: AdminTheme.warningColor,
          subtitle: '${_systemMetrics['todayAppointments']} today',
          onTap: () {
            AdminRoutes.push(context, AdminRoutes.appointments);
          },
        ),
      ],
    );
  }

  Widget _buildOrganizationsOverview(bool isMobile) {
    final orgs = _authService.getAllOrganizations();

    return Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Organizations',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: isMobile ? 18 : 20,
                        ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    AdminRoutes.push(context, AdminRoutes.organizations);
                  },
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...orgs.map((org) => _buildOrganizationItem(org)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrganizationItem(dynamic org) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminTheme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AdminTheme.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AdminTheme.primaryIndigo.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.business,
              color: AdminTheme.primaryIndigo,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  org.name,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${org.city}, ${org.state}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AdminTheme.textSecondaryColor,
                      ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${org.patientCount} patients',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 4),
              AdminTheme.getStatusBadge(org.status.displayName),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(bool isMobile) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: isMobile ? 18 : 20,
                  ),
            ),
            const SizedBox(height: 16),
            _buildActivityItem(
              icon: Icons.business,
              title: 'New Organization',
              subtitle: 'Memorial Medical Center created',
              time: '2 hours ago',
              color: AdminTheme.successColor,
            ),
            _buildActivityItem(
              icon: Icons.person_add,
              title: 'User Added',
              subtitle: 'Dr. James Johnson joined',
              time: '5 hours ago',
              color: AdminTheme.infoColor,
            ),
            _buildActivityItem(
              icon: Icons.edit,
              title: 'Organization Updated',
              subtitle: 'City General Hospital details modified',
              time: '1 day ago',
              color: AdminTheme.warningColor,
            ),
            _buildActivityItem(
              icon: Icons.admin_panel_settings,
              title: 'Role Modified',
              subtitle: 'Hospital Admin permissions updated',
              time: '2 days ago',
              color: AdminTheme.primaryIndigo,
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () {
                  AdminRoutes.push(context, AdminRoutes.auditLogs);
                },
                child: const Text('View All Activity'),
              ),
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
              color: color.withOpacity(0.1),
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

  Widget _buildQuickActions(bool isMobile) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: isMobile ? 18 : 20,
                  ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildActionButton(
                  icon: Icons.add_business,
                  label: 'Create Organization',
                  onPressed: () {
                    AdminRoutes.push(context, AdminRoutes.createOrganization);
                  },
                ),
                _buildActionButton(
                  icon: Icons.person_add,
                  label: 'Add User',
                  onPressed: () {
                    AdminRoutes.push(context, AdminRoutes.createUser);
                  },
                ),
                _buildActionButton(
                  icon: Icons.admin_panel_settings,
                  label: 'Manage Roles',
                  onPressed: () {
                    AdminRoutes.push(context, AdminRoutes.roles);
                  },
                ),
                _buildActionButton(
                  icon: Icons.history,
                  label: 'View Audit Logs',
                  onPressed: () {
                    AdminRoutes.push(context, AdminRoutes.auditLogs);
                  },
                ),
                _buildActionButton(
                  icon: Icons.medication,
                  label: 'Manage Medications',
                  onPressed: () {
                    AdminRoutes.push(context, AdminRoutes.medications);
                  },
                ),
                _buildActionButton(
                  icon: Icons.settings,
                  label: 'System Settings',
                  onPressed: () {
                    AdminRoutes.push(context, AdminRoutes.settings);
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
}
