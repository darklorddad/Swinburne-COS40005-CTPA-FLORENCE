import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../config/theme.dart';
import '../../core/models/health_data_models.dart';
import '../../dashboard/providers/dashboard_providers.dart';

class BloodPressureDetailScreen extends ConsumerWidget {
  const BloodPressureDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monitorAsync = ref.watch(monitorDataProvider);
    final thresholdsAsync = ref.watch(patientThresholdsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Blood Pressure Analytics'),
        elevation: 0,
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
          // 1. Pair Systolic and Diastolic readings based on timestamp
          final readings = _pairReadings(dataList);
          
          if (readings.isEmpty) {
            return const Center(child: Text('No blood pressure data available'));
          }

          // Sort by date ascending
          readings.sort((a, b) => a.timestamp.compareTo(b.timestamp));

          // Get Thresholds (Default to standard medical guidelines if not set)
          final thresholds = thresholdsAsync.value ?? [];
          final sysThreshold = thresholds.firstWhere(
            (t) => t.dataType == MonitorDataType.BLOOD_PRESSURE_SYSTOLIC,
            orElse: () => const HealthThreshold(dataType: MonitorDataType.BLOOD_PRESSURE_SYSTOLIC, minValue: 90, maxValue: 120),
          );
          final diaThreshold = thresholds.firstWhere(
            (t) => t.dataType == MonitorDataType.BLOOD_PRESSURE_DIASTOLIC,
            orElse: () => const HealthThreshold(dataType: MonitorDataType.BLOOD_PRESSURE_DIASTOLIC, minValue: 60, maxValue: 80),
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // 1. Statistics
                _StatisticsSection(readings: readings),
                const SizedBox(height: 20),

                // 2. Dual Trend Chart
                _DualTrendChart(
                  readings: readings,
                  sysThreshold: sysThreshold,
                  diaThreshold: diaThreshold,
                ),
                const SizedBox(height: 20),

                // 3. Floating Bar (Pulse Pressure / Daily Range)
                _FloatingBarChart(readings: readings),
                const SizedBox(height: 20),

                // 4. Scatter Plot
                _ScatterBPChart(
                  readings: readings,
                  sysThreshold: sysThreshold,
                  diaThreshold: diaThreshold,
                ),
                const SizedBox(height: 20),

                // 5. History List
                _HistorySection(readings: readings),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  List<_BpReading> _pairReadings(List<MonitorData> data) {
    final Map<String, double> sysMap = {};
    final Map<String, double> diaMap = {};
    final Map<String, DateTime> timeMap = {};

    for (var d in data) {
      // Key by timestamp ISO string to pair readings logged together
      final key = d.measuredAt.toIso8601String(); 
      
      if (d.dataType == MonitorDataType.BLOOD_PRESSURE_SYSTOLIC) {
        sysMap[key] = d.value;
        timeMap[key] = d.measuredAt;
      } else if (d.dataType == MonitorDataType.BLOOD_PRESSURE_DIASTOLIC) {
        diaMap[key] = d.value;
        timeMap[key] = d.measuredAt;
      }
    }

    final List<_BpReading> paired = [];
    sysMap.forEach((key, sys) {
      if (diaMap.containsKey(key)) {
        paired.add(_BpReading(timeMap[key]!, sys, diaMap[key]!));
      }
    });

    return paired;
  }
}

class _BpReading {
  final DateTime timestamp;
  final double systolic;
  final double diastolic;
  _BpReading(this.timestamp, this.systolic, this.diastolic);
  
  double get pulsePressure => systolic - diastolic;
}

// ============================================================================
// SECTIONS
// ============================================================================

class _StatisticsSection extends StatelessWidget {
  final List<_BpReading> readings;

  const _StatisticsSection({required this.readings});

  @override
  Widget build(BuildContext context) {
    final avgSys = readings.map((e) => e.systolic).reduce((a, b) => a + b) / readings.length;
    final avgDia = readings.map((e) => e.diastolic).reduce((a, b) => a + b) / readings.length;
    final avgPulse = readings.map((e) => e.pulsePressure).reduce((a, b) => a + b) / readings.length;

    return _ChartContainer(
      title: 'Overview',
      icon: Icons.analytics_outlined,
      child: Row(
        children: [
          Expanded(child: _buildStatBox(context, 'Avg Systolic', avgSys.toStringAsFixed(0), 'mmHg', AppTheme.primaryRed)),
          const SizedBox(width: 12),
          Expanded(child: _buildStatBox(context, 'Avg Diastolic', avgDia.toStringAsFixed(0), 'mmHg', AppTheme.primaryBlue)),
          const SizedBox(width: 12),
          Expanded(child: _buildStatBox(context, 'Pulse Pressure', avgPulse.toStringAsFixed(0), 'mmHg', AppTheme.textSecondaryColor)),
        ],
      ),
    );
  }

  Widget _buildStatBox(BuildContext context, String title, String value, String unit, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(width: 2),
              Text(unit, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 9)),
            ],
          ),
        ],
      ),
    );
  }
}

