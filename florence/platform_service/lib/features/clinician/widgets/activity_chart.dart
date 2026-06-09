import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:florence/features/clinician/models/health_data.dart';
import 'package:florence/features/clinician/theme/app_theme.dart';
import 'package:intl/intl.dart';

import 'dart:math';

class ActivityChart extends StatelessWidget {
  final List<ActivityData> activityData;
  final String filter;
  final DateTime focusedDate;
  final int targetMinutes;

  const ActivityChart({
    super.key,
    required this.activityData,
    required this.filter,
    required this.focusedDate,
    this.targetMinutes = 30,
  });

  @override
  Widget build(BuildContext context) {
    List<ActivityData> aggregatedData = [];

    if (filter == 'Hourly') {
      final start = DateTime(focusedDate.year, focusedDate.month, focusedDate.day);
      aggregatedData = List.generate(24, (hour) {
        return ActivityData(
          date: DateTime(start.year, start.month, start.day, hour),
          steps: 0,
          activeMinutes: 0,
          caloriesBurned: 0,
        );
      });
      for (var act in activityData) {
        final hour = act.date.hour;
        if (hour >= 0 && hour < 24) {
          aggregatedData[hour] = ActivityData(
            date: aggregatedData[hour].date,
            steps: aggregatedData[hour].steps + act.steps,
            activeMinutes: aggregatedData[hour].activeMinutes + act.activeMinutes,
            caloriesBurned: aggregatedData[hour].caloriesBurned + act.caloriesBurned,
          );
        }
      }
    } else if (filter == 'Daily') {
      final startOfWeek = DateTime(focusedDate.year, focusedDate.month, focusedDate.day).subtract(Duration(days: focusedDate.weekday - 1));
      aggregatedData = List.generate(7, (dayIndex) {
        final dayDate = startOfWeek.add(Duration(days: dayIndex));
        return ActivityData(
          date: dayDate,
          steps: 0,
          activeMinutes: 0,
          caloriesBurned: 0,
        );
      });
      for (var act in activityData) {
        final diff = act.date.difference(startOfWeek).inDays;
        if (diff >= 0 && diff < 7) {
          aggregatedData[diff] = ActivityData(
            date: aggregatedData[diff].date,
            steps: aggregatedData[diff].steps + act.steps,
            activeMinutes: aggregatedData[diff].activeMinutes + act.activeMinutes,
            caloriesBurned: aggregatedData[diff].caloriesBurned + act.caloriesBurned,
          );
        }
      }
    } else {
      aggregatedData = List.generate(12, (monthIndex) {
        final monthDate = DateTime(focusedDate.year, monthIndex + 1, 1);
        return ActivityData(
          date: monthDate,
          steps: 0,
          activeMinutes: 0,
          caloriesBurned: 0,
        );
      });
      
      Map<int, int> totalMinsPerMonth = {};
      Map<int, int> totalStepsPerMonth = {};
      Map<int, int> totalCalsPerMonth = {};
      
      for (var act in activityData) {
        if (act.date.year == focusedDate.year) {
          final m = act.date.month;
          totalMinsPerMonth[m] = (totalMinsPerMonth[m] ?? 0) + act.activeMinutes;
          totalStepsPerMonth[m] = (totalStepsPerMonth[m] ?? 0) + act.steps;
          totalCalsPerMonth[m] = (totalCalsPerMonth[m] ?? 0) + act.caloriesBurned;
        }
      }
      
      for (int i = 0; i < 12; i++) {
        final m = i + 1;
        final daysInMonth = DateTime(focusedDate.year, m + 1, 0).day;
        
        final avgMins = ((totalMinsPerMonth[m] ?? 0) / daysInMonth).round();
        final avgSteps = ((totalStepsPerMonth[m] ?? 0) / daysInMonth).round();
        final avgCals = ((totalCalsPerMonth[m] ?? 0) / daysInMonth).round();
        
        aggregatedData[i] = ActivityData(
          date: DateTime(focusedDate.year, m, 1),
          steps: avgSteps,
          activeMinutes: avgMins,
          caloriesBurned: avgCals,
        );
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8, right: 8),
      child: BarChart(
        _activityChartData(aggregatedData),
      ),
    );
  }

