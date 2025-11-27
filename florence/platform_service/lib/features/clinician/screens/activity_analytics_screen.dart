import 'package:flutter/material.dart';
import 'package:florence/features/clinician/models/health_data.dart';
import 'package:florence/features/clinician/models/patient.dart';
import 'package:florence/features/clinician/theme/app_theme.dart';
import 'package:florence/features/clinician/widgets/activity_chart.dart';

class ActivityAnalyticsScreen extends StatefulWidget {
  final Patient patient;
  final List<ActivityData> activityData;

  const ActivityAnalyticsScreen({
    super.key,
    required this.patient,
    required this.activityData,
  });

  @override
  State<ActivityAnalyticsScreen> createState() => _ActivityAnalyticsScreenState();
}

class _ActivityAnalyticsScreenState extends State<ActivityAnalyticsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Analytics'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildTodayMovement(),
            _buildActivityStreak(),
            _buildWeeklyConsistency(),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayMovement() {
    // Find today's data or latest
    final today = DateTime.now();
    final todayData = widget.activityData.firstWhere(
      (d) => isSameDay(d.date, today),
      orElse: () => ActivityData(
        date: today,
        steps: 0,
        activeMinutes: 0,
        caloriesBurned: 0,
      ),
    );

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text("Today's Movement", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Icon(Icons.info_outline, size: 20, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    Text(
                      todayData.activeMinutes.toString(),
                      style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    const Text('minutes', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text(
                      'across ${todayData.activeMinutes > 0 ? (todayData.activeMinutes / 30).ceil() : 0} sessions', // Mock calculation
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Steps', todayData.steps.toString(), Icons.directions_walk, AppTheme.primaryColor),
                  _buildStatItem('Calories', todayData.caloriesBurned.toString(), Icons.local_fire_department, Colors.orange),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildActivityStreak() {
    // Mock heatmap logic
    // Generate list of last 28 days status
    // This is a visual representation
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Activity Streak', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Icon(Icons.info_outline, size: 20, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text(
                    '5', // Mock streak
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('DAY STREAK', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                      Text('Start moving today!', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Heatmap Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: 28, // 4 weeks
                itemBuilder: (context, index) {
                  // Mock data: some days are active (green), some less (light green), some none (grey)
                  // Use index to vary
                  final opacity = (index % 3 == 0) ? 1.0 : ((index % 2 == 0) ? 0.4 : 0.1);
                  final color = index > 24 ? Colors.grey[200]! : AppTheme.lowRiskColor.withValues(alpha: opacity);
                  
                  // Simple day label for top row
                  if (index < 7) {
                    // We could add labels M T W T F S S above this grid instead
                  }
                  
                  return Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerRight,
                child: Text('Less ■■■ More', style: TextStyle(fontSize: 10, color: Colors.grey)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyConsistency() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Weekly Consistency', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Icon(Icons.info_outline, size: 20, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: ActivityChart(activityData: widget.activityData),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

