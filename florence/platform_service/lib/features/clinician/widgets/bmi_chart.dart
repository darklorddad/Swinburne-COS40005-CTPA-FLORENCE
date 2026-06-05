import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:florence/features/clinician/models/health_data.dart';
import 'package:florence/features/clinician/theme/app_theme.dart';
import 'package:intl/intl.dart';

class BmiChart extends StatelessWidget {
  final List<BmiReading> readings;
  final double highThreshold;
  final double lowThreshold;
  final String filter;
  final DateTime focusedDate;

  const BmiChart({
    super.key,
    required this.readings,
    required this.filter,
    required this.focusedDate,
    this.highThreshold = 25.0, // Above target
    this.lowThreshold = 18.5, // Below target
  });

  List<BmiReading> _getAggregatedReadings() {
    if (readings.isEmpty) return [];

    if (filter == 'Hourly') {
      final Map<int, List<double>> grouped = {};
      for (var r in readings) {
        grouped.putIfAbsent(r.timestamp.hour, () => []).add(r.value);
      }
      final List<BmiReading> result = [];
      final start = DateTime(focusedDate.year, focusedDate.month, focusedDate.day);
      for (int hour = 0; hour < 24; hour++) {
        if (grouped.containsKey(hour)) {
          final avg = grouped[hour]!.reduce((a, b) => a + b) / grouped[hour]!.length;
          result.add(BmiReading(
            timestamp: DateTime(start.year, start.month, start.day, hour),
            value: avg,
            weight: 70.0,
            height: 170.0,
          ));
        }
      }
      return result;
    } else if (filter == 'Daily') {
      final Map<int, List<double>> grouped = {};
      for (var r in readings) {
        grouped.putIfAbsent(r.timestamp.weekday, () => []).add(r.value);
      }
      final List<BmiReading> result = [];
      final startOfWeek = DateTime(focusedDate.year, focusedDate.month, focusedDate.day).subtract(Duration(days: focusedDate.weekday - 1));
      for (int day = 1; day <= 7; day++) {
        if (grouped.containsKey(day)) {
          final avg = grouped[day]!.reduce((a, b) => a + b) / grouped[day]!.length;
          result.add(BmiReading(
            timestamp: startOfWeek.add(Duration(days: day - 1)),
            value: avg,
            weight: 70.0,
            height: 170.0,
          ));
        }
      }
      return result;
    } else {
      final Map<int, List<double>> grouped = {};
      for (var r in readings) {
        grouped.putIfAbsent(r.timestamp.month, () => []).add(r.value);
      }
      final List<BmiReading> result = [];
      for (int month = 1; month <= 12; month++) {
        if (grouped.containsKey(month)) {
          final avg = grouped[month]!.reduce((a, b) => a + b) / grouped[month]!.length;
          result.add(BmiReading(
            timestamp: DateTime(focusedDate.year, month, 1),
            value: avg,
            weight: 70.0,
            height: 170.0,
          ));
        }
      }
      return result;
    }
  }

  @override
  Widget build(BuildContext context) {
    final aggregatedReadings = _getAggregatedReadings();
    if (aggregatedReadings.isEmpty) {
      return const Center(child: Text('No BMI data available'));
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: LineChart(
        _bmiChartData(aggregatedReadings),
      ),
    );
  }

  LineChartData _bmiChartData(List<BmiReading> sortedReadings) {
    final minY = _getMinY(sortedReadings);
    final maxY = _getMaxY(sortedReadings);
    final range = maxY - minY;
    
    // Calculate dynamic interval to prevent overlapping labels
    double interval = 5.0;
    if (range <= 5) {
      interval = 1.0;
    } else if (range <= 10) {
      interval = 2.0;
    } else if (range <= 20) {
      interval = 5.0;
    } else {
      interval = 10.0;
    }
    
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: interval,
        getDrawingHorizontalLine: (value) {
          if (value == highThreshold || value == lowThreshold) {
            return FlLine(
            color: value == highThreshold
                ? AppTheme.mediumRiskColor.withValues(alpha: 0.5)
                : AppTheme.primaryColor.withValues(alpha: 0.5),
              strokeWidth: 1,
              dashArray: [4, 4],
            );
          }
          return FlLine(
            color: Colors.grey[200]!,
            strokeWidth: 1,
          );
        },
        getDrawingVerticalLine: (value) => FlLine(
          color: Colors.transparent,
          strokeWidth: 0, 
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 44,
            interval: 1,
            getTitlesWidget: (value, meta) {
              if (value < 0 || value >= sortedReadings.length) {
                return const Text('');
              }
              
              final index = value.toInt();
              if (index >= 0 && index < sortedReadings.length) {
                final date = sortedReadings[index].timestamp;
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
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 10, height: 1.1, color: AppTheme.textSecondary),
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
            interval: interval,
            getTitlesWidget: (value, meta) {
              return Text(
                interval < 2.0 ? value.toStringAsFixed(1) : value.toInt().toString(),
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 10,
                ),
              );
            },
            reservedSize: 35,
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
          left: BorderSide(color: Colors.grey[300]!),
          right: const BorderSide(color: Colors.transparent),
          top: const BorderSide(color: Colors.transparent),
        ),
      ),
      minX: 0,
      maxX: sortedReadings.length - 1 > 0 ? (sortedReadings.length - 1).toDouble() : 1.0,
      minY: minY,
      maxY: maxY,
      rangeAnnotations: RangeAnnotations(
        horizontalRangeAnnotations: [
          HorizontalRangeAnnotation(
            y1: lowThreshold,
            y2: highThreshold,
            color: AppTheme.lowRiskColor.withValues(alpha: 0.1),
          ),
        ],
      ),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          tooltipBorder: const BorderSide(color: AppTheme.primaryColor),
          getTooltipItems: (List<LineBarSpot> lineBarsSpot) {
            return lineBarsSpot.map((lineBarSpot) {
              final index = lineBarSpot.x.toInt();
              if (index >= 0 && index < sortedReadings.length) {
                final reading = sortedReadings[index];
                return LineTooltipItem(
                  '${reading.value.toStringAsFixed(1)} kg/m²\n',
                  const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  children: [
                    TextSpan(
                      text: DateFormat('dd/MM/yy HH:mm').format(reading.timestamp),
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                  ],
                );
              }
              return null;
            }).toList();
          },
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: List.generate(
            sortedReadings.length,
            (index) => FlSpot(index.toDouble(), sortedReadings[index].value),
          ),
          isCurved: false,
          color: AppTheme.primaryColor,
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: AppTheme.primaryColor,
                strokeWidth: 1.5,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(show: false),
        ),
      ],
    );
  }

  double _getMinY(List<BmiReading> sortedReadings) {
    if (sortedReadings.isEmpty) return 0;
    double minVal = sortedReadings.map((r) => r.value).reduce((a, b) => a < b ? a : b);
    if (lowThreshold < minVal) {
      minVal = lowThreshold;
    }
    return minVal > 10 ? (minVal - 2).floorToDouble() : 0;
  }

  double _getMaxY(List<BmiReading> sortedReadings) {
    if (sortedReadings.isEmpty) return 40;
    double maxVal = sortedReadings.map((r) => r.value).reduce((a, b) => a > b ? a : b);
    if (highThreshold > maxVal) {
      maxVal = highThreshold;
    }
    return (maxVal + 2).ceilToDouble();
  }
}