class _DualTrendChart extends StatelessWidget {
  final List<_BpReading> readings;
  final HealthThreshold sysThreshold;
  final HealthThreshold diaThreshold;

  const _DualTrendChart({required this.readings, required this.sysThreshold, required this.diaThreshold});

  @override
  Widget build(BuildContext context) {
    double minX = readings.first.timestamp.millisecondsSinceEpoch.toDouble();
    double maxX = readings.last.timestamp.millisecondsSinceEpoch.toDouble();
    if (minX == maxX) { minX -= 3600000; maxX += 3600000; } 

    return _ChartContainer(
      title: 'Pressure Trends',
      icon: Icons.show_chart,
      child: Column(
        children: [
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                minX: minX, maxX: maxX, minY: 40, maxY: 180,
                gridData: FlGridData(
                  show: true, 
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(color: AppTheme.getBorderColor(context).withOpacity(0.2), strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 35, interval: 40, getTitlesWidget: (v, _) => Text(v.toInt().toString(), style: const TextStyle(fontSize: 10)))),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: (maxX - minX) / 4, getTitlesWidget: (v, _) {
                    final date = DateTime.fromMillisecondsSinceEpoch(v.toInt());
                    return Padding(padding: const EdgeInsets.only(top: 8), child: Text(DateFormat('MM/dd').format(date), style: const TextStyle(fontSize: 10)));
                  })),
                ),
                borderData: FlBorderData(show: true, border: Border.all(color: AppTheme.getBorderColor(context).withOpacity(0.5))),
                // Safe Zones
                rangeAnnotations: RangeAnnotations(
                  horizontalRangeAnnotations: [
                    HorizontalRangeAnnotation(y1: sysThreshold.minValue, y2: sysThreshold.maxValue, color: AppTheme.primaryRed.withOpacity(0.05)),
                    HorizontalRangeAnnotation(y1: diaThreshold.minValue, y2: diaThreshold.maxValue, color: AppTheme.primaryBlue.withOpacity(0.05)),
                  ]
                ),
                lineBarsData: [
                  // Systolic Line
                  LineChartBarData(
                    spots: readings.map((r) => FlSpot(r.timestamp.millisecondsSinceEpoch.toDouble(), r.systolic)).toList(),
                    color: AppTheme.primaryRed, barWidth: 2, isCurved: true,
                    dotData: const FlDotData(show: false),
                  ),
                  // Diastolic Line
                  LineChartBarData(
                    spots: readings.map((r) => FlSpot(r.timestamp.millisecondsSinceEpoch.toDouble(), r.diastolic)).toList(),
                    color: AppTheme.primaryBlue, barWidth: 2, isCurved: true,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
             _LegendItem('Systolic', AppTheme.primaryRed),
             const SizedBox(width: 16),
             _LegendItem('Diastolic', AppTheme.primaryBlue),
          ]),
        ],
      ),
    );
  }
}

class _FloatingBarChart extends StatelessWidget {
  final List<_BpReading> readings;

  const _FloatingBarChart({required this.readings});

