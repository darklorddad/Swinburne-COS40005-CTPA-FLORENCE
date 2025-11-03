/// Weekly Summaries Screen for FLORENCE Digital Health Platform
/// Displays weekly health summaries with trends and AI insights

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../../../config/theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/card_widgets.dart';
import '../../core/providers/health_data_provider.dart';
import '../../core/models/health_data_models.dart';

/// Weekly summaries screen
class WeeklySummariesScreen extends StatefulWidget {
  const WeeklySummariesScreen({super.key});

  @override
  State<WeeklySummariesScreen> createState() => _WeeklySummariesScreenState();
}

class _WeeklySummariesScreenState extends State<WeeklySummariesScreen> {
  int _weeksBack = 0; // 0 = this week, 1 = last week, etc.
  final int _maxWeeksBack = 12; // Show up to 12 weeks of history

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Summaries'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Share summary
            },
            tooltip: 'Share',
          ),
        ],
      ),
      body: Consumer<HealthDataProvider>(
        builder: (context, healthData, child) {
          final summary = _getWeeklySummary(healthData);

          return RefreshIndicator(
            onRefresh: () async {
              await healthData.refreshData();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Week selector
                  _buildWeekSelector(),
                  const SizedBox(height: 16),

                  // Overview card
                  _buildOverviewCard(summary),
                  const SizedBox(height: 16),

                  // Glucose metrics
                  _buildSectionHeader('Glucose Control'),
                  const SizedBox(height: 12),
                  _buildGlucoseMetricsCard(summary),
                  const SizedBox(height: 16),

                  // Activity & nutrition
                  _buildSectionHeader('Lifestyle'),
                  const SizedBox(height: 12),
                  _buildLifestyleCard(summary),
                  const SizedBox(height: 16),

                  // Medication adherence
                  _buildSectionHeader('Medication Adherence'),
                  const SizedBox(height: 12),
                  _buildMedicationCard(healthData),
                  const SizedBox(height: 16),

                  // Week comparison chart
                  _buildSectionHeader('Trends'),
                  const SizedBox(height: 12),
                  _buildTrendsCard(healthData),
                  const SizedBox(height: 16),

                  // AI insights
                  _buildSectionHeader('AI Insights'),
                  const SizedBox(height: 12),
                  _buildAIInsightsCard(summary),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Build week selector
  Widget _buildWeekSelector() {
    final weekStart = _getWeekStart();
    final weekEnd = _getWeekEnd();

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: _weeksBack < _maxWeeksBack
                  ? () {
                      setState(() => _weeksBack++);
                    }
                  : null,
              tooltip: 'Previous week',
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    _weeksBack == 0
                        ? 'This Week'
                        : _weeksBack == 1
                            ? 'Last Week'
                            : '$_weeksBack weeks ago',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${DateFormat('MMM d').format(weekStart)} - ${DateFormat('MMM d, yyyy').format(weekEnd)}',
                    style: TextStyle(
                      color: AppTheme.textSecondaryColor,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: _weeksBack > 0
                  ? () {
                      setState(() => _weeksBack--);
                    }
                  : null,
              tooltip: 'Next week',
            ),
          ],
        ),
      ),
    );
  }

  /// Build overview card
  Widget _buildOverviewCard(HealthSummary summary) {
    final avgGlucose = summary.averageGlucose;
    final timeInRange = summary.timeInRange;

    // Simple status based on time in range
    String status;
    Color statusColor;
    IconData statusIcon;

    if (timeInRange >= 70) {
      status = 'Excellent';
      statusColor = AppTheme.primaryGreen;
      statusIcon = Icons.check_circle;
    } else if (timeInRange >= 50) {
      status = 'Good';
      statusColor = AppTheme.warningColor;
      statusIcon = Icons.info;
    } else {
      status = 'Needs Attention';
      statusColor = AppTheme.errorColor;
      statusIcon = Icons.warning;
    }

    return Card(
      color: statusColor.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(statusIcon, color: statusColor, size: 32),
                const SizedBox(width: 12),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildOverviewStat(
                  'Avg Glucose',
                  '${avgGlucose.toStringAsFixed(0)} mg/dL',
                  Icons.water_drop,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey.shade300,
                ),
                _buildOverviewStat(
                  'Time in Range',
                  '${timeInRange.toStringAsFixed(0)}%',
                  Icons.track_changes,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build overview stat
  Widget _buildOverviewStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryBlue, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  /// Build glucose metrics card
  Widget _buildGlucoseMetricsCard(HealthSummary summary) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildMetricRow(
              'Average Glucose',
              '${summary.averageGlucose.toStringAsFixed(0)} mg/dL',
              Icons.water_drop,
              AppTheme.primaryBlue,
            ),
            const Divider(height: 24),
            _buildMetricRow(
              'Time in Range',
              '${summary.timeInRange.toStringAsFixed(0)}%',
              Icons.track_changes,
              AppTheme.primaryGreen,
            ),
            const Divider(height: 24),
            _buildMetricRow(
              'Total Readings',
              '${summary.totalReadings}',
              Icons.assessment,
              AppTheme.accentPurple,
            ),
            const Divider(height: 24),
            _buildMetricRow(
              'Readings/Day',
              (summary.totalReadings / 7).toStringAsFixed(1),
              Icons.calendar_today,
              AppTheme.primaryBlue,
            ),
          ],
        ),
      ),
    );
  }

  /// Build lifestyle card
  Widget _buildLifestyleCard(HealthSummary summary) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildMetricRow(
              'Activity Minutes',
              '${summary.totalActivityMinutes}',
              Icons.directions_run,
              AppTheme.activityColor,
            ),
            const Divider(height: 24),
            _buildMetricRow(
              'Minutes/Day',
              (summary.totalActivityMinutes / 7).toStringAsFixed(1),
              Icons.timer,
              AppTheme.activityColor,
            ),
            const Divider(height: 24),
            _buildMetricRow(
              'Total Meals',
              '${summary.totalMeals}',
              Icons.restaurant,
              AppTheme.mealColor,
            ),
            const Divider(height: 24),
            _buildMetricRow(
              'Average Carbs',
              '${summary.averageCarbs.toStringAsFixed(0)}g',
              Icons.grain,
              AppTheme.mealColor,
            ),
          ],
        ),
      ),
    );
  }

  /// Build medication card
  Widget _buildMedicationCard(HealthDataProvider healthData) {
    final adherence = healthData.getMedicationAdherence();

    Color color;
    IconData icon;
    String status;

    if (adherence >= 80) {
      color = AppTheme.primaryGreen;
      icon = Icons.check_circle;
      status = 'Excellent';
    } else if (adherence >= 60) {
      color = AppTheme.warningColor;
      icon = Icons.info;
      status = 'Good';
    } else {
      color = AppTheme.errorColor;
      icon = Icons.warning;
      status = 'Needs Improvement';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${adherence.toStringAsFixed(0)}% Adherence',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    status,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build trends card
  Widget _buildTrendsCard(HealthDataProvider healthData) {
    // Get last 4 weeks of data for comparison
    final weeks = <Map<String, dynamic>>[];

    for (int i = 3; i >= 0; i--) {
      final weekEnd = DateTime.now().subtract(Duration(days: (i * 7) + (_weeksBack * 7)));
      final weekStart = weekEnd.subtract(const Duration(days: 6));

      final summary = healthData.getHealthSummary(
        startDate: weekStart,
        endDate: weekEnd,
      );

      weeks.add({
        'label': i == 0 && _weeksBack == 0 ? 'This' : 'Wk ${4 - i}',
        'avgGlucose': summary.averageGlucose,
        'timeInRange': summary.timeInRange,
      });
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Average Glucose (Last 4 Weeks)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 200,
                  minY: 70,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < weeks.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                weeks[value.toInt()]['label'],
                                style: const TextStyle(fontSize: 12),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 50,
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: weeks.asMap().entries.map((entry) {
                    final avgGlucose = entry.value['avgGlucose'] as double;
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: avgGlucose,
                          color: AppTheme.primaryBlue,
                          width: 20,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build AI insights card
  Widget _buildAIInsightsCard(HealthSummary summary) {
    final insights = _generateAIInsights(summary);

    return Card(
      color: AppTheme.primaryBlue.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.psychology,
                    color: AppTheme.primaryBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'AI-Powered Insights',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...insights.map((insight) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(top: 7, right: 12),
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryBlue,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          insight,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  /// Build metric row
  Widget _buildMetricRow(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 15),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Build section header
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  /// Get week start date
  DateTime _getWeekStart() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final daysToSubtract = (now.weekday % 7) + (_weeksBack * 7);
    return today.subtract(Duration(days: daysToSubtract));
  }

  /// Get week end date
  DateTime _getWeekEnd() {
    return _getWeekStart().add(const Duration(days: 6, hours: 23, minutes: 59));
  }

  /// Get weekly summary
  HealthSummary _getWeeklySummary(HealthDataProvider healthData) {
    return healthData.getHealthSummary(
      startDate: _getWeekStart(),
      endDate: _getWeekEnd(),
    );
  }

  /// Generate AI insights
  List<String> _generateAIInsights(HealthSummary summary) {
    final insights = <String>[];

    // Time in range insight
    if (summary.timeInRange >= 70) {
      insights.add(
        'Excellent glucose control! Your time in range of ${summary.timeInRange.toStringAsFixed(0)}% is well above the 70% target.',
      );
    } else if (summary.timeInRange >= 50) {
      insights.add(
        'Your time in range is ${summary.timeInRange.toStringAsFixed(0)}%. Consider reviewing meal timing and portions to reach the 70% target.',
      );
    } else {
      insights.add(
        'Time in range needs improvement at ${summary.timeInRange.toStringAsFixed(0)}%. Work with your healthcare team to adjust your management plan.',
      );
    }

    // Activity insight
    final avgActivityPerDay = summary.totalActivityMinutes / 7;
    if (avgActivityPerDay >= 30) {
      insights.add(
        'Great job staying active! You averaged ${avgActivityPerDay.toStringAsFixed(0)} minutes per day.',
      );
    } else if (avgActivityPerDay >= 15) {
      insights.add(
        'You\'re moving ${avgActivityPerDay.toStringAsFixed(0)} minutes/day. Try to gradually increase to 30 minutes for optimal glucose control.',
      );
    } else {
      insights.add(
        'Physical activity is key to glucose management. Start with 10-minute walks after meals.',
      );
    }

    // Reading frequency insight
    final avgReadingsPerDay = summary.totalReadings / 7;
    if (avgReadingsPerDay >= 4) {
      insights.add(
        'Consistent monitoring with ${avgReadingsPerDay.toStringAsFixed(1)} readings/day helps you understand your patterns.',
      );
    } else {
      insights.add(
        'More frequent glucose checks (aim for 4+ daily) provide better insights into your diabetes management.',
      );
    }

    return insights;
  }
}
