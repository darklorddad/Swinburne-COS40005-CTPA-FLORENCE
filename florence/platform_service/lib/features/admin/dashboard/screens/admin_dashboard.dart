import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:florence/config/admin_routes.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Mission Control'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // ref.invalidate(adminDashboardProvider);
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'System Overview',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              
              // 1. KPI Summary Cards
              _buildSummaryCards(context),
              const SizedBox(height: 32),

              // Responsive Layout for Main Content
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 800) {
                    // Desktop/Tablet Landscape: 2 Columns
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              _buildAIHealthSection(context),
                              const SizedBox(height: 24),
                              _buildRecentAuditLogs(context),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 1,
                          child: _buildQuickActions(context),
                        ),
                      ],
                    );
                  } else {
                    // Mobile/Tablet Portrait: 1 Column
                    return Column(
                      children: [
                        _buildQuickActions(context),
                        const SizedBox(height: 24),
                        _buildAIHealthSection(context),
                        const SizedBox(height: 24),
                        _buildRecentAuditLogs(context),
                      ],
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widget Builders ---

  Widget _buildSummaryCards(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _buildStatCard(context, 'Active Clinicians', '42', Icons.medical_services, Colors.blue),
        _buildStatCard(context, 'Total Patients', '1,284', Icons.people, Colors.green),
        _buildStatCard(context, 'Practice Groups', '12', Icons.domain, Colors.orange),
        _buildStatCard(context, 'Critical Alerts (24h)', '5', Icons.warning_amber_rounded, Colors.red),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 28),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '+12%', // Placeholder for trend
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Admin Controls', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _actionButton(
              context, 
              'Launch Data Simulator', 
              Icons.science, 
              Colors.purple, 
              () {
                Navigator.pushNamed(context, AdminRoutes.dataSimulator);
              }
            ),
            const SizedBox(height: 12),
            _actionButton(
              context, 
              'Provision New Clinician', 
              Icons.person_add, 
              Colors.blue, 
              () {
                // Navigator.pushNamed(context, AdminRoutes.createUser);
              }
            ),
            const SizedBox(height: 12),
            _actionButton(
              context, 
              'Manage Organizations', 
              Icons.business, 
              Colors.orange, 
              () {
                // Navigator.pushNamed(context, AdminRoutes.organizationsList);
              }
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildAIHealthSection(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('AI & Automation Engine Status', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _statusIndicator(context, 'LLM Rec Engine', 'Online', Colors.green)),
                const SizedBox(width: 16),
                Expanded(child: _statusIndicator(context, 'LAM Automation', 'Processing', Colors.blue)),
                const SizedBox(width: 16),
                Expanded(child: _statusIndicator(context, 'Chatbot API', 'Online', Colors.green)),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text('Recent LAM Triggers', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(backgroundColor: Colors.redAccent, child: Icon(Icons.warning, color: Colors.white, size: 16)),
              title: const Text('Dangerously High Glucose Alert Generated'),
              subtitle: const Text('Sent to Dr. Touch Khun • 2 mins ago'),
              trailing: const Text('Patient ID: 109'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(backgroundColor: Colors.blueAccent, child: Icon(Icons.lightbulb, color: Colors.white, size: 16)),
              title: const Text('Post-Meal Activity Recommendation Sent'),
              subtitle: const Text('Triggered by high carb meal log • 15 mins ago'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusIndicator(BuildContext context, String title, String status, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              ),
              const SizedBox(width: 8),
              Text(status, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildRecentAuditLogs(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('System Audit Logs', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                TextButton(onPressed: () {}, child: const Text('View All')),
              ],
            ),
            const SizedBox(height: 8),
            _logEntry('Admin "admin_1" created new Clinician profile.', '10:42 AM', Icons.person_add),
            const Divider(),
            _logEntry('Data Simulator injected 50 test records.', '09:15 AM', Icons.science),
            const Divider(),
            _logEntry('Organization "Bionime Hospital" settings updated.', 'Yesterday', Icons.settings),
          ],
        ),
      ),
    );
  }

  Widget _logEntry(String message, String time, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 16),
          Expanded(child: Text(message, style: const TextStyle(fontSize: 14))),
          Text(time, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
        ],
      ),
    );
  }
}
