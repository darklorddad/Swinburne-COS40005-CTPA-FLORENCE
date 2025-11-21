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

          // Ensure we only pass thresholds if they exist, no defaults
          final sysThreshold = userSys;
          final diaThreshold = userDia;

          return RefreshIndicator(
            onRefresh: () async {
              await Future.wait([
                ref.refresh(monitorDataProvider.future),
                ref.refresh(patientThresholdsProvider.future),
              ]);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
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
                _HistorySection(
                  readings: readings,
                  sysThreshold: sysThreshold,
                  diaThreshold: diaThreshold,
                ),
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
    if (widget.ranges.contains('1D')) _selectedRange = '1D';
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
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(widget.icon, color: AppTheme.primaryBlue),
            const SizedBox(width: 12),
            Expanded(child: Text(widget.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))),
          ],
        ),
        content: Text(widget.infoText, style: Theme.of(context).textTheme.bodyMedium),
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
              IconButton(
                icon: Icon(Icons.info_outline, color: AppTheme.textSecondaryColor, size: 20),
                onPressed: () => _showInfoDialog(context),
              ),
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
  final HealthThreshold? sysThreshold;
  final HealthThreshold? diaThreshold;
  final bool isDefault;

  const _StatisticsSection({
    required this.readings, 
    this.sysThreshold, 
    this.diaThreshold,
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
            InkWell(
              onTap: () => Navigator.of(context).pushNamed('/profile'),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.track_changes, size: 18, color: AppTheme.primaryGreen),
                            const SizedBox(width: 8),
                            Text(
                              'Target Ranges',
                              style: TextStyle(color: AppTheme.primaryGreen.withOpacity(0.8), fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: AppTheme.primaryGreen.withOpacity(0.5),
                        ),
                      ],
                    ),
                    if (sysThreshold != null && diaThreshold != null) ...[
                      const SizedBox(height: 12),
                      _buildMiniTargetRow('Systolic', '${sysThreshold!.minValue.toInt()} - ${sysThreshold!.maxValue.toInt()} mmHg', AppTheme.primaryGreen),
                      const SizedBox(height: 4),
                      _buildMiniTargetRow('Diastolic', '${diaThreshold!.minValue.toInt()} - ${diaThreshold!.maxValue.toInt()} mmHg', AppTheme.primaryGreen),
                    ] else ...[
                      const SizedBox(height: 12),
                      const Text('Targets not configured', style: TextStyle(color: AppTheme.textSecondaryColor)),
                    ],
                  ],
                ),
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

  Widget _buildMiniTargetRow(String label, String val, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: color.withOpacity(0.8))),
        Text(val, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
      ],
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
          Text(title, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(width: 2),
              Text(unit, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

class _DualTrendSection extends StatelessWidget {
  final List<_BpReading> readings;
  final HealthThreshold? sysThreshold;
  final HealthThreshold? diaThreshold;

  const _DualTrendSection({required this.readings, this.sysThreshold, this.diaThreshold});

  @override
  Widget build(BuildContext context) {
    return _ChartSection(
      title: 'Pressure Trends',
      icon: Icons.show_chart,
      infoText: 'Visualizes your blood pressure trends over time.\n\n'
                '• Y-Axis: Pressure (mmHg)\n'
                '• X-Axis: Time\n'
                '• Shaded Band: Readings within your target safe zone.',
      allData: readings,
      builder: (range, data) {
        double minX, maxX;
        if (range == '1D') {
          // For Daily view, always show full 24h of the specific day (or last 24h)
          final now = DateTime.now();
          // Align to start of day if data exists, otherwise last 24h
          if (data.isNotEmpty) {
             final day = data.last.timestamp;
             minX = DateTime(day.year, day.month, day.day).millisecondsSinceEpoch.toDouble();
             // Use next midnight for cleaner 24h axis division
             maxX = DateTime(day.year, day.month, day.day).add(const Duration(days: 1)).millisecondsSinceEpoch.toDouble();
          } else {
             minX = now.subtract(const Duration(hours: 24)).millisecondsSinceEpoch.toDouble();
             maxX = now.millisecondsSinceEpoch.toDouble();
          }
        } else if (data.isNotEmpty) {
           minX = data.first.timestamp.millisecondsSinceEpoch.toDouble();
           maxX = data.last.timestamp.millisecondsSinceEpoch.toDouble();
           if (minX == maxX) { minX -= 3600000; maxX += 3600000; } 
        } else {
           final now = DateTime.now();
           Duration d = const Duration(days: 7);
           if (range == '14D') d = const Duration(days: 14);
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
                    drawVerticalLine: true,
                    getDrawingHorizontalLine: (_) => FlLine(color: AppTheme.getBorderColor(context).withOpacity(0.2), strokeWidth: 1),
                    getDrawingVerticalLine: (_) => FlLine(color: AppTheme.getBorderColor(context).withOpacity(0.2), strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: (maxX - minX) / (range == '1D' ? 6 : 4), // More ticks for daily view
                        getTitlesWidget: (value, meta) {
                          // Aggressively hide labels near the start and end
                          // Using meta.min/max ensures we match the chart's actual viewport
                          final tolerance = (meta.max - meta.min) * 0.05; // 5% margin
                          if (value <= meta.min + tolerance || value >= meta.max - tolerance) {
                            return const SizedBox();
                          }

                          final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                          // 1D shows Time (HH:mm), others show Date (d/M)
                          final text = range == '1D' 
                              ? DateFormat('HH:mm').format(date) 
                              : DateFormat('d/M').format(date);
                          return Padding(padding: const EdgeInsets.only(top: 8), child: Text(text, style: const TextStyle(fontSize: 10)));
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true, border: Border.all(color: AppTheme.getBorderColor(context).withOpacity(0.5))),
                  // Safe Zones
                  rangeAnnotations: RangeAnnotations(
                    horizontalRangeAnnotations: [
                      if (sysThreshold != null)
                        HorizontalRangeAnnotation(y1: sysThreshold!.minValue, y2: sysThreshold!.maxValue, color: AppTheme.primaryRed.withOpacity(0.05)),
                      if (diaThreshold != null)
                        HorizontalRangeAnnotation(y1: diaThreshold!.minValue, y2: diaThreshold!.maxValue, color: AppTheme.primaryBlue.withOpacity(0.05)),
                    ]
                  ),
                  // Dotted Threshold Lines
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      if (sysThreshold != null) ...[
                        HorizontalLine(y: sysThreshold!.minValue, color: AppTheme.primaryRed.withOpacity(0.5), strokeWidth: 1, dashArray: [4, 4]),
                        HorizontalLine(y: sysThreshold!.maxValue, color: AppTheme.primaryRed.withOpacity(0.5), strokeWidth: 1, dashArray: [4, 4]),
                      ],
                      if (diaThreshold != null) ...[
                        HorizontalLine(y: diaThreshold!.minValue, color: AppTheme.primaryBlue.withOpacity(0.5), strokeWidth: 1, dashArray: [4, 4]),
                        HorizontalLine(y: diaThreshold!.maxValue, color: AppTheme.primaryBlue.withOpacity(0.5), strokeWidth: 1, dashArray: [4, 4]),
                      ],
                    ],
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
                    getTouchedSpotIndicator: (barData, spotIndexes) {
                      return spotIndexes.map((index) {
                        return TouchedSpotIndicatorData(
                          // Thinner line (0.5)
                          const FlLine(color: AppTheme.textSecondaryColor, strokeWidth: 0.5),
                          FlDotData(show: true, getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(radius: 4, color: AppTheme.primaryBlue, strokeColor: Colors.white)),
                        );
                      }).toList();
                    },
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
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              runSpacing: 8,
              children: [
               _buildLegendItem('Systolic', AppTheme.primaryRed, isCircle: true),
               _buildLegendItem('Diastolic', AppTheme.primaryBlue, isCircle: true),
               _buildLegendItem('Sys Limit', AppTheme.primaryRed.withOpacity(0.5), isBox: true),
               _buildLegendItem('Dia Limit', AppTheme.primaryBlue.withOpacity(0.5), isBox: true),
            ]),
          ],
        );
      },
    );
  }
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
                '• Y-Axis: Pressure (mmHg)\n'
                '• X-Axis: Time\n'
                '• Bar Height: Difference between Systolic and Diastolic.',
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
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, meta) {
                        if (v.toInt() >= data.length) return const SizedBox();
                        
                        // Hide first and last labels
                        if (v == 0 || v.toInt() == data.length - 1) return const SizedBox();

                        // Skip every other label if too many points
                        if (data.length > 10 && v.toInt() % 2 != 0) return const SizedBox();
                        
                        final date = data[v.toInt()].timestamp;
                        final text = range == '1D' 
                            ? DateFormat('HH:mm').format(date) 
                            : DateFormat('d/M').format(date);
                            
                        return Padding(padding: const EdgeInsets.only(top: 8), child: Text(text, style: const TextStyle(fontSize: 10)));
                      })),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Systolic (Top)', AppTheme.primaryBlue.withOpacity(0.6), isBox: true),
                const SizedBox(width: 16),
                _buildLegendItem('Diastolic (Bottom)', AppTheme.primaryBlue.withOpacity(0.6), isBox: true),
              ],
            )
          ],
        );
      },
    );
  }
}

