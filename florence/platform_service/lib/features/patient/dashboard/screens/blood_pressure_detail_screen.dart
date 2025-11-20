import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
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

          // Sort by date ascending for charts
          readings.sort((a, b) => a.timestamp.compareTo(b.timestamp));

          // Get Thresholds
          final thresholds = thresholdsAsync.value ?? [];
          
          // Check for user-defined thresholds
          HealthThreshold? userSys;
          HealthThreshold? userDia;
          try { userSys = thresholds.firstWhere((t) => t.dataType == MonitorDataType.BLOOD_PRESSURE_SYSTOLIC); } catch (_) {}
          try { userDia = thresholds.firstWhere((t) => t.dataType == MonitorDataType.BLOOD_PRESSURE_DIASTOLIC); } catch (_) {}

          final isDefault = userSys == null || userDia == null;

          final sysThreshold = userSys ?? const HealthThreshold(dataType: MonitorDataType.BLOOD_PRESSURE_SYSTOLIC, minValue: 90, maxValue: 120);
          final diaThreshold = userDia ?? const HealthThreshold(dataType: MonitorDataType.BLOOD_PRESSURE_DIASTOLIC, minValue: 60, maxValue: 80);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // 1. Statistics
                _StatisticsSection(
                  readings: readings, 
                  sysThreshold: sysThreshold, 
                  diaThreshold: diaThreshold,
                  isDefault: isDefault,
                ),
                const SizedBox(height: 20),

                // 2. Dual Trend Chart
                _DualTrendSection(
                  readings: readings,
                  sysThreshold: sysThreshold,
                  diaThreshold: diaThreshold,
                ),
                const SizedBox(height: 20),

                // 3. Floating Bar (Pulse Pressure / Daily Range)
                _FloatingBarSection(readings: readings),
                const SizedBox(height: 20),

                // 4. Scatter Plot
                _ScatterSection(
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
// REUSABLE WRAPPER
// ============================================================================

class _ChartSection extends StatefulWidget {
  final String title;
  final IconData icon;
  final String infoText;
  final Widget Function(String range, List<_BpReading> filteredData) builder;
  final List<_BpReading> allData;
  final List<String> ranges;

  const _ChartSection({
    required this.title,
    required this.icon,
    required this.infoText,
    required this.builder,
    required this.allData,
    this.ranges = const ['1D', '7D', '14D', '30D'],
  });

  @override
  State<_ChartSection> createState() => _ChartSectionState();
}

class _ChartSectionState extends State<_ChartSection> {
  late String _selectedRange;

  @override
  void initState() {
    super.initState();
    _selectedRange = widget.ranges.contains('7D') ? '7D' : widget.ranges.first;
  }

  List<_BpReading> _filterData() {
    if (widget.allData.isEmpty) return [];
    final now = DateTime.now();
    Duration duration;
    switch (_selectedRange) {
      case '7D': duration = const Duration(days: 7); break;
      case '14D': duration = const Duration(days: 14); break;
      case '30D': duration = const Duration(days: 30); break;
      case '1D':
      default: duration = const Duration(hours: 24); break;
    }
    final cutoff = now.subtract(duration);
    return widget.allData.where((d) => d.timestamp.isAfter(cutoff)).toList();
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(children: [Icon(widget.icon, color: AppTheme.primaryBlue), const SizedBox(width: 12), Expanded(child: Text(widget.title))]),
        content: Text(widget.infoText),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Got it'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerColor = isDark ? AppTheme.midnightSurface : Colors.white;
    final borderColor = AppTheme.getBorderColor(context);
    final filteredData = _filterData();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppTheme.primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(widget.icon, color: AppTheme.primaryBlue, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(widget.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))),
              IconButton(icon: Icon(Icons.info_outline, color: AppTheme.textSecondaryColor), onPressed: () => _showInfoDialog(context)),
            ],
          ),
          const SizedBox(height: 16),
          
          // Tabs
          Container(
            height: 36,
            decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: widget.ranges.map((range) {
                final isSelected = _selectedRange == range;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedRange = range),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: isSelected ? AppTheme.primaryBlue : Colors.transparent, borderRadius: BorderRadius.circular(8)),
                      child: Text(_getRangeLabel(range), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
          widget.builder(_selectedRange, filteredData),
        ],
      ),
    );
  }

  String _getRangeLabel(String key) {
    switch (key) {
      case '1D': return 'Daily';
      case '7D': return 'Weekly';
      case '14D': return 'Bi-Weekly';
      case '30D': return 'Monthly';
      default: return key;
    }
  }
}

