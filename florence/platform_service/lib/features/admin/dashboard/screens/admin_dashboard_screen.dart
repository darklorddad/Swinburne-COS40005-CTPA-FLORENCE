import 'package:florence/features/admin/core/widgets/admin_sidebar.dart';
import 'package:flutter/material.dart';
import 'package:florence/config/admin_theme.dart';
import 'package:florence/config/routes.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminSidebar(currentRoute: AppRoutes.adminDashboard),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 32),
                  _buildMetricCards(context),
                  const SizedBox(height: 32),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column (Feed)
                      Expanded(
                        flex: 7,
                        child: _buildActionFeed(context),
                      ),
                      const SizedBox(width: 24),
                      // Right Column (Quick Actions & Activity)
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildQuickActions(context),
                            const SizedBox(height: 24),
                            _buildRecentActivity(context),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Good Morning, Admin',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        Row(
          children: [
            SizedBox(
              width: 300,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search patients, doctors.',
                  prefixIcon: const Icon(Icons.search, color: AdminTheme.outline),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AdminTheme.outlineVariant),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AdminTheme.primary),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_none_rounded, color: AdminTheme.onSurfaceVariant),
                  onPressed: () {},
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: AdminTheme.error, shape: BoxShape.circle),
                  ),
                )
              ],
            ),
            IconButton(
              icon: const Icon(Icons.help_outline_rounded, color: AdminTheme.onSurfaceVariant),
              onPressed: () {},
            ),
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage('https://picsum.photos/id/83/200'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCards(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            title: 'Total Patients',
            value: '42',
            subtitle: '↑ 12%',
            subtitleColor: AdminTheme.primary,
            subtitleBg: AdminTheme.primaryContainer.withValues(alpha: 0.3),
            icon: Icons.people_outline,
            iconColor: AdminTheme.primary,
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _MetricCard(
            title: 'High-Risk Patients',
            value: '18',
            subtitle: 'Needs attention',
            subtitleColor: AdminTheme.error,
            subtitleBg: Colors.transparent,
            icon: Icons.warning_amber_rounded,
            iconColor: AdminTheme.error,
            isAlert: true,
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _MetricCard(
            title: 'Active Clinicians',
            value: '12',
            subtitle: 'On duty',
            subtitleColor: AdminTheme.onSurfaceVariant,
            subtitleBg: Colors.transparent,
            icon: Icons.medical_services_outlined,
            iconColor: AdminTheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildActionFeed(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Action Required Feed', style: Theme.of(context).textTheme.titleLarge),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(foregroundColor: AdminTheme.primary),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: AdminTheme.outlineVariant, width: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _FeedItem(
                name: 'Mohd Haris',
                alert: 'Critical Glucose Spike',
                doctor: 'Dr. Darren Tan',
                isHighRisk: true,
                avatarUrl: 'https://picsum.photos/id/120/200',
              ),
              const Divider(height: 1, color: AdminTheme.outlineVariant),
              _FeedItem(
                name: 'Wong Chee Keong',
                alert: 'Elevated Blood Pressure',
                doctor: 'Dr. Christina Wong',
                isHighRisk: true,
                avatarUrl: 'https://picsum.photos/id/67/200',
              ),
              const Divider(height: 1, color: AdminTheme.outlineVariant),
              _FeedItem(
                name: 'Sarah Felicia',
                alert: 'Missed Medication Dose',
                doctor: 'Dr. Putri Anisa',
                isHighRisk: false,
                avatarUrl: 'https://picsum.photos/id/124/200',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _QuickActionButton(icon: Icons.person_add_outlined, label: 'Add Patient'),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _QuickActionButton(icon: Icons.medical_information_outlined, label: 'Add Clinician'),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Activity', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        Card(
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: AdminTheme.outlineVariant, width: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _ActivityItem(
                  icon: Icons.person_add,
                  iconBg: AdminTheme.primaryContainer.withValues(alpha: 0.5),
                  title: 'New Patient Registered: John Doe',
                  time: '10 Mins Ago',
                  isLast: false,
                ),
                _ActivityItem(
                  icon: Icons.check_circle_outline,
                  iconBg: AdminTheme.surfaceContainerHighest,
                  title: 'Dr. Smith completed rounds',
                  time: '1 Hour Ago',
                  isLast: false,
                ),
                _ActivityItem(
                  icon: Icons.warning_amber_rounded,
                  iconBg: AdminTheme.errorContainer,
                  iconColor: AdminTheme.error,
                  title: 'Alert generated for Marcus Johnson',
                  time: '2 Hours Ago',
                  isLast: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Helper Widgets
class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color subtitleColor;
  final Color subtitleBg;
  final IconData icon;
  final Color iconColor;
  final bool isAlert;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.subtitleColor,
    required this.subtitleBg,
    required this.icon,
    required this.iconColor,
    this.isAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
            side: const BorderSide(color: AdminTheme.outlineVariant, width: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title, 
                  style: const TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w600,
                    color: AdminTheme.onSurfaceVariant,
                    letterSpacing: 0.3,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isAlert ? AdminTheme.errorContainer.withValues(alpha: 0.5) : AdminTheme.primaryContainer.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(value, style: Theme.of(context).textTheme.displaySmall),
                const SizedBox(width: 12),
                Container(
                  padding: subtitleBg != Colors.transparent ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4) : EdgeInsets.zero,
                  decoration: BoxDecoration(
                    color: subtitleBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    subtitle,
                    style: TextStyle(color: subtitleColor, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedItem extends StatelessWidget {
  final String name;
  final String alert;
  final String doctor;
  final bool isHighRisk;
  final String avatarUrl;

  const _FeedItem({required this.name, required this.alert, required this.doctor, required this.isHighRisk, required this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          CircleAvatar(radius: 24, backgroundImage: NetworkImage(avatarUrl)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      isHighRisk ? Icons.priority_high_rounded : Icons.medical_information, 
                      size: 16, 
                      color: isHighRisk ? AdminTheme.error : AdminTheme.onSurfaceVariant
                    ),
                    const SizedBox(width: 4),
                    Text(alert, style: TextStyle(color: isHighRisk ? AdminTheme.error : AdminTheme.onSurfaceVariant, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 16, color: AdminTheme.outline),
                    const SizedBox(width: 4),
                    Text(doctor, style: const TextStyle(color: AdminTheme.outline, fontSize: 14)),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isHighRisk ? AdminTheme.errorContainer : AdminTheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  isHighRisk ? 'High Risk' : 'Medium Risk',
                  style: TextStyle(
                    color: isHighRisk ? AdminTheme.onErrorContainer : AdminTheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: AdminTheme.onSurface,
                  side: const BorderSide(color: AdminTheme.secondary),
                  backgroundColor: AdminTheme.secondary.withValues(alpha: 0.1),
                ),
                child: const Text('Review'),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;

  const _QuickActionButton({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
            side: const BorderSide(color: AdminTheme.outlineVariant, width: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(
            children: [
              Icon(icon, color: AdminTheme.primary, size: 32),
              const SizedBox(height: 16),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color? iconColor;
  final String title;
  final String time;
  final bool isLast;

  const _ActivityItem({required this.icon, required this.iconBg, this.iconColor, required this.title, required this.time, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                child: Icon(icon, size: 16, color: iconColor ?? AdminTheme.primary),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: AdminTheme.surfaceContainerHighest,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, color: AdminTheme.onSurface)),
                  const SizedBox(height: 4),
                  Text(time, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AdminTheme.onSurfaceVariant)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}