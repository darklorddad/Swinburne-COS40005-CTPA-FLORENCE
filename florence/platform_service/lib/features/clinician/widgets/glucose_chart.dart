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

  const GlucoseChart({
    super.key,
    required this.readings,
    required this.unit,
    this.hbA1cReadings = const [],
    this.highThreshold = 180.0,
    this.lowThreshold = 70.0,
  });

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty) {
      return const Center(child: Text('No glucose data available'));
    }

    // Sort readings by date
    final sortedReadings = [...readings]..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: LineChart(
        _glucoseChartData(sortedReadings),
      ),
    );
  }

  LineChartData _glucoseChartData(List<GlucoseReading> sortedReadings) {
    final bool isMmol = unit == 'mmol/L';
    
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: isMmol ? 2.0 : 50.0,
        getDrawingHorizontalLine: (value) {
          if (value == highThreshold || value == lowThreshold) {
            return FlLine(
            color: value == highThreshold
                ? AppTheme.highRiskColor.withValues(alpha: 0.5)
                : AppTheme.secondaryColor.withValues(alpha: 0.5),
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
              if (value < 0 || value >= sortedReadings.length) {
                return const Text('');
              }
              
              // Show dates spaced evenly
              if (sortedReadings.length > 10) {
                if (value % (sortedReadings.length ~/ 5) != 0) {
                  return const Text('');
                }
              }
              
              final index = value.toInt();
              if (index >= 0 && index < sortedReadings.length) {
                final date = sortedReadings[index].timestamp;
                return Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Text(
                    DateFormat('MM/dd\nHH:mm').format(date),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 10, height: 1.1),
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
            interval: isMmol ? 2.0 : 50.0,
            getTitlesWidget: (value, meta) {
              return Text(
                isMmol ? value.toStringAsFixed(1) : value.toInt().toString(),
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
          right: BorderSide(color: Colors.transparent),
          top: BorderSide(color: Colors.transparent),
        ),
      ),
      minX: 0,
      maxX: sortedReadings.length - 1,
      minY: _getMinY(),
      maxY: _getMaxY(),
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
                  '${reading.value} $unit\n',
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
            return FlSpot(
              index.toDouble(),
              sortedReadings[index].value,
            );
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
                dotColor = AppTheme.secondaryColor;
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
            color: AppTheme.secondaryColor,
            strokeWidth: 1,
            dashArray: [5, 5],
            label: HorizontalLineLabel(
              show: true,
              alignment: Alignment.bottomRight,
              padding: const EdgeInsets.only(right: 5, top: 5),
              style: const TextStyle(
                color: AppTheme.secondaryColor,
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

  double _getMinY() {
    if (readings.isEmpty) return 0;
    
    double minValue = readings.map((e) => e.value).reduce((a, b) => a < b ? a : b);
    double limit = (minValue < lowThreshold ? minValue : lowThreshold);
    return limit * 0.85;
  }

  double _getMaxY() {
    if (readings.isEmpty) return unit == 'mmol/L' ? 15 : 300;
    
    double maxValue = readings.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    double limit = (maxValue > highThreshold ? maxValue : highThreshold);
    return limit * 1.15;
  }
}
