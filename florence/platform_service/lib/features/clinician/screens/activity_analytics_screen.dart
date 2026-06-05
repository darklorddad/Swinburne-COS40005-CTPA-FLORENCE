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
  DateTime _heatmapMonth = DateTime.now();
  DateTime? _selectedHeatmapDate;
  ActivityData? _selectedHeatmapDayData;

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
    final readings = _filteredReadings;
    
    String cardTitle = "Today's Movement";
    String valueText = "0";
    String sessionsText = "0 sessions";
    String stepsText = "0";
    String caloriesText = "0";
    
    if (_selectedFilter == 'Hourly') {
      cardTitle = "Movement on ${DateFormat('d MMM yyyy').format(_focusedDate)}";
      int totalMins = 0;
      int totalSteps = 0;
      int totalCals = 0;
      for (var r in readings) {
        totalMins += r.activeMinutes;
        totalSteps += r.steps;
        totalCals += r.caloriesBurned;
      }
      valueText = totalMins.toString();
      sessionsText = "across ${readings.length} sessions";
      stepsText = totalSteps.toString();
      caloriesText = totalCals.toString();
    } else if (_selectedFilter == 'Daily') {
      final startOfWeek = _focusedDate.subtract(Duration(days: _focusedDate.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      cardTitle = "Weekly Movement Summary";
      
      int totalMins = 0;
      int totalSteps = 0;
      int totalCals = 0;
      for (var r in readings) {
        totalMins += r.activeMinutes;
        totalSteps += r.steps;
        totalCals += r.caloriesBurned;
      }
      final daysWithData = readings.map((r) => DateTime(r.date.year, r.date.month, r.date.day)).toSet().length;
      final divisor = daysWithData > 0 ? daysWithData : 7;
      valueText = (totalMins / divisor).toStringAsFixed(0);
      sessionsText = "Daily average active minutes";
      stepsText = (totalSteps / divisor).toStringAsFixed(0);
      caloriesText = (totalCals / divisor).toStringAsFixed(0);
    } else {
      cardTitle = "Yearly Movement Summary";
      int totalMins = 0;
      int totalSteps = 0;
      int totalCals = 0;
      for (var r in readings) {
        totalMins += r.activeMinutes;
        totalSteps += r.steps;
        totalCals += r.caloriesBurned;
      }
      final monthsWithData = readings.map((r) => r.date.month).toSet().length;
      final divisor = monthsWithData > 0 ? monthsWithData : 12;
      valueText = (totalMins / divisor).toStringAsFixed(0);
      sessionsText = "Monthly average active minutes";
      stepsText = (totalSteps / divisor).toStringAsFixed(0);
      caloriesText = (totalCals / divisor).toStringAsFixed(0);
    }

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.directions_run, color: AppTheme.textSecondary, size: 20),
                      const SizedBox(width: 8),
                      Text(cardTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    ],
                  ),
                  const Icon(Icons.info_outline, size: 20, color: AppTheme.textSecondary),
                ],
              ),
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    Text(
                      valueText,
                      style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                    ),
                    const Text('minutes', style: TextStyle(fontSize: 16, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(
                      sessionsText,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textTertiary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem('Steps', stepsText, Icons.directions_walk, AppTheme.secondaryColor, isUp: true),
                  _buildStatItem('Calories', caloriesText, Icons.local_fire_department, AppTheme.accentColor, isUp: true),
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
    final year = _heatmapMonth.year;
    final month = _heatmapMonth.month;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final firstDayOffset = DateTime(year, month, 1).weekday - 1; // 0 for Monday, 6 for Sunday
    
    // Group activity data by day for the selected month
    final Map<int, ActivityData> monthDataMap = {};
    for (var act in widget.activityData) {
      if (act.date.year == year && act.date.month == month) {
        monthDataMap[act.date.day] = act;
      }
    }

    final totalCells = firstDayOffset + daysInMonth;
    final monthLabel = DateFormat('MMMM yyyy').format(_heatmapMonth);

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.local_fire_department_outlined, color: AppTheme.textSecondary, size: 20),
                      SizedBox(width: 8),
                      Text('Activity Streak', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    ],
                  ),
                  Text(
                    monthLabel,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Days of Week Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                    .map((d) => Expanded(
                          child: Text(
                            d,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 8),
              // Heatmap Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: totalCells,
                itemBuilder: (context, index) {
                  if (index < firstDayOffset) {
                    return const SizedBox.shrink();
                  }
                  
                  final day = index - firstDayOffset + 1;
                  final dayData = monthDataMap[day];
                  final hasData = dayData != null;
                  
                  Color cellColor = AppTheme.dividerColor;
                  if (hasData) {
                    final mins = dayData.activeMinutes;
                    if (mins >= 30) {
                      cellColor = AppTheme.lowRiskColor;
                    } else if (mins > 0) {
                      cellColor = AppTheme.lowRiskColor.withValues(alpha: 0.4);
                    }
                  }

                  final isSelected = _selectedHeatmapDate != null &&
                      _selectedHeatmapDate!.year == year &&
                      _selectedHeatmapDate!.month == month &&
                      _selectedHeatmapDate!.day == day;

                  return Tooltip(
                    message: hasData
                        ? '$day $monthLabel\n${dayData.activeMinutes} mins • ${dayData.caloriesBurned} kcal'
                        : '$day $monthLabel\nNo activity logged',
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedHeatmapDate = DateTime(year, month, day);
                          _selectedHeatmapDayData = dayData;
                        });
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        decoration: BoxDecoration(
                          color: cellColor,
                          borderRadius: BorderRadius.circular(6),
                          border: isSelected
                              ? Border.all(color: AppTheme.primaryColor, width: 2)
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            day.toString(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: hasData ? Colors.white : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              // Selected Day Details Banner
              if (_selectedHeatmapDate != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppTheme.primaryColor, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${DateFormat('d MMMM yyyy').format(_selectedHeatmapDate!)}: '
                          '${_selectedHeatmapDayData != null ? "${_selectedHeatmapDayData!.activeMinutes} mins • ${_selectedHeatmapDayData!.caloriesBurned} kcal" : "No activity logged"}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              // Navigation Buttons at the bottom right
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Less ■■■ More', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left, color: AppTheme.primaryColor),
                        onPressed: () {
                          setState(() {
                            _heatmapMonth = DateTime(_heatmapMonth.year, _heatmapMonth.month - 1);
                            _selectedHeatmapDate = null;
                            _selectedHeatmapDayData = null;
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right, color: AppTheme.primaryColor),
                        onPressed: () {
                          setState(() {
                            _heatmapMonth = DateTime(_heatmapMonth.year, _heatmapMonth.month + 1);
                            _selectedHeatmapDate = null;
                            _selectedHeatmapDayData = null;
                          });
                        },
                      ),
                    ],
                  ),
                ],
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
                height: 250,
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