  BarChartData _activityChartData(List<ActivityData> sortedData) {
    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: _getMaxY(sortedData),
      minY: 0,
      groupsSpace: 12,
      barTouchData: BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final activity = sortedData[groupIndex];
            String title = '';
            if (filter == 'Hourly') {
              title = '${DateFormat('HH:00').format(activity.date)}\n';
            } else if (filter == 'Daily') {
              title = '${DateFormat('EEEE, d MMM').format(activity.date)}\n';
            } else {
              title = '${DateFormat('MMMM yyyy').format(activity.date)}\nDaily Avg: ';
            }
            return BarTooltipItem(
              '$title${activity.activeMinutes} active min\n',
              const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
              children: <TextSpan>[
                if (activity.steps > 0)
                  TextSpan(
                    text: '${activity.steps} steps\n',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                TextSpan(
                  text: '${activity.caloriesBurned} calories',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            );
          },
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              if (value < 0 || value >= sortedData.length) return const Text('');
              
              final index = value.toInt();
              if (index >= 0 && index < sortedData.length) {
                final date = sortedData[index].date;
                String label = '';
                if (filter == 'Hourly') {
                  if (index % 4 == 0) {
                    label = DateFormat('HH:00').format(date);
                  }
                } else if (filter == 'Daily') {
                  label = DateFormat('E').format(date);
                } else {
                  label = DateFormat('MMM').format(date);
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 10,
                    ),
                  ),
                );
              }
              return const Text('');
            },
            reservedSize: 28,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: _getYInterval(sortedData),
            getTitlesWidget: (value, meta) {
              return Text(
                '${value.toInt()}m',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                ),
              );
            },
            reservedSize: 36,
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
          left: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: _getYInterval(sortedData),
        getDrawingHorizontalLine: (value) {
          if (value == targetMinutes.toDouble()) {
            return FlLine(
              color: AppTheme.accentColor.withValues(alpha: 0.5),
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          }
          return FlLine(
            color: Colors.grey[300]!,
            strokeWidth: 0.5,
          );
        },
      ),
      barGroups: List.generate(
        sortedData.length,
        (index) {
          final activity = sortedData[index];
          
          // Calculate progress percentage
          final progressPercent = activity.activeMinutes / targetMinutes;
          
          // Choose color based on progress
          Color barColor;
          if (progressPercent >= 1.0) {
            barColor = AppTheme.lowRiskColor;
          } else if (progressPercent >= 0.6) {
            barColor = AppTheme.secondaryColor;
          } else {
            barColor = AppTheme.mediumRiskColor;
          }
          
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: activity.activeMinutes.toDouble(),
                color: barColor,
                width: 16,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          );
        },
      ),
      // Add target steps line
      extraLinesData: ExtraLinesData(
        horizontalLines: [
          HorizontalLine(
            y: targetMinutes.toDouble(),
            color: AppTheme.accentColor,
            strokeWidth: 1,
            dashArray: [5, 5],
            label: HorizontalLineLabel(
              show: true,
              alignment: Alignment.topRight,
              padding: const EdgeInsets.only(right: 5, bottom: 5),
              style: const TextStyle(
                color: AppTheme.accentColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              labelResolver: (_) => 'Target',
            ),
          ),
        ],
      ),
    );
  }

  double _getMaxY(List<ActivityData> sortedData) {
    if (sortedData.isEmpty) return targetMinutes * 1.2;
    
    final maxMins = sortedData.map((e) => e.activeMinutes).reduce((a, b) => a > b ? a : b);
    return maxMins > targetMinutes ? (maxMins * 1.2) : (targetMinutes * 1.2);
  }
  
  double _getYInterval(List<ActivityData> sortedData) {
    final maxY = _getMaxY(sortedData);
    if (maxY <= 15) return 5;
    if (maxY <= 30) return 10;
    if (maxY <= 60) return 15;
    if (maxY <= 120) return 30;
    return 45;
  }
}