// ============================================================================
// SECTIONS
// ============================================================================

class _StatisticsSection extends StatelessWidget {
  final List<_BpReading> readings;
  final HealthThreshold sysThreshold;
  final HealthThreshold diaThreshold;
  final bool isDefault;

  const _StatisticsSection({
    required this.readings, 
    required this.sysThreshold, 
    required this.diaThreshold,
    this.isDefault = false,
  });

  @override
  Widget build(BuildContext context) {
    return _ChartSection(
      title: 'Overview',
      icon: Icons.analytics_outlined,
      infoText: 'Key statistics for blood pressure.\n\n'
                '• Average: Mean systolic/diastolic levels.\n'
                '• Pulse Pressure: Difference between systolic and diastolic (Sys - Dia).\n'
                '• Target: Your configured safe range.',
      allData: readings,
      builder: (range, data) {
        double avgSys = 0, avgDia = 0, avgPulse = 0;
        if (data.isNotEmpty) {
          avgSys = data.map((e) => e.systolic).reduce((a, b) => a + b) / data.length;
          avgDia = data.map((e) => e.diastolic).reduce((a, b) => a + b) / data.length;
          avgPulse = data.map((e) => e.pulsePressure).reduce((a, b) => a + b) / data.length;
        }

        return Column(
          children: [
             // Target Range Display
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.track_changes, size: 18, color: AppTheme.primaryGreen),
                  const SizedBox(width: 8),
                  Text(
                    isDefault ? 'Default Target: ' : 'Your Target: ',
                    style: TextStyle(color: AppTheme.primaryGreen.withOpacity(0.8), fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '<${sysThreshold.maxValue.toInt()} / <${diaThreshold.maxValue.toInt()} mmHg',
                    style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ),
            // Stats Grid
            Row(
              children: [
                Expanded(child: _buildStatBox(context, 'Avg Systolic', avgSys.toStringAsFixed(0), 'mmHg', AppTheme.primaryRed)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatBox(context, 'Avg Diastolic', avgDia.toStringAsFixed(0), 'mmHg', AppTheme.primaryBlue)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatBox(context, 'Pulse Pressure', avgPulse.toStringAsFixed(0), 'mmHg', AppTheme.textSecondaryColor)),
              ],
            ),
          ],
        );
      },
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

class _DualTrendSection extends StatelessWidget {
  final List<_BpReading> readings;
  final HealthThreshold sysThreshold;
  final HealthThreshold diaThreshold;

  const _DualTrendSection({required this.readings, required this.sysThreshold, required this.diaThreshold});

  @override
  Widget build(BuildContext context) {
    const double yAxisWidth = 35.0;

    return _ChartSection(
      title: 'Pressure Trends',
      icon: Icons.show_chart,
      infoText: 'Shows your Systolic (Top) and Diastolic (Bottom) trends over time.\n\n'
                '• Shaded areas indicate readings within your target safe zone.',
      allData: readings,
      builder: (range, data) {
        double minX, maxX;
        if (data.isNotEmpty) {
           minX = data.first.timestamp.millisecondsSinceEpoch.toDouble();
           maxX = data.last.timestamp.millisecondsSinceEpoch.toDouble();
           if (minX == maxX) { minX -= 3600000; maxX += 3600000; } 
        } else {
           final now = DateTime.now();
           Duration d = const Duration(hours: 24);
           if (range == '7D') d = const Duration(days: 7);
           else if (range == '14D') d = const Duration(days: 14);
           else if (range == '30D') d = const Duration(days: 30);
           minX = now.subtract(d).millisecondsSinceEpoch.toDouble();
           maxX = now.millisecondsSinceEpoch.toDouble();
        }

        return Column(
          children: [
            SizedBox(
              height: 250,
              child: LineChart(
                duration: Duration.zero, // Fix janky animation
                LineChartData(
                  minX: minX, maxX: maxX, minY: 40, maxY: 180,
                  gridData: FlGridData(
                    show: true, 
                    drawVerticalLine: false, 
                    getDrawingHorizontalLine: (_) => FlLine(color: AppTheme.getBorderColor(context).withOpacity(0.2), strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      axisNameWidget: Text('mmHg', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10)),
                      axisNameSize: 20,
                      sideTitles: SideTitles(
                        showTitles: true, 
                        reservedSize: yAxisWidth, 
                        interval: 40, 
                        getTitlesWidget: (v, _) {
                          if (v == 40 || v == 180) return const SizedBox(); // Hide overlap
                          return Text(v.toInt().toString(), style: const TextStyle(fontSize: 10));
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      axisNameWidget: Padding(padding: const EdgeInsets.only(top: 4), child: Text('Time', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10))),
                      axisNameSize: 20,
                      sideTitles: SideTitles(
                        showTitles: true, 
                        interval: (maxX - minX) / 4, 
                        getTitlesWidget: (v, _) {
                          if (v == minX || v == maxX) return const SizedBox(); // Hide overlap
                          final date = DateTime.fromMillisecondsSinceEpoch(v.toInt());
                          final fmt = range == '1D' ? DateFormat('HH:mm') : DateFormat('MM/dd');
                          return Padding(padding: const EdgeInsets.only(top: 8), child: Text(fmt.format(date), style: const TextStyle(fontSize: 10)));
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: yAxisWidth, getTitlesWidget: _emptyTitle)),
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
                      spots: data.map((r) => FlSpot(r.timestamp.millisecondsSinceEpoch.toDouble(), r.systolic)).toList(),
                      color: AppTheme.primaryRed, barWidth: 2, isCurved: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: 3, color: AppTheme.primaryRed, strokeWidth: 1.5, strokeColor: Colors.white),
                      ),
                    ),
                    // Diastolic Line
                    LineChartBarData(
                      spots: data.map((r) => FlSpot(r.timestamp.millisecondsSinceEpoch.toDouble(), r.diastolic)).toList(),
                      color: AppTheme.primaryBlue, barWidth: 2, isCurved: true,
                      dotData: FlDotData(
                         show: true,
                         getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: 3, color: AppTheme.primaryBlue, strokeWidth: 1.5, strokeColor: Colors.white),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => Colors.black.withOpacity(0.8),
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                           final isSys = spot.barIndex == 0;
                           return LineTooltipItem(
                             '${isSys ? "Sys" : "Dia"}: ${spot.y.toInt()}',
                             const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                           );
                        }).toList();
                      }
                    )
                  )
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
               _LegendItem('Systolic', AppTheme.primaryRed),
               const SizedBox(width: 16),
               _LegendItem('Diastolic', AppTheme.primaryBlue),
               const SizedBox(width: 16),
               _LegendItem('Safe Zone', Colors.grey.withOpacity(0.3), isBox: true),
            ]),
          ],
        );
      },
    );
  }
  static Widget _emptyTitle(double value, TitleMeta meta) => const SizedBox.shrink();
}

