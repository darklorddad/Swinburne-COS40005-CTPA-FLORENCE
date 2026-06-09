import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:florence/features/clinician/models/health_data.dart';
import 'package:florence/features/clinician/theme/app_theme.dart';
import 'package:intl/intl.dart';

class GlucoseChart extends StatelessWidget {
  final List<GlucoseReading> readings;
  final List<HbA1cReading> hbA1cReadings;
  final double highThreshold;
  final double lowThreshold;
  final String unit;
  final String filter;
  final DateTime focusedDate;

  const GlucoseChart({
    super.key,
    required this.readings,
    required this.unit,
    required this.filter,
    required this.focusedDate,
    this.hbA1cReadings = const [],
    this.highThreshold = 180.0,
    this.lowThreshold = 70.0,
  });

  List<GlucoseReading> _getAggregatedReadings() {
    if (readings.isEmpty) return [];

    if (filter == 'Hourly') {
      final Map<int, List<double>> grouped = {};
      for (var r in readings) {
        grouped.putIfAbsent(r.timestamp.hour, () => []).add(r.value);
      }
      final List<GlucoseReading> result = [];
      final start = DateTime(focusedDate.year, focusedDate.month, focusedDate.day);
      for (int hour = 0; hour < 24; hour++) {
        if (grouped.containsKey(hour)) {
          final avg = grouped[hour]!.reduce((a, b) => a + b) / grouped[hour]!.length;
          result.add(GlucoseReading(
            timestamp: DateTime(start.year, start.month, start.day, hour),
            value: avg,
            context: 'Hourly Average',
          ));
        }
      }
      return result;
    } else if (filter == 'Daily') {
      final Map<int, List<double>> grouped = {};
      for (var r in readings) {
        grouped.putIfAbsent(r.timestamp.weekday, () => []).add(r.value);
      }
      final List<GlucoseReading> result = [];
      final startOfWeek = DateTime(focusedDate.year, focusedDate.month, focusedDate.day).subtract(Duration(days: focusedDate.weekday - 1));
      for (int day = 1; day <= 7; day++) {
        if (grouped.containsKey(day)) {
          final avg = grouped[day]!.reduce((a, b) => a + b) / grouped[day]!.length;
          result.add(GlucoseReading(
            timestamp: startOfWeek.add(Duration(days: day - 1)),
            value: avg,
            context: 'Daily Average',
          ));
        }
      }
      return result;
    } else {
      final Map<int, List<double>> grouped = {};
      for (var r in readings) {
        grouped.putIfAbsent(r.timestamp.month, () => []).add(r.value);
      }
      final List<GlucoseReading> result = [];
      for (int month = 1; month <= 12; month++) {
        if (grouped.containsKey(month)) {
          final avg = grouped[month]!.reduce((a, b) => a + b) / grouped[month]!.length;
          result.add(GlucoseReading(
            timestamp: DateTime(focusedDate.year, month, 1),
            value: avg,
            context: 'Monthly Average',
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
      return const Center(child: Text('No glucose data available'));
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: LineChart(
        _glucoseChartData(aggregatedReadings),
      ),
    );
  }

  LineChartData _glucoseChartData(List<GlucoseReading> sortedReadings) {
    final minY = _getMinY(sortedReadings);
    final maxY = _getMaxY(sortedReadings);
    final range = maxY - minY;
    
    // Calculate dynamic interval to prevent overlapping labels
    double interval = 50.0;
    if (range <= 15) {
      interval = 2.0;
    } else if (range <= 30) {
      interval = 5.0;
    } else if (range <= 60) {
      interval = 10.0;
    } else if (range <= 150) {
      interval = 25.0;
    } else if (range <= 300) {
      interval = 50.0;
    } else {
      interval = 100.0;
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
                ? AppTheme.highRiskColor.withValues(alpha: 0.5)
                : AppTheme.primaryColor.withValues(alpha: 0.5),
              strokeWidth: 1,
              dashArray: [4, 4], // Tighter dash
            );
          }
          return FlLine(
            color: Colors.grey[200]!, // Lighter grid lines
            strokeWidth: 1,
          );
        },
        getDrawingVerticalLine: (value) => FlLine(
          color: Colors.transparent, // Hide vertical grid lines for cleaner look
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
              final index = value.toInt();
              if (index < 0) return const Text('');
              
              String label = '';
              if (filter == 'Hourly') {
                if (index % 4 == 0 && index < 24) {
                  label = '${index.toString().padLeft(2, '0')}:00';
                }
              } else if (filter == 'Daily') {
                if (index >= 0 && index < 7) {
                  final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                  label = weekdays[index];
                }
              } else {
                if (index >= 0 && index < 12) {
                  final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                  label = months[index];
                }
              }
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 10, height: 1.1, color: AppTheme.textSecondary),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: interval,
            getTitlesWidget: (value, meta) {
              return Text(
                interval < 5.0 ? value.toStringAsFixed(1) : value.toInt().toString(),
                style: const TextStyle(
                  color: Colors.grey,
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
      maxX: filter == 'Hourly' ? 23 : (filter == 'Daily' ? 6 : 11),
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
              final xVal = lineBarSpot.x.toInt();
              GlucoseReading? reading;
              for (var r in sortedReadings) {
                int rX = 0;
                if (filter == 'Hourly') {
                  rX = r.timestamp.hour;
                } else if (filter == 'Daily') {
                  rX = r.timestamp.weekday - 1;
                } else {
                  rX = r.timestamp.month - 1;
                }
                if (rX == xVal) {
                  reading = r;
                  break;
                }
              }
              if (reading != null) {
                return LineTooltipItem(
                  '${reading.value.toStringAsFixed(1)} $unit\n',
                  const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  children: [
                    TextSpan(
                      text: DateFormat('MMM d, h:mm a').format(reading.timestamp),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                    TextSpan(
                      text: '\n${reading.context}',
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
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
        // Main glucose line
        LineChartBarData(
          spots: List.generate(sortedReadings.length, (index) {
            final r = sortedReadings[index];
            double x = 0;
            if (filter == 'Hourly') {
              x = r.timestamp.hour.toDouble();
            } else if (filter == 'Daily') {
              x = (r.timestamp.weekday - 1).toDouble();
            } else {
              x = (r.timestamp.month - 1).toDouble();
            }
            return FlSpot(x, r.value);
          }),
          isCurved: true,
          gradient: LinearGradient(
            colors: [AppTheme.lowRiskColor.withValues(alpha: 0.5), AppTheme.lowRiskColor],
          ),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              final reading = sortedReadings[index];
              Color dotColor = AppTheme.primaryColor;
              
              // Color the dot based on the glucose level
              if (reading.value >= highThreshold) {
                dotColor = AppTheme.highRiskColor;
              } else if (reading.value <= lowThreshold) {
                dotColor = AppTheme.primaryColor;
              }
              
              return FlDotCirclePainter(
                radius: 4,
                color: Colors.white,
                strokeWidth: 2,
                strokeColor: dotColor,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                AppTheme.lowRiskColor.withValues(alpha: 0.2),
                AppTheme.lowRiskColor.withValues(alpha: 0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        
        // HbA1c markers (if available)
        if (hbA1cReadings.isNotEmpty)
          LineChartBarData(
            spots: _getHbA1cSpots(sortedReadings),
            isCurved: false,
            color: Colors.red,
            barWidth: 0,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotSquarePainter(
                  size: 8,
                  color: Colors.red.withValues(alpha: 0.8),
                );
              },
            ),
          ),
      ],
      // Add extra horizontal lines for high and low thresholds
      extraLinesData: ExtraLinesData(
        horizontalLines: [
          HorizontalLine(
            y: highThreshold,
            color: AppTheme.highRiskColor,
            strokeWidth: 1,
            dashArray: [5, 5],
            label: HorizontalLineLabel(
              show: true,
              alignment: Alignment.topRight,
              padding: const EdgeInsets.only(right: 5, bottom: 5),
              style: const TextStyle(
                color: AppTheme.highRiskColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              labelResolver: (_) => 'High',
            ),
          ),
          HorizontalLine(
            y: lowThreshold,
            color: AppTheme.primaryColor,
            strokeWidth: 1,
            dashArray: [5, 5],
            label: HorizontalLineLabel(
              show: true,
              alignment: Alignment.bottomRight,
              padding: const EdgeInsets.only(right: 5, top: 5),
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              labelResolver: (_) => 'Low',
            ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _getHbA1cSpots(List<GlucoseReading> sortedReadings) {
    final spots = <FlSpot>[];
    
    // Find closest glucose reading for each HbA1c reading
    for (final hbA1c in hbA1cReadings) {
      int closestIndex = 0;
      Duration minDifference = const Duration(days: 365);
      
      for (int i = 0; i < sortedReadings.length; i++) {
        final difference = (sortedReadings[i].timestamp.difference(hbA1c.timestamp)).abs();
        if (difference < minDifference) {
          closestIndex = i;
          minDifference = difference;
        }
      }
      
      // Only add if the reading is within a week
      if (minDifference.inDays <= 7) {
        // Convert HbA1c to average glucose estimate
        // Formula: eAG (mg/dL) = (28.7 × HbA1c) - 46.7
        final estimatedGlucose = (28.7 * hbA1c.value) - 46.7;
        spots.add(FlSpot(closestIndex.toDouble(), estimatedGlucose));
      }
    }
    
    return spots;
  }

  double _getMinY(List<GlucoseReading> sortedReadings) {
    if (sortedReadings.isEmpty) return 0;
    
    double minValue = sortedReadings.map((e) => e.value).reduce((a, b) => a < b ? a : b);
    double limit = (minValue < lowThreshold ? minValue : lowThreshold);
    return limit * 0.85;
  }

  double _getMaxY(List<GlucoseReading> sortedReadings) {
    if (sortedReadings.isEmpty) return unit == 'mmol/L' ? 15 : 300;
    
    double maxValue = sortedReadings.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    double limit = (maxValue > highThreshold ? maxValue : highThreshold);
    return limit * 1.15;
  }
}
