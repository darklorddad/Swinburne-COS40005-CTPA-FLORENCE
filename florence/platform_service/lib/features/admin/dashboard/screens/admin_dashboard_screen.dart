import 'package:flutter/material.dart';
import '../../../../config/admin_theme.dart';
import '../../core/widgets/admin_scaffold.dart';
import '../../core/services/permission_service.dart';
import '../../../../config/admin_routes.dart';

/// Admin Dashboard
/// System-wide overview with patient metrics, recent activity, and quick actions
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final bool _isLoading = false;

  // Mock data tailored for Chronic Disease Monitoring MVP
  final Map<String, dynamic> _systemMetrics = {
    'totalPatients': 142,
    'highRiskPatients': 18,
    'totalClinicians': 12,
    'activeDevices': 89,
  };

  @override
  Widget build(BuildContext context) {
    final currentUser = PermissionService().currentUser;
    final isMobile = MediaQuery.of(context).size.width < 600;
    final padding = isMobile ? 16.0 : 32.0;

    return AdminScaffold(
      title: 'Admin Dashboard',
      currentRoute: AdminRoutes.adminDashboard,
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Header
                  _buildWelcomeHeader(currentUser, isMobile),

                  SizedBox(height: isMobile ? 24 : 32),

                  // Gradient KPI Cards
                  _buildSystemMetrics(isMobile),

                  SizedBox(height: isMobile ? 24 : 32),

                  // Main Content Grid
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 900) {
                        return Column(
                          children: [
                            _buildQuickActions(isMobile),
                            SizedBox(height: isMobile ? 16 : 24),
                            _buildHighRiskPatientsList(isMobile),
                            SizedBox(height: isMobile ? 16 : 24),
                            _buildRecentActivity(isMobile),
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Column: Priority Data (High Risk Patients)
                          Expanded(
                            flex: 7,
                            child: _buildHighRiskPatientsList(isMobile),
                          ),
                          const SizedBox(width: 24),
                          // Right Column: Actions & Logs
                          Expanded(
                            flex: 4,
                            child: Column(
                              children: [
                                _buildQuickActions(isMobile),
                                const SizedBox(height: 24),
                                _buildRecentActivity(isMobile),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(dynamic currentUser, bool isMobile) {
    final hour = DateTime.now().hour;
    String greeting = hour < 12 ? 'Good Morning' : (hour < 18 ? 'Good Afternoon' : 'Good Evening');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting, ${currentUser?.firstName ?? 'Admin'}!',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: isMobile ? 24 : 32,
                color: AdminTheme.textPrimaryColor,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'Here is the current status of the Florence Health Platform.',
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
      spacing: isMobile ? 12 : 24,
      runSpacing: isMobile ? 12 : 24,
      children: [
        _GradientStatCard(
          title: 'Total Patients',
          value: _systemMetrics['totalPatients'].toString(),
          icon: Icons.personal_injury_rounded,
          gradientColors: const [Color(0xFF4F46E5), Color(0xFF818CF8)], // Indigo
          subtitle: 'Active in system',
          onTap: () => Navigator.pushNamed(context, AdminRoutes.patients),
        ),
        _GradientStatCard(
          title: 'High Risk Patients',
          value: _systemMetrics['highRiskPatients'].toString(),
          icon: Icons.warning_rounded,
          gradientColors: const [Color(0xFFE11D48), Color(0xFFFB7185)], // Rose/Red
          subtitle: 'Requires attention',
          onTap: () => Navigator.pushNamed(context, AdminRoutes.patients),
        ),
        _GradientStatCard(
          title: 'Clinicians',
          value: _systemMetrics['totalClinicians'].toString(),
          icon: Icons.medical_services_rounded,
          gradientColors: const [Color(0xFF0D9488), Color(0xFF2DD4BF)], // Teal
          subtitle: 'Healthcare providers',
          onTap: () => Navigator.pushNamed(context, AdminRoutes.users),
        ),
        _GradientStatCard(
          title: 'Connected Devices',
          value: _systemMetrics['activeDevices'].toString(),
          icon: Icons.watch_rounded,
          gradientColors: const [Color(0xFFD97706), Color(0xFFFBBF24)], // Amber
          subtitle: 'Wearables synced',
          onTap: () {}, // Future feature
        ),
      ],
    );
  }

  Widget _buildHighRiskPatientsList(bool isMobile) {
    return Card(
      margin: EdgeInsets.zero, // FIX: Removes default Flutter card margin
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'High Risk Patients (Action Needed)',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: isMobile ? 18 : 20,
                      ),
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, AdminRoutes.patients),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildPatientListTile('Jordan Lee', 'Recent glucose spike (12.5 mmol/L)', 'Dr. Sarah', true),
            const Divider(),
            _buildPatientListTile('Maria Garcia', 'Missed 3 medication logs', 'Dr. Ahmed', true),
            const Divider(),
            _buildPatientListTile('Robert Chen', 'High BP trend detected', 'Dr. Sarah', true),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientListTile(String name, String alertMsg, String doctor, bool isHighRisk) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isHighRisk ? Colors.red.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
            child: Icon(
              Icons.person,
              color: isHighRisk ? AdminTheme.errorColor : AdminTheme.primaryIndigo,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text(alertMsg, style: TextStyle(color: AdminTheme.errorColor, fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(doctor, style: TextStyle(color: AdminTheme.textSecondaryColor, fontSize: 13)),
              const SizedBox(height: 4),
              Icon(Icons.chevron_right, color: AdminTheme.textLightColor, size: 20),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(bool isMobile) {
    return Card(
      margin: EdgeInsets.zero, // FIX: Removes default Flutter card margin
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                  icon: Icons.person_add_rounded,
                  label: 'Add Patient',
                  color: AdminTheme.primaryIndigo,
                  onPressed: () => Navigator.pushNamed(context, AdminRoutes.createPatient),
                ),
                _buildActionButton(
                  icon: Icons.medical_information_rounded,
                  label: 'Add Clinician',
                  color: AdminTheme.accentTeal,
                  onPressed: () => Navigator.pushNamed(context, AdminRoutes.createUser),
                ),
                _buildActionButton(
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  color: AdminTheme.textSecondaryColor,
                  onPressed: () => Navigator.pushNamed(context, AdminRoutes.settings),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required Color color, required VoidCallback onPressed}) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withOpacity(0.3)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildRecentActivity(bool isMobile) {
    return Card(
      margin: EdgeInsets.zero, // FIX: Removes default Flutter card margin
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent System Activity',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: isMobile ? 18 : 20,
                  ),
            ),
            const SizedBox(height: 16),
            _buildActivityItem(
              icon: Icons.warning_amber_rounded,
              title: 'Risk Level Elevated',
              subtitle: 'Jordan Lee updated to HIGH risk',
              time: '1 hour ago',
              color: AdminTheme.errorColor,
            ),
            _buildActivityItem(
              icon: Icons.person_add_rounded,
              title: 'New Patient Registered',
              subtitle: 'Emily Chen joined the platform',
              time: '3 hours ago',
              color: AdminTheme.successColor,
            ),
            _buildActivityItem(
              icon: Icons.assignment_ind_rounded,
              title: 'Clinician Assigned',
              subtitle: 'Dr. Sarah assigned to 3 new patients',
              time: '1 day ago',
              color: AdminTheme.primaryIndigo,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem({required IconData icon, required String title, required String subtitle, required String time, required Color color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: AdminTheme.textSecondaryColor, fontSize: 13)),
              ],
            ),
          ),
          Text(time, style: TextStyle(color: AdminTheme.textLightColor, fontSize: 11)),
        ],
      ),
    );
  }
}

/// Custom Gradient Card Widget for KPIs
class _GradientStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final List<Color> gradientColors;
  final String subtitle;
  final VoidCallback onTap;

  const _GradientStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.gradientColors,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradientColors.last.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: Colors.white, size: 24),
                    ),
                    const Icon(Icons.arrow_outward_rounded, color: Colors.white70, size: 20),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}