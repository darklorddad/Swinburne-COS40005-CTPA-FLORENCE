import 'package:flutter/material.dart';
import 'package:florence/features/clinician/models/health_data.dart';
import 'package:florence/features/clinician/models/patient.dart';
import 'package:florence/features/clinician/theme/app_theme.dart';
import 'package:florence/features/clinician/widgets/activity_chart.dart';
import 'package:intl/intl.dart';

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
  String _selectedFilter = 'Daily';
  DateTime _focusedDate = DateTime.now();

  List<ActivityData> get _filteredReadings {
    final filtered = widget.activityData.where((r) {
      if (_selectedFilter == 'Hourly') {
        final start = DateTime(_focusedDate.year, _focusedDate.month, _focusedDate.day);
        final end = start.add(const Duration(days: 1));
        return !r.date.isBefore(start) && r.date.isBefore(end);
      } else if (_selectedFilter == 'Daily') {
        final start = DateTime(_focusedDate.year, _focusedDate.month, _focusedDate.day).subtract(Duration(days: _focusedDate.weekday - 1));
        final end = start.add(const Duration(days: 7));
        return !r.date.isBefore(start) && r.date.isBefore(end);
      } else {
        final start = DateTime(_focusedDate.year, 1, 1);
        final end = DateTime(_focusedDate.year + 1, 1, 1);
        return !r.date.isBefore(start) && r.date.isBefore(end);
      }
    }).toList();
    return filtered;
  }

  List<ActivityData> get _filteredReadingsAsc {
    final list = List<ActivityData>.from(_filteredReadings);
    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  List<ActivityData> get _filteredReadingsDesc {
    final list = List<ActivityData>.from(_filteredReadings);
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  Widget _buildFilterHeader({
    required String selectedFilter,
    required DateTime focusedDate,
    required Function(String) onFilterChanged,
    required Function(DateTime) onDateChanged,
  }) {
    String dateLabel = '';
    if (selectedFilter == 'Hourly') {
      dateLabel = DateFormat('EEEE, d MMMM yyyy').format(focusedDate);
    } else if (selectedFilter == 'Daily') {
      final startOfWeek = focusedDate.subtract(Duration(days: focusedDate.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      dateLabel = '${DateFormat('d MMM').format(startOfWeek)} - ${DateFormat('d MMM yyyy').format(endOfWeek)}';
    } else {
      dateLabel = DateFormat('yyyy').format(focusedDate);
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.dividerColor, width: 1),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'Hourly', label: Text('24 Hours', style: TextStyle(fontSize: 12))),
                      ButtonSegment(value: 'Daily', label: Text('7 Days', style: TextStyle(fontSize: 12))),
                      ButtonSegment(value: 'Yearly', label: Text('12 Months', style: TextStyle(fontSize: 12))),
                    ],
                    selected: {selectedFilter},
                    onSelectionChanged: (newSelection) {
                      onFilterChanged(newSelection.first);
                    },
                    style: SegmentedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      selectedBackgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                      selectedForegroundColor: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: AppTheme.primaryColor),
                  onPressed: () {
                    if (selectedFilter == 'Hourly') {
                      onDateChanged(focusedDate.subtract(const Duration(days: 1)));
                    } else if (selectedFilter == 'Daily') {
                      onDateChanged(focusedDate.subtract(const Duration(days: 7)));
                    } else {
                      onDateChanged(DateTime(focusedDate.year - 1, focusedDate.month, focusedDate.day));
                    }
                  },
                ),
                Text(
                  dateLabel,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: AppTheme.primaryColor),
                  onPressed: () {
                    if (selectedFilter == 'Hourly') {
                      onDateChanged(focusedDate.add(const Duration(days: 1)));
                    } else if (selectedFilter == 'Daily') {
                      onDateChanged(focusedDate.add(const Duration(days: 7)));
                    } else {
                      onDateChanged(DateTime(focusedDate.year + 1, focusedDate.month, focusedDate.day));
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Analytics'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildFilterHeader(
              selectedFilter: _selectedFilter,
              focusedDate: _focusedDate,
              onFilterChanged: (filter) => setState(() => _selectedFilter = filter),
              onDateChanged: (date) => setState(() => _focusedDate = date),
            ),
            _buildTodayMovement(),
            _buildActivityStreak(),
            _buildWeeklyConsistency(),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayMovement() {
    final readings = _filteredReadingsDesc;
    final today = DateTime.now();
    final todayData = readings.firstWhere(
      (d) => isSameDay(d.date, today),
      orElse: () => readings.isNotEmpty ? readings.first : ActivityData(
        date: today,
        steps: 0,
        activeMinutes: 0,
        caloriesBurned: 0,
      ),
    );

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.dividerColor, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.directions_run, color: AppTheme.textSecondary, size: 20),
                      SizedBox(width: 8),
                      Text("Today's Movement", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    ],
                  ),
                  Icon(Icons.info_outline, size: 20, color: AppTheme.textSecondary),
                ],
              ),
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    Text(
                      todayData.activeMinutes.toString(),
                      style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                    ),
                    const Text('minutes', style: TextStyle(fontSize: 16, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(
                      'across ${todayData.activeMinutes > 0 ? (todayData.activeMinutes / 30).ceil() : 0} sessions', // Mock calculation
                      style: const TextStyle(fontSize: 12, color: AppTheme.textTertiary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem('Steps', todayData.steps.toString(), Icons.directions_walk, AppTheme.secondaryColor, isUp: true),
                  _buildStatItem('Calories', todayData.caloriesBurned.toString(), Icons.local_fire_department, AppTheme.accentColor, isUp: true),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color, {bool? isUp}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withValues(alpha: 0.5)),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              if (isUp != null) ...[
                const SizedBox(width: 8),
                Icon(
                  isUp ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 16,
                  color: isUp ? AppTheme.lowRiskColor : AppTheme.highRiskColor, // More activity is generally good
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildActivityStreak() {
    // Mock heatmap logic
    // Generate list of last 28 days status
    // This is a visual representation
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.dividerColor, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.local_fire_department_outlined, color: AppTheme.textSecondary, size: 20),
                      SizedBox(width: 8),
                      Text('Activity Streak', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    ],
                  ),
                  Icon(Icons.info_outline, size: 20, color: AppTheme.textSecondary),
                ],
              ),
              const SizedBox(height: 24),
              const Row(
                children: [
                  Text(
                    '5', // Mock streak
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                  ),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('DAY STREAK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary, letterSpacing: 0.5)),
                      Text('Start moving today!', style: TextStyle(fontSize: 13, color: AppTheme.textTertiary)),
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
                  final color = index > 24 ? AppTheme.dividerColor : AppTheme.lowRiskColor.withValues(alpha: opacity);
                  
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
              const SizedBox(height: 12),
              const Align(
                alignment: Alignment.centerRight,
                child: Text('Less ■■■ More', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
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
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.dividerColor, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_month_outlined, color: AppTheme.textSecondary, size: 20),
                      SizedBox(width: 8),
                      Text('Weekly Consistency', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    ],
                  ),
                  Icon(Icons.info_outline, size: 20, color: AppTheme.textSecondary),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 200,
                child: ActivityChart(activityData: _filteredReadingsAsc),
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