class _ScatterSection extends StatelessWidget {
  final List<_BpReading> readings;
  final HealthThreshold? sysThreshold;
  final HealthThreshold? diaThreshold;

  const _ScatterSection({required this.readings, this.sysThreshold, this.diaThreshold});

  @override
  Widget build(BuildContext context) {
    return _ChartSection(
      title: 'Systolic vs. Diastolic',
      icon: Icons.bubble_chart_outlined,
      infoText: 'Correlates your Systolic vs Diastolic pressure.\n\n'
                '• Y-Axis: Systolic (mmHg)\n'
                '• X-Axis: Diastolic (mmHg)\n'
                '• Color: Green (In Range), Red (Out of Range).',
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
                    Color dotColor;
                    if (sysThreshold != null && diaThreshold != null) {
                      final isHigh = r.systolic > sysThreshold!.maxValue || r.diastolic > diaThreshold!.maxValue;
                      dotColor = isHigh ? AppTheme.errorColor : AppTheme.primaryGreen;
                    } else {
                      dotColor = AppTheme.primaryBlue;
                    }
                    
                    return ScatterSpot(
                      r.diastolic, 
                      r.systolic,
                      dotPainter: FlDotCirclePainter(
                        color: dotColor,
                        radius: 4,
                        strokeWidth: 0,
                      ),
                    );
                  }).toList(),
                  minX: 40, maxX: 130,
                  minY: 80, maxY: 200,
                  gridData: FlGridData(show: true, getDrawingHorizontalLine: (_) => FlLine(color: AppTheme.getBorderColor(context).withOpacity(0.2), strokeWidth: 1), getDrawingVerticalLine: (_) => FlLine(color: AppTheme.getBorderColor(context).withOpacity(0.2), strokeWidth: 1)),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 20, getTitlesWidget: (value, meta) {
                      if (value <= meta.min || value >= meta.max) return const SizedBox();
                      return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10));
                    })),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
               if (sysThreshold != null && diaThreshold != null) ...[
                 _buildLegendItem('Normal', AppTheme.primaryGreen, isCircle: true),
                 const SizedBox(width: 16),
                 _buildLegendItem('High', AppTheme.errorColor, isCircle: true),
               ] else
                 _buildLegendItem('Recorded', AppTheme.primaryBlue, isCircle: true),
            ]),
          ],
        );
      },
    );
  }
}

