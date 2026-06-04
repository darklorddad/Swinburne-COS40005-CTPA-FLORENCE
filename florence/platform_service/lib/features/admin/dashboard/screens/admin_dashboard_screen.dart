import 'package:florence/features/admin/core/widgets/admin_sidebar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:florence/config/admin_theme.dart';
import 'package:florence/config/routes.dart';
import 'package:florence/features/admin/core/providers/admin_providers.dart';
import 'package:florence/features/admin/core/models/admin_models.dart';
import 'package:florence/features/admin/patients/widgets/add_patient_dialog.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final metricsAsync = ref.watch(adminMetricsProvider);
    final patientsAsync = ref.watch(adminPatientsProvider);

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
                  
                  // LIVE METRICS
                  metricsAsync.when(
                    data: (metrics) => _buildMetricCards(context, metrics),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Text('Error loading metrics: $err', style: const TextStyle(color: AdminTheme.error)),
                  ),
                  
                  const SizedBox(height: 32),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // LIVE FEED
                      Expanded(
                        flex: 7,
                        child: patientsAsync.when(
                          data: (patients) => _buildActionFeed(context, patients),
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (err, stack) => Text('Failed to load feed: $err'),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildQuickActions(context),
                            const SizedBox(height: 24),
                            _buildRecentActivity(context, ref),
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
    final isMobile = MediaQuery.of(context).size.width < 800;
    
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Good Morning, Admin', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildSearchField()),
              const SizedBox(width: 16),
              const CircleAvatar(radius: 18, child: Icon(Icons.person)),
            ],
          ),
        ],
      );
    }
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text('Good Morning, Admin', style: Theme.of(context).textTheme.headlineMedium)),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 300, child: _buildSearchField()),
            const SizedBox(width: 16),
            const CircleAvatar(radius: 18, child: Icon(Icons.person)),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return TextField(
      onChanged: (val) => setState(() => _searchQuery = val),
      decoration: InputDecoration(
        hintText: 'Search patients, doctors...',
        prefixIcon: const Icon(Icons.search, color: AdminTheme.outline),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AdminTheme.outlineVariant)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AdminTheme.primary)),
      ),
    );
  }

  Widget _buildMetricCards(BuildContext context, AdminMetrics metrics) {
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            title: 'Total Patients',
            value: metrics.totalPatients.toString(),
            subtitle: 'Active accounts',
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
            value: metrics.highRiskPatients.toString(),
            subtitle: 'Needs attention',
            subtitleColor: AdminTheme.error,
            subtitleBg: AdminTheme.errorContainer.withValues(alpha: 0.5),
            icon: Icons.warning_amber_rounded,
            iconColor: AdminTheme.error,
            isAlert: true,
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _MetricCard(
            title: 'Hypoglycemia',
            value: metrics.hypoPatients.toString(),
            subtitle: 'Recent Alerts',
            subtitleColor: const Color(0xFFE65100), // Amber/Orange
            subtitleBg: const Color(0xFFFFE0B2).withValues(alpha: 0.5),
            icon: Icons.trending_down_rounded,
            iconColor: const Color(0xFFE65100),
            isAlert: metrics.hypoPatients > 0,
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _MetricCard(
            title: 'Hyperglycemia',
            value: metrics.hyperPatients.toString(),
            subtitle: 'Recent Alerts',
            subtitleColor: const Color(0xFFD32F2F), // Red
            subtitleBg: const Color(0xFFFFCDD2).withValues(alpha: 0.5),
            icon: Icons.trending_up_rounded,
            iconColor: const Color(0xFFD32F2F),
            isAlert: metrics.hyperPatients > 0,
          ),
        ),
      ],
    );
  }

  Widget _buildActionFeed(BuildContext context, List<AdminPatient> patients) {
    // 1. Filter by search query
    var filteredPatients = patients;
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filteredPatients = patients.where((p) => 
        p.name.toLowerCase().contains(query) ||
        (p.clinicianName?.toLowerCase().contains(query) ?? false) ||
        p.id.toString().contains(query)
      ).toList();
    }

    // 2. Show ANY patient that requires attention (High Risk, Hypo, or Hyper)
    final attentionPatients = filteredPatients.where((p) => p.requiresAttention).take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Action Required Feed', style: Theme.of(context).textTheme.titleLarge),
            TextButton(
              onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.adminPatientList),
              style: TextButton.styleFrom(foregroundColor: AdminTheme.primary),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (attentionPatients.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Center(
                child: Text(
                  _searchQuery.isNotEmpty 
                    ? 'No matching flagged patients found.' 
                    : 'All patient vitals are stable. ✅', 
                  style: const TextStyle(color: AdminTheme.outline)
                )
              ),
            ),
          )
        else
          Card(
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: AdminTheme.outlineVariant, width: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: attentionPatients.asMap().entries.map((entry) {
                final patient = entry.value;
                final isLast = entry.key == attentionPatients.length - 1;
                
                // Determine what text to show in the feed based on their status
                String alertText = patient.latestAlert ?? 'Flagged as High Risk';
                
                return Column(
                  children: [
                    _FeedItem(
                      name: patient.name,
                      alert: alertText,
                      doctor: patient.clinicianName ?? 'Unassigned',
                      riskLevel: patient.riskLevel,
                    ),
                    if (!isLast) const Divider(height: 1, color: AdminTheme.outlineVariant),
                  ],
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  // --- Keep your existing _buildQuickActions, _buildRecentActivity, _MetricCard, _FeedItem, _QuickActionButton, _ActivityItem below this line exactly as they are ---
  // ...

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _QuickActionButton(
                icon: Icons.person_add_outlined,
                label: 'Register Patient',
                onTap: () {
                  showDialog(
                    context: context,
                    barrierDismissible: false, // Prevents closing by tapping outside
                    builder: (context) => const AddPatientDialog(),
                  );
                },),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _QuickActionButton(
                icon: Icons.science_outlined,
                label: 'Data Simulator',
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.dataSimulator);
                },
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildRecentActivity(BuildContext context, WidgetRef ref) {
     final activityAsync = ref.watch(adminActivityProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Activity', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        Card(
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: AdminTheme.outlineVariant, width: 1.0),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: activityAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Text('Error loading activity: $err', style: const TextStyle(color: AdminTheme.error)),
              data: (activities) {
                if (activities.isEmpty) {
                  return const Center(child: Text('No recent activity.', style: TextStyle(color: AdminTheme.outline)));
                }

                return Column(
                  children: activities.asMap().entries.map((entry) {
                    final index = entry.key;
                    final activity = entry.value;
                    final isLast = index == activities.length - 1;

                    // Dynamically set icons and colors based on the backend iconType
                    final isWarning = activity.iconType == 'warning';
                    final icon = isWarning ? Icons.warning_amber_rounded : Icons.update_rounded;
                    final iconBg = isWarning ? AdminTheme.errorContainer : AdminTheme.primaryContainer.withValues(alpha: 0.5);
                    final iconColor = isWarning ? AdminTheme.error : AdminTheme.primary;

                    return _ActivityItem(
                      icon: icon,
                      iconBg: iconBg,
                      iconColor: iconColor,
                      title: activity.title,
                      subtitle: activity.subtitle,
                      time: _getTimeAgo(activity.timestamp),
                      isLast: isLast,
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
  String _getTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime.toLocal());
    if (diff.inDays > 0) return '${diff.inDays} ${diff.inDays == 1 ? 'day' : 'days'} ago';
    if (diff.inHours > 0) return '${diff.inHours} ${diff.inHours == 1 ? 'hour' : 'hours'} ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes} ${diff.inMinutes == 1 ? 'min' : 'mins'} ago';
    return 'Just now';
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
            side: const BorderSide(color: AdminTheme.outlineVariant, width: 1.0),
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
  final String riskLevel;

  const _FeedItem({
    required this.name, 
    required this.alert, 
    required this.doctor, 
    required this.riskLevel,
  });

  @override
  Widget build(BuildContext context) {
    final riskUpper = riskLevel.toUpperCase();
    final isHighRisk = riskUpper == 'HIGH';
    final isMediumRisk = riskUpper == 'MEDIUM';

    final Color badgeColor = isHighRisk
        ? AdminTheme.errorContainer
        : (isMediumRisk
            ? AdminTheme.surfaceContainerHighest
            : AdminTheme.primaryContainer);
            
    final Color textColor = isHighRisk
        ? AdminTheme.onErrorContainer
        : (isMediumRisk
            ? AdminTheme.onSurfaceVariant
            : AdminTheme.onPrimaryContainer);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24, 
            backgroundColor: AdminTheme.surfaceContainerHighest,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                fontWeight: FontWeight.bold, 
                fontSize: 20, 
                color: AdminTheme.onSurfaceVariant
              ),
            ),
          ),
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
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${riskLevel[0].toUpperCase()}${riskLevel.substring(1).toLowerCase()} Risk',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
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
  final VoidCallback? onTap;

  const _QuickActionButton({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
            side: const BorderSide(color: AdminTheme.outlineVariant, width: 1.0),
            borderRadius: BorderRadius.circular(12),
          ),
      child: InkWell(
        onTap: onTap,
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
  final String subtitle;
  final String time;
  final bool isLast;

  const _ActivityItem({required this.icon, required this.iconBg, this.iconColor, required this.title, required this.subtitle, required this.time, required this.isLast});

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
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 13, color: AdminTheme.onSurfaceVariant)),
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