  @override
  Widget build(BuildContext context) {
    final recent = readings.length > 10 ? readings.sublist(readings.length - 10) : readings;

    return _ChartContainer(
      title: 'Pressure Range (Sys-Dia)',
      icon: Icons.bar_chart,
      child: SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: 180, minY: 40,
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, interval: 40, getTitlesWidget: (v, _) => Text(v.toInt().toString(), style: const TextStyle(fontSize: 10)))),
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
                if (v.toInt() >= recent.length) return const SizedBox();
                return Padding(padding: const EdgeInsets.only(top: 8), child: Text(DateFormat('d/M').format(recent[v.toInt()].timestamp), style: const TextStyle(fontSize: 10)));
              })),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: AppTheme.getBorderColor(context).withOpacity(0.2), strokeWidth: 1)),
            borderData: FlBorderData(show: false),
            barGroups: recent.asMap().entries.map((entry) {
              final r = entry.value;
              return BarChartGroupData(
                x: entry.key,
                barRods: [
                  BarChartRodData(
                    toY: r.systolic,
                    fromY: r.diastolic,
                    color: AppTheme.primaryBlue.withOpacity(0.6),
                    width: 12,
                    borderRadius: BorderRadius.circular(4),
                  )
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _ScatterBPChart extends StatelessWidget {
  final List<_BpReading> readings;
  final HealthThreshold sysThreshold;
  final HealthThreshold diaThreshold;

  const _ScatterBPChart({required this.readings, required this.sysThreshold, required this.diaThreshold});

  @override
  Widget build(BuildContext context) {
    return _ChartContainer(
      title: 'Systolic vs. Diastolic',
      icon: Icons.bubble_chart_outlined,
      child: Column(
        children: [
          SizedBox(
            height: 250,
            child: ScatterChart(
              ScatterChartData(
                scatterSpots: readings.map((r) {
                  bool isHigh = r.systolic > sysThreshold.maxValue || r.diastolic > diaThreshold.maxValue;
                  return ScatterSpot(
                    r.diastolic, 
                    r.systolic,
                    dotPainter: FlDotCirclePainter(
                      color: isHigh ? AppTheme.errorColor : AppTheme.primaryGreen,
                      radius: 6,
                      strokeWidth: 0,
                    ),
                  );
                }).toList(),
                minX: 40, maxX: 130,
                minY: 80, maxY: 200,
                gridData: FlGridData(show: true, getDrawingHorizontalLine: (_) => FlLine(color: AppTheme.getBorderColor(context).withOpacity(0.2), strokeWidth: 1), getDrawingVerticalLine: (_) => FlLine(color: AppTheme.getBorderColor(context).withOpacity(0.2), strokeWidth: 1)),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(axisNameWidget: const Text('Diastolic', style: TextStyle(fontSize: 10)), axisNameSize: 20, sideTitles: SideTitles(showTitles: true, interval: 20)),
                  leftTitles: AxisTitles(axisNameWidget: const Text('Systolic', style: TextStyle(fontSize: 10)), axisNameSize: 20, sideTitles: SideTitles(showTitles: true, interval: 20)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: true, border: Border.all(color: AppTheme.getBorderColor(context).withOpacity(0.5))),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
             _LegendItem('Normal', AppTheme.primaryGreen, isCircle: true),
             const SizedBox(width: 16),
             _LegendItem('High', AppTheme.errorColor, isCircle: true),
          ]),
        ],
      ),
    );
  }
}

class _HistorySection extends StatelessWidget {
  final List<_BpReading> readings;
  const _HistorySection({required this.readings});

  @override
  Widget build(BuildContext context) {
    final reversed = readings.reversed.toList();
    
    return _ChartContainer(
      title: 'History',
      icon: Icons.history,
      child: Column(
        children: reversed.take(10).map((r) {
           final isHigh = r.systolic > 130 || r.diastolic > 85;
           return Container(
             margin: const EdgeInsets.only(bottom: 12),
             padding: const EdgeInsets.symmetric(vertical: 8),
             decoration: BoxDecoration(
               border: Border(bottom: BorderSide(color: AppTheme.getBorderColor(context).withOpacity(0.5)))
             ),
             child: Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 Text(DateFormat('MMM d, h:mm a').format(r.timestamp), style: const TextStyle(fontSize: 12)),
                 Row(
                   children: [
                     Text('${r.systolic.toInt()}/${r.diastolic.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                     const SizedBox(width: 4),
                     Text('mmHg', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10)),
                     if (isHigh) ...[
                       const SizedBox(width: 8),
                       const Icon(Icons.warning_amber, color: AppTheme.warningColor, size: 16)
                     ]
                   ],
                 )
               ],
             ),
           );
        }).toList(),
      ),
    );
  }
}

// --- Shared UI Components ---

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppTheme.primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: AppTheme.primaryBlue, size: 24),
              ),
              const SizedBox(width: 12),
              Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
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
  final bool isCircle;
  const _LegendItem(this.label, this.color, {this.isCircle = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(color: color, shape: isCircle ? BoxShape.circle : BoxShape.rectangle, borderRadius: isCircle ? null : BorderRadius.circular(2)),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}