class _HistorySection extends StatefulWidget {
  final List<_BpReading> readings;
  final HealthThreshold? sysThreshold;
  final HealthThreshold? diaThreshold;

  const _HistorySection({
    required this.readings,
    this.sysThreshold,
    this.diaThreshold,
  });

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

    // Manually build container to allow Paginator in header (same layout as GlucoseDetailScreen)
    final containerColor = isDark ? AppTheme.midnightSurface : Colors.white;
    final borderColor = AppTheme.getBorderColor(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          // Header Row with Paginator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppTheme.primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.history, color: AppTheme.primaryBlue, size: 24)
                  ),
                  const SizedBox(width: 12),
                  Text('History', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              // Pagination Controls (Top Right)
              if (totalPages > 1)
                Row(
                  children: [
                    IconButton(
                      onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text('${_currentPage + 1}/$totalPages', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    IconButton(
                      onPressed: _currentPage < totalPages - 1 ? () => setState(() => _currentPage++) : null,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 20),
          
          if (currentItems.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No history available',
                  style: TextStyle(color: AppTheme.textSecondaryColor),
                ),
              ),
            ),
            
          ...currentItems.map((r) {
             // Dynamic Status Logic using Thresholds
             String status;
             Color statusColor;
             
             if (widget.sysThreshold != null && widget.diaThreshold != null) {
               final sysMax = widget.sysThreshold!.maxValue;
               final diaMax = widget.diaThreshold!.maxValue;

               if (r.systolic > (sysMax + 20) || r.diastolic > (diaMax + 10)) {
                 status = 'HIGH';
                 statusColor = AppTheme.errorColor;
               } else if (r.systolic > sysMax || r.diastolic > diaMax) {
                 status = 'ELEVATED';
                 statusColor = AppTheme.warningColor;
               } else if (r.systolic < widget.sysThreshold!.minValue || r.diastolic < widget.diaThreshold!.minValue) {
                 status = 'LOW';
                 statusColor = AppTheme.infoColor;
               } else {
                 status = 'NORMAL';
                 statusColor = AppTheme.primaryGreen;
               }
             } else {
               status = 'RECORDED';
               statusColor = AppTheme.primaryBlue;
             }

             return Container(
               margin: const EdgeInsets.only(bottom: 12),
               padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
               decoration: BoxDecoration(
                 color: isDark ? AppTheme.midnightSurface : Colors.white,
                 borderRadius: BorderRadius.circular(12),
                 boxShadow: [
                   BoxShadow(
                     color: Colors.black.withOpacity(0.03),
                     blurRadius: 8,
                     offset: const Offset(0, 2)
                   )
                 ],
                 border: Border.all(
                   color: statusColor.withOpacity(0.3),
                   width: 1,
                 ),
               ),
               child: Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   // Left: Value
                   Row(
                     crossAxisAlignment: CrossAxisAlignment.baseline,
                     textBaseline: TextBaseline.alphabetic,
                     children: [
                       Text(
                         '${r.systolic.toInt()}/${r.diastolic.toInt()}',
                         style: TextStyle(
                           fontWeight: FontWeight.normal,
                           fontSize: 20, // Reduced font size
                           color: AppTheme.textPrimaryColor,
                         ),
                       ),
                       const SizedBox(width: 4),
                       Text(
                         'mmHg',
                         style: Theme.of(context).textTheme.bodySmall?.copyWith(
                               color: AppTheme.textSecondaryColor,
                               fontSize: 12,
                             ),
                       ),
                     ],
                   ),
                   // Right: Date and Status Badge
                   Column(
                     crossAxisAlignment: CrossAxisAlignment.end,
                     children: [
                       Container(
                         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                         decoration: BoxDecoration(
                           color: statusColor.withOpacity(0.1),
                           borderRadius: BorderRadius.circular(8),
                         ),
                         child: Text(
                           status,
                           style: TextStyle(
                             color: statusColor,
                             fontSize: 10,
                             fontWeight: FontWeight.bold,
                           ),
                         ),
                       ),
                       const SizedBox(height: 6),
                       Text(
                         DateFormat('MMM d, h:mm a').format(r.timestamp),
                         style: Theme.of(context).textTheme.bodySmall?.copyWith(
                               fontSize: 11,
                               color: AppTheme.textSecondaryColor,
                             ),
                       ),
                     ],
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

Widget _emptyTitle(double value, TitleMeta meta) => const SizedBox.shrink();

class _ChartContainer extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _ChartContainer({super.key, required this.title, required this.icon, required this.child});

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

Widget _buildLegendItem(String label, Color color, {bool isBox = false, bool isCircle = false, bool isDashed = false}) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (isBox)
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)))
      else if (isCircle)
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle))
      else if (isDashed)
        Container(width: 2, height: 12, color: color)
      else
        Container(width: 12, height: 2, color: color),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 11)),
    ],
  );
}