class _FloatingBarSection extends StatelessWidget {
  final List<_BpReading> readings;

  const _FloatingBarSection({required this.readings});

  @override
  Widget build(BuildContext context) {
    return _ChartSection(
      title: 'Daily Range (Pulse Pressure)',
      icon: Icons.bar_chart,
      infoText: 'Visualizes the gap between your systolic and diastolic numbers.\n\n'
                'A wider gap (Pulse Pressure) can indicate stiffness in arteries.',
      allData: readings,
      builder: (range, data) {
        // For bar chart, too many points look bad. Limit or aggregate if needed.
        // Here we simply show the data points available in range.
        // If 1D, show actual points. If 30D, we might want to sample, but filtering is done by wrapper.
        
        return Column(
          children: [
            SizedBox(
              height: 250,
              child: BarChart(
                duration: Duration.zero, // Fix animation
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 200, minY: 40,
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      axisNameWidget: Text('mmHg', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10)),
                      axisNameSize: 20,
                      sideTitles: SideTitles(showTitles: true, reservedSize: 35, interval: 40, getTitlesWidget: (v, _) => Text(v.toInt().toString(), style: const TextStyle(fontSize: 10)))),
                    bottomTitles: AxisTitles(
                      axisNameWidget: Padding(padding: const EdgeInsets.only(top: 4), child: Text('Time', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10))),
                      axisNameSize: 20,
                      sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
                        if (v.toInt() >= data.length) return const SizedBox();
                        if (data.length > 10 && v.toInt() % 2 != 0) return const SizedBox();
                        return Padding(padding: const EdgeInsets.only(top: 8), child: Text(DateFormat('d/M').format(data[v.toInt()].timestamp), style: const TextStyle(fontSize: 10)));
                      })),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    // Use empty right titles to center axis
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 35, getTitlesWidget: _emptyTitle)),
                  ),
                  gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: AppTheme.getBorderColor(context).withOpacity(0.2), strokeWidth: 1)),
                  borderData: FlBorderData(show: true, border: Border.all(color: AppTheme.getBorderColor(context).withOpacity(0.5))), // Added border
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => Colors.black.withOpacity(0.8),
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                         final r = data[group.x.toInt()];
                         return BarTooltipItem(
                           '${r.systolic.toInt()}/${r.diastolic.toInt()}',
                           const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                           children: [TextSpan(text: '\nPulse: ${r.pulsePressure.toInt()}', style: const TextStyle(fontSize: 10, color: Colors.white70))],
                         );
                      }
                    )
                  ),
                  barGroups: data.asMap().entries.map((entry) {
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
          ],
        );
      },
    );
  }
}

