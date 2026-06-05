import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:florence/features/clinician/models/health_data.dart';
import 'package:florence/features/clinician/theme/app_theme.dart';
import 'package:intl/intl.dart';

class ActivityChart extends StatelessWidget {
  final List<ActivityData> activityData;
  final int targetMinutes;

  const ActivityChart({
    super.key,
    required this.activityData,
    this.targetMinutes = 30,
  });

  @override
  Widget build(BuildContext context) {
    if (activityData.isEmpty) {
      return const Center(child: Text('No activity data available'));
    }

    // Sort data by date
    final sortedData = [...activityData]..sort((a, b) => a.date.compareTo(b.date));

    return Padding(
      padding: const EdgeInsets.only(top: 16, right: 16, bottom: 16),
      child: AspectRatio(
        aspectRatio: 1.7,
        child: BarChart(
          _activityChartData(sortedData),
        ),
      ),
    );
  }

  BarChartData _activityChartData(List<ActivityData> sortedData) {
    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: _getMaxY(),
      minY: 0,
      groupsSpace: 12,
      barTouchData: BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final activity = sortedData[groupIndex];
            return BarTooltipItem(
              '${activity.activeMinutes} active min\n',
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
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    DateFormat('MM/dd').format(date),
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
            interval: _getYInterval(),
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
        horizontalInterval: _getYInterval(),
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

  double _getMaxY() {
    if (activityData.isEmpty) return targetMinutes * 1.2;
    
    final maxMins = activityData.map((e) => e.activeMinutes).reduce((a, b) => a > b ? a : b);
    return maxMins > targetMinutes ? (maxMins * 1.2) : (targetMinutes * 1.2);
  }
  
  double _getYInterval() {
    final maxY = _getMaxY();
    if (maxY <= 15) return 5;
    if (maxY <= 30) return 10;
    if (maxY <= 60) return 15;
    if (maxY <= 120) return 30;
    return 45;
  }
}
