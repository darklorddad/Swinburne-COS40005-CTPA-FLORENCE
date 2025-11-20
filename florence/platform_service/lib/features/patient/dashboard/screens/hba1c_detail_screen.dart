import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../../../../config/theme.dart';
import '../../core/models/health_data_models.dart';
import '../../dashboard/providers/dashboard_providers.dart';

class HbA1cDetailScreen extends ConsumerWidget {
  const HbA1cDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monitorAsync = ref.watch(monitorDataProvider);
    final thresholdsAsync = ref.watch(patientThresholdsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('HbA1c Analytics'),
        elevation: 0,
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: AppTheme.getBorderColor(context),
            height: 1.0,
          ),
        ),
      ),
      body: monitorAsync.when(
        data: (dataList) {
          final readings = dataList
              .where((d) => d.dataType == MonitorDataType.HBA1C)
              .toList();
          
          // Sort by date ascending
          readings.sort((a, b) => a.measuredAt.compareTo(b.measuredAt));

          final thresholds = thresholdsAsync.value ?? [];
          HealthThreshold? userThreshold;
          try {
            userThreshold = thresholds.firstWhere((t) => t.dataType == MonitorDataType.HBA1C);
          } catch (_) {}

          // Default: Target < 6.5% or 7.0% depending on profile, defaulting to 6.5 for visualization
          final targetMax = userThreshold?.maxValue ?? 6.5;

          return RefreshIndicator(
            onRefresh: () async {
               await Future.wait([
                 ref.refresh(monitorDataProvider.future),
                 ref.refresh(patientThresholdsProvider.future),
               ]);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // 1. Gauge Chart (Speedometer)
                  _GaugeSection(
                    latestReading: readings.isNotEmpty ? readings.last : null,
                  ),
                  const SizedBox(height: 20),
                  
                  // 2. Trends (Line Chart with Reference Bands)
                  _TrendsSection(
                    readings: readings,
                    targetMax: targetMax,
                  ),
                  const SizedBox(height: 20),

                  // 3. Actual vs. Goal Bar Chart
                  _GoalComparisonSection(
                    latestReading: readings.isNotEmpty ? readings.last : null,
                    targetMax: targetMax,
                  ),
                  const SizedBox(height: 20),
                  
                  // 4. History List
                  _HistorySection(readings: readings),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

// ============================================================================
// 1. GAUGE CHART (Speedometer)
// ============================================================================

class _GaugeSection extends StatelessWidget {
  final MonitorData? latestReading;

  const _GaugeSection({this.latestReading});

  @override
  Widget build(BuildContext context) {
    final val = latestReading?.value ?? 0.0;
    
    // Define Ranges
    const double minScale = 4.0;
    const double maxScale = 12.0;
    
    // Normalize value for needle position (0 to 1)
    double normalized = (val - minScale) / (maxScale - minScale);
    normalized = normalized.clamp(0.0, 1.0);
    
    // Angle mapping: 0.0 -> 180 deg, 1.0 -> 0 deg (Semi-circle)
    final double angle = 180 - (normalized * 180);

    Color statusColor;
    String statusText;
    if (val < 5.7) {
      statusColor = AppTheme.primaryGreen;
      statusText = "Normal";
    } else if (val < 6.5) {
      statusColor = AppTheme.warningColor;
      statusText = "Pre-diabetes";
    } else {
      statusColor = AppTheme.errorColor;
      statusText = "Diabetes";
    }

    if (latestReading == null) {
      statusText = "No Data";
      statusColor = AppTheme.textSecondaryColor;
    }

    return _ChartContainer(
      title: 'Current Status',
      icon: Icons.speed,
      child: Column(
        children: [
          SizedBox(
            height: 150, // Half circle height
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                PieChart(
                  PieChartData(
                    startDegreeOffset: 180,
                    sectionsSpace: 2,
                    centerSpaceRadius: 0, // Full pie
                    sections: [
                      // Normal (4.0 - 5.7) -> 1.7 units
                      PieChartSectionData(
                        value: 1.7,
                        color: AppTheme.primaryGreen.withOpacity(0.8),
                        radius: 80,
                        showTitle: false,
                      ),
                      // Pre-diabetes (5.7 - 6.5) -> 0.8 units
                      PieChartSectionData(
                        value: 0.8,
                        color: AppTheme.warningColor.withOpacity(0.8),
                        radius: 80,
                        showTitle: false,
                      ),
                      // Diabetes (6.5 - 12.0) -> 5.5 units
                      PieChartSectionData(
                        value: 5.5,
                        color: AppTheme.errorColor.withOpacity(0.8),
                        radius: 80,
                        showTitle: false,
                      ),
                      // Transparent bottom half to make it a semi-circle
                      PieChartSectionData(
                        value: 8.0, // Sum of top parts
                        color: Colors.transparent,
                        radius: 80,
                        showTitle: false,
                      ),
                    ],
                  ),
                ),
                // Needle
                if (latestReading != null)
                  Transform.translate(
                    offset: const Offset(0, 15), // Adjust pivot
                    child: Transform.rotate(
                      angle: -math.pi * (normalized), // Radians
                      alignment: Alignment.bottomCenter,
                      child: Container(
                         width: 4,
                         height: 90,
                         alignment: Alignment.topCenter,
                         child: Container(
                           width: 4,
                           height: 90, // Needle length
                           decoration: BoxDecoration(
                             color: AppTheme.textPrimaryColor,
                             borderRadius: BorderRadius.circular(2),
                           ),
                         ),
                      ),
                    ),
                  ),
                // Center Knob
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppTheme.textPrimaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            val > 0 ? '${val.toStringAsFixed(1)}%' : '--',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statusText.toUpperCase(),
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 2. TRENDS (Line Chart with Reference Bands)
// ============================================================================

class _TrendsSection extends StatelessWidget {
  final List<MonitorData> readings;
  final double targetMax;

  const _TrendsSection({required this.readings, required this.targetMax});

  @override
  Widget build(BuildContext context) {
    // X-Axis logic
    double minX = 0, maxX = 1;
    if (readings.isNotEmpty) {
      minX = readings.first.measuredAt.millisecondsSinceEpoch.toDouble();
      maxX = readings.last.measuredAt.millisecondsSinceEpoch.toDouble();
      // Add padding if only one point
      if (minX == maxX) {
        minX -= 2629743000; // -1 month approx
        maxX += 2629743000; // +1 month approx
      }
    } else {
       final now = DateTime.now();
       minX = now.subtract(const Duration(days: 90)).millisecondsSinceEpoch.toDouble();
       maxX = now.millisecondsSinceEpoch.toDouble();
    }

    return _ChartContainer(
      title: 'HbA1c Trends',
      icon: Icons.show_chart,
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minX: minX, maxX: maxX, minY: 4, maxY: 10, // Standard HbA1c range
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (_) => FlLine(color: AppTheme.getBorderColor(context).withOpacity(0.2), strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: (maxX - minX) / 3,
                      getTitlesWidget: (val, _) {
                        if (val == minX || val == maxX) return const SizedBox();
                        final date = DateTime.fromMillisecondsSinceEpoch(val.toInt());
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(DateFormat('MMM y').format(date), style: const TextStyle(fontSize: 10)),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: true, border: Border.all(color: AppTheme.getBorderColor(context).withOpacity(0.5))),
                // Reference Bands
                rangeAnnotations: RangeAnnotations(
                  horizontalRangeAnnotations: [
                    // Healthy Zone (< 5.7)
                    HorizontalRangeAnnotation(y1: 4, y2: 5.7, color: AppTheme.primaryGreen.withOpacity(0.1)),
                    // Pre-Diabetes Zone (5.7 - 6.5)
                    HorizontalRangeAnnotation(y1: 5.7, y2: 6.5, color: AppTheme.warningColor.withOpacity(0.05)),
                    // Diabetes Zone (> 6.5) - visually up to 10
                    HorizontalRangeAnnotation(y1: 6.5, y2: 12, color: AppTheme.errorColor.withOpacity(0.05)),
                  ],
                ),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                     HorizontalLine(y: targetMax, color: AppTheme.primaryBlue, strokeWidth: 1, dashArray: [5,5], label: HorizontalLineLabel(show: true, alignment: Alignment.topRight, padding: const EdgeInsets.only(right: 5, bottom: 2), style: TextStyle(color: AppTheme.primaryBlue, fontSize: 9, fontWeight: FontWeight.bold), labelResolver: (line) => 'Target'))
                  ]
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: readings.map((r) => FlSpot(r.measuredAt.millisecondsSinceEpoch.toDouble(), r.value)).toList(),
                    isCurved: true,
                    color: AppTheme.primaryBlue,
                    barWidth: 3,
                    dotData: FlDotData(show: true, getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(radius: 4, color: AppTheme.primaryBlue, strokeColor: Colors.white, strokeWidth: 2)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            children: [
              _LegendItem('Normal', AppTheme.primaryGreen),
              _LegendItem('Elevated', AppTheme.warningColor),
              _LegendItem('High', AppTheme.errorColor),
            ],
          )
        ],
      ),
    );
  }
}

// ============================================================================
// 3. ACTUAL VS GOAL (Bar Chart)
// ============================================================================

class _GoalComparisonSection extends StatelessWidget {
  final MonitorData? latestReading;
  final double targetMax;

  const _GoalComparisonSection({this.latestReading, required this.targetMax});

  @override
  Widget build(BuildContext context) {
    final current = latestReading?.value ?? 0.0;
    final isGood = current <= targetMax;
    final barColor = isGood ? AppTheme.primaryGreen : AppTheme.errorColor;

    return _ChartContainer(
      title: 'Actual vs. Goal',
      icon: Icons.flag_outlined,
      child: Column(
        children: [
          SizedBox(
            height: 150,
            child: BarChart(
              BarChartData(
                maxY: math.max(current, targetMax) + 2,
                minY: 0,
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, _) {
                         switch(val.toInt()) {
                           case 0: return const Padding(padding: EdgeInsets.only(top: 8), child: Text('You', style: TextStyle(fontWeight: FontWeight.bold)));
                           case 1: return const Padding(padding: EdgeInsets.only(top: 8), child: Text('Target', style: TextStyle(fontWeight: FontWeight.bold)));
                           default: return const SizedBox();
                         }
                      }
                    )
                  )
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  // Actual
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: current,
                        color: barColor,
                        width: 40,
                        borderRadius: BorderRadius.circular(4),
                        backDrawRodData: BackgroundBarChartRodData(show: true, toY: 10, color: AppTheme.backgroundColor),
                      ),
                    ],
                    showingTooltipIndicators: [0],
                  ),
                  // Goal
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: targetMax,
                        color: AppTheme.textSecondaryColor.withOpacity(0.5),
                        width: 40,
                        borderRadius: BorderRadius.circular(4),
                        backDrawRodData: BackgroundBarChartRodData(show: true, toY: 10, color: AppTheme.backgroundColor),
                      ),
                    ],
                    showingTooltipIndicators: [0],
                  ),
                ],
                barTouchData: BarTouchData(
                  enabled: false,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => Colors.transparent,
                    tooltipPadding: EdgeInsets.zero,
                    tooltipMargin: 4,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        rod.toY.toStringAsFixed(1),
                        TextStyle(
                          color: group.x == 0 ? barColor : AppTheme.textSecondaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (latestReading != null)
            Text(
              isGood 
                ? "Great! You're under your target of ${targetMax.toStringAsFixed(1)}%"
                : "You're ${(current - targetMax).toStringAsFixed(1)}% above target",
              style: TextStyle(
                color: barColor,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// 4. HISTORY LIST
// ============================================================================

class _HistorySection extends StatelessWidget {
  final List<MonitorData> readings;

  const _HistorySection({required this.readings});

  @override
  Widget build(BuildContext context) {
    final reversed = readings.reversed.toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerColor = isDark ? AppTheme.midnightSurface : Colors.white;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.getBorderColor(context)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppTheme.primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.history, color: AppTheme.primaryBlue, size: 24),
              ),
              const SizedBox(width: 12),
              Text('History', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          if (readings.isEmpty)
            const Padding(padding: EdgeInsets.all(16), child: Text('No records found')),
          
          ...reversed.map((r) {
             Color color = r.value < 5.7 ? AppTheme.primaryGreen : (r.value < 6.5 ? AppTheme.warningColor : AppTheme.errorColor);
             return Container(
               margin: const EdgeInsets.only(bottom: 12),
               padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
               decoration: BoxDecoration(
                 color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
                 borderRadius: BorderRadius.circular(12),
                 border: Border.all(color: color.withOpacity(0.3)),
               ),
               child: Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   Text(DateFormat('MMM d, yyyy').format(r.measuredAt), style: const TextStyle(fontWeight: FontWeight.w500)),
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                     decoration: BoxDecoration(
                       color: color.withOpacity(0.1),
                       borderRadius: BorderRadius.circular(12),
                     ),
                     child: Text('${r.value.toStringAsFixed(1)}%', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                   ),
                 ],
               ),
             );
          }),
        ],
      ),
    );
  }
}

// Helpers
class _ChartContainer extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _ChartContainer({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.midnightSurface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.getBorderColor(context)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.textSecondaryColor),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;
  const _LegendItem(this.label, this.color);
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