class _ScatterSection extends StatelessWidget {
  final List<_BpReading> readings;
  final HealthThreshold sysThreshold;
  final HealthThreshold diaThreshold;

  const _ScatterSection({required this.readings, required this.sysThreshold, required this.diaThreshold});

  @override
  Widget build(BuildContext context) {
    return _ChartSection(
      title: 'Systolic vs. Diastolic',
      icon: Icons.bubble_chart_outlined,
      infoText: 'Correlates your top number vs bottom number.\n\n'
                '• Green dots: Within target range.\n'
                '• Red dots: Exceeding target range.',
      allData: readings,
      builder: (range, data) {
        return Column(
          children: [
            SizedBox(
              height: 250,
              child: ScatterChart(
                duration: Duration.zero, // Fix animation
                ScatterChartData(
                  scatterSpots: data.map((r) {
                    bool isHigh = r.systolic > sysThreshold.maxValue || r.diastolic > diaThreshold.maxValue;
                    return ScatterSpot(
                      r.diastolic, 
                      r.systolic,
                      dotPainter: FlDotCirclePainter(
                        color: isHigh ? AppTheme.errorColor : AppTheme.primaryGreen,
                        radius: 4, // Thinner dots
                        strokeWidth: 0,
                      ),
                    );
                  }).toList(),
                  minX: 40, maxX: 130,
                  minY: 80, maxY: 200,
                  gridData: FlGridData(show: true, getDrawingHorizontalLine: (_) => FlLine(color: AppTheme.getBorderColor(context).withOpacity(0.2), strokeWidth: 1), getDrawingVerticalLine: (_) => FlLine(color: AppTheme.getBorderColor(context).withOpacity(0.2), strokeWidth: 1)),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(axisNameWidget: const Text('Diastolic (mmHg)', style: TextStyle(fontSize: 10)), axisNameSize: 20, sideTitles: SideTitles(showTitles: true, interval: 20, getTitlesWidget: (v, _) {
                      if (v == 40 || v == 130) return const SizedBox();
                      return Text(v.toInt().toString(), style: const TextStyle(fontSize: 10));
                    })),
                    leftTitles: AxisTitles(axisNameWidget: const Text('Systolic (mmHg)', style: TextStyle(fontSize: 10)), axisNameSize: 20, sideTitles: SideTitles(showTitles: true, interval: 20, reservedSize: 35, getTitlesWidget: (v, _) {
                      if (v == 80 || v == 200) return const SizedBox();
                      return Text(v.toInt().toString(), style: const TextStyle(fontSize: 10));
                    })),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 35, getTitlesWidget: _emptyTitle)), // Center chart
                  ),
                  borderData: FlBorderData(show: true, border: Border.all(color: AppTheme.getBorderColor(context).withOpacity(0.5))),
                  scatterTouchData: ScatterTouchData(
                    touchTooltipData: ScatterTouchTooltipData(
                      getTooltipColor: (_) => Colors.black.withOpacity(0.8),
                      getTooltipItems: (spot) {
                        return ScatterTooltipItem(
                          'Sys: ${spot.y.toInt()}\nDia: ${spot.x.toInt()}',
                          textStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        );
                      }
                    )
                  )
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
        );
      },
    );
  }
}

class _HistorySection extends StatefulWidget {
  final List<_BpReading> readings;
  const _HistorySection({required this.readings});

  @override
  State<_HistorySection> createState() => _HistorySectionState();
}

class _HistorySectionState extends State<_HistorySection> {
  int _currentPage = 0;
  static const int _itemsPerPage = 5;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reversed = widget.readings.reversed.toList();

    final totalItems = reversed.length;
    final totalPages = (totalItems / _itemsPerPage).ceil();
    if (_currentPage >= totalPages && totalPages > 0) _currentPage = totalPages - 1;
    
    final start = _currentPage * _itemsPerPage;
    final end = math.min(start + _itemsPerPage, totalItems);
    final currentItems = reversed.sublist(start, end);

    return _ChartContainer(
      title: 'History',
      icon: Icons.history,
      child: Column(
        children: [
          if (currentItems.isEmpty) const Text('No History available'),
          ...currentItems.map((r) {
             // Unique Status Logic
             String status;
             Color statusColor;
             if (r.systolic > 140 || r.diastolic > 90) {
               status = 'HIGH';
               statusColor = AppTheme.errorColor;
             } else if (r.systolic > 120 || r.diastolic > 80) {
               status = 'ELEVATED';
               statusColor = AppTheme.warningColor;
             } else {
               status = 'NORMAL';
               statusColor = AppTheme.primaryGreen;
             }

             return Container(
               margin: const EdgeInsets.only(bottom: 12),
               padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
               decoration: BoxDecoration(
                 // BP Screen Style Color (White/Midnight)
                 color: isDark ? AppTheme.midnightSurface : Colors.white,
                 borderRadius: BorderRadius.circular(12),
                 border: Border.all(color: AppTheme.getBorderColor(context).withOpacity(0.5)),
               ),
               child: Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   // Glucose Layout (Left: Date/Time)
                   Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(DateFormat('MMM d, yyyy').format(r.timestamp), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                       const SizedBox(height: 2),
                       Text(DateFormat('h:mm a').format(r.timestamp), style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11)),
                     ],
                   ),
                   // Glucose Layout (Right: Value/Status)
                   Column(
                     crossAxisAlignment: CrossAxisAlignment.end,
                     children: [
                       Text('${r.systolic.toInt()}/${r.diastolic.toInt()} mmHg', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                       const SizedBox(height: 2),
                       Container(
                         padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                         decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                         child: Text(status, style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold)),
                       ),
                     ],
                   ),
                 ],
               ),
             );
          }),
          // Pagination Controls
          if (totalPages > 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null, icon: const Icon(Icons.chevron_left)),
                Text('${_currentPage + 1}/$totalPages', style: const TextStyle(fontWeight: FontWeight.bold)),
                IconButton(onPressed: _currentPage < totalPages - 1 ? () => setState(() => _currentPage++) : null, icon: const Icon(Icons.chevron_right)),
              ],
            ),
        ],
      ),
    );
  }
}

Widget _emptyTitle(double value, TitleMeta meta) => const SizedBox.shrink();

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;
  final bool isCircle;
  final bool isBox;
  const _LegendItem(this.label, this.color, {this.isCircle = false, this.isBox = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(color: color, shape: isCircle ? BoxShape.circle : BoxShape.rectangle, borderRadius: (isCircle || isBox) ? null : BorderRadius.circular(2)),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}
