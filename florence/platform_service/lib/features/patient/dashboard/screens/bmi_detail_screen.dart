import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../config/routes.dart';
import '../../../../config/theme.dart';
import '../../../../core/layout/responsive_layout_system.dart';
import '../../core/models/health_data_models.dart';
import '../../core/providers/monitor_data_providers.dart' as core_data;
import '../../core/providers/threshold_providers.dart';
import '../../dashboard/providers/dashboard_providers.dart';

class BmiDetailScreen extends ConsumerWidget {
  final VoidCallback? onSwitchToLog;
  const BmiDetailScreen({super.key, this.onSwitchToLog});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monitorAsync = ref.watch(monitorDataProvider);
    final thresholdsAsync = ref.watch(patientThresholdsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('BMI Analytics'),
        elevation: 0,
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: IconButton(
              icon: const Icon(Icons.add),
              onPressed: onSwitchToLog ?? () => AppRoutes.pushReplacement(context, AppRoutes.logBmi),
              tooltip: 'Add Log',
            ),
          ),
        ],
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
          // Get Thresholds
          final thresholds = thresholdsAsync.value ?? [];
          HealthThreshold? bmiThreshold;
          try {
            bmiThreshold = thresholds.firstWhere((t) => t.dataType == MonitorDataType.BMI);
          } catch (_) {}

          // Filter BMI Data
          final bmiReadings = dataList
              .where((d) => d.dataType == MonitorDataType.BMI)
              .toList();
          
          // Sort by date ascending
          bmiReadings.sort((a, b) => a.measuredAt.compareTo(b.measuredAt));

          // Get latest reading
          final latestBmi = bmiReadings.isNotEmpty ? bmiReadings.last : null;

          // Get correlation data (HbA1c)
          final hba1cReadings = dataList
              .where((d) => d.dataType == MonitorDataType.HBA1C)
              .toList()
            ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));

          return RefreshIndicator(
            onRefresh: () async {
              return ref.refresh(core_data.monitorDataProvider.future);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: context.isDesktop
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    children: [
                                      _BmiGaugeSection(
                                        latestReading: latestBmi,
                                        threshold: bmiThreshold,
                                      ),
                                      const SizedBox(height: 20),
                                      _BmiTrendSection(
                                        readings: bmiReadings,
                                        threshold: bmiThreshold,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    children: [
                                      _BmiCorrelationSection(
                                        bmiReadings: bmiReadings,
                                        hba1cReadings: hba1cReadings,
                                      ),
                                      const SizedBox(height: 20),
                                      _HistorySection(
                                        readings: bmiReadings,
                                        threshold: bmiThreshold,
                                      ),
                                      const SizedBox(height: 24),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                _BmiGaugeSection(
                                  latestReading: latestBmi,
                                  threshold: bmiThreshold,
                                ),
                                const SizedBox(height: 20),
                                _BmiTrendSection(
                                  readings: bmiReadings,
                                  threshold: bmiThreshold,
                                ),
                                const SizedBox(height: 20),
                                _BmiCorrelationSection(
                                  bmiReadings: bmiReadings,
                                  hba1cReadings: hba1cReadings,
                                ),
                                const SizedBox(height: 20),
                                _HistorySection(
                                  readings: bmiReadings,
                                  threshold: bmiThreshold,
                                ),
                                const SizedBox(height: 24),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
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
// REUSABLE CHART WRAPPER (Consistent Layout)
// ============================================================================

class _ChartSection extends StatefulWidget {
  final String title;
  final IconData icon;
  final String infoText;
  final Widget Function(String range, List<MonitorData> filteredData) builder;
  final List<MonitorData> allData;
  final List<String> ranges;

  const _ChartSection({
    required this.title,
    required this.icon,
    required this.infoText,
    required this.builder,
    required this.allData,
    this.ranges = const ['6M', '1Y', 'ALL'], // Default for slow metrics like BMI
  });

  @override
  State<_ChartSection> createState() => _ChartSectionState();
}

class _ChartSectionState extends State<_ChartSection> {
  late String _selectedRange;

  @override
  void initState() {
    super.initState();
    _selectedRange = widget.ranges.first;
    if (widget.ranges.contains('1D')) _selectedRange = '1D';
  }

  List<MonitorData> _filterData() {
    if (widget.allData.isEmpty) return [];
    if (_selectedRange == 'ALL') return widget.allData;

    final now = DateTime.now();
    Duration duration;
    switch (_selectedRange) {
      case '1D': duration = const Duration(days: 1); break;
      case '7D': duration = const Duration(days: 7); break;
      case '30D': duration = const Duration(days: 30); break;
      case '3M': duration = const Duration(days: 90); break;
      case '6M': duration = const Duration(days: 180); break;
      case '1Y': duration = const Duration(days: 365); break;
      default: duration = const Duration(days: 90); break;
    }
    final cutoff = now.subtract(duration);
    return widget.allData.where((d) => d.measuredAt.isAfter(cutoff)).toList();
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
      case '1M': return 'Monthly';
      case '3M': return 'Quarterly';
      case '6M': return 'Half Year';
      case '1Y': return 'Yearly';
      case 'ALL': return 'All Time';
      default: return key;
    }
  }
}

// ============================================================================
// 1. LINEAR GAUGE (CURRENT STATUS)
// ============================================================================

class _BmiGaugeSection extends StatelessWidget {
  final MonitorData? latestReading;
  final HealthThreshold? threshold;

  const _BmiGaugeSection({this.latestReading, this.threshold});

  @override
  Widget build(BuildContext context) {
    // 1. Setup Bounds (Standard or Custom)
    final bool hasCustomThreshold = threshold != null;
    final minNormal = threshold?.minValue ?? 18.5;  // Lower Bound of Target
    final maxNormal = threshold?.maxValue ?? 24.9;  // Upper Bound of Target
    final overweightLimit = maxNormal + 5.0;        // Dynamic Warning Zone

    final bmi = latestReading?.value ?? 0.0;
    
    // 2. Determine Text Label & Indicator Color based on position relative to Target
    String category;
    Color color;

    if (bmi == 0) {
      category = "No Data";
      color = AppTheme.textSecondaryColor;
    } else if (bmi < minNormal) {
      category = hasCustomThreshold ? "Below Target" : "Underweight";
      color = AppTheme.primaryBlue;
    } else if (bmi <= maxNormal) {
      category = hasCustomThreshold ? "On Target" : "Normal";
      color = AppTheme.primaryGreen;
    } else if (bmi <= overweightLimit) {
      category = hasCustomThreshold ? "Above Target" : "Overweight";
      color = AppTheme.warningColor;
    } else {
      category = hasCustomThreshold ? "High" : "Obese";
      color = AppTheme.errorColor;
    }

    final infoText = hasCustomThreshold
        ? 'Your Personal BMI Goal:\n\n'
          '• Target: ${minNormal.toStringAsFixed(1)} - ${maxNormal.toStringAsFixed(1)} kg/m²\n'
          '• Below: < ${minNormal.toStringAsFixed(1)}\n'
          '• Above: > ${maxNormal.toStringAsFixed(1)}'
        : 'Standard BMI Categories:\n\n'
          '• Underweight: < 18.5\n'
          '• Normal: 18.5 – 24.9\n'
          '• Overweight: 25 – 29.9\n'
          '• Obese: 30+';

    return _BmiCard(
      title: 'Current Status',
      icon: Icons.speed,
      infoText: infoText,
      child: Column(
        children: [
          // Target Range Header
          InkWell(
            onTap: () => Navigator.of(context).pushNamed('/profile'),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
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
                          const Icon(Icons.track_changes, size: 18, color: AppTheme.primaryGreen),
                          const SizedBox(width: 8),
                          Text(
                            'Target Range',
                            style: TextStyle(
                              color: AppTheme.primaryGreen.withOpacity(0.8),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Icon(Icons.chevron_right, size: 20, color: AppTheme.primaryGreen.withOpacity(0.5)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('BMI', style: TextStyle(fontSize: 12, color: AppTheme.primaryGreen.withOpacity(0.8))),
                      Text(
                        '${minNormal.toStringAsFixed(1)} - ${maxNormal.toStringAsFixed(1)} kg/m²',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                latestReading != null ? bmi.toStringAsFixed(1) : '--',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'kg/m²',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondaryColor,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 3. The Visual Gauge & Labels (Combined in LayoutBuilder)
          SizedBox(
            height: 80, // Increased overall container height
            child: LayoutBuilder(builder: (context, constraints) {
                final width = constraints.maxWidth;
                
                // Dynamic Viewport
                final double minScale = math.min(15.0, bmi - 5);
                final double maxScale = math.max(overweightLimit + 5.0, bmi + 5); 
                final totalRange = maxScale - minScale;

                // Helper to get pixel position
                double getPos(double val) {
                  return ((val.clamp(minScale, maxScale) - minScale) / totalRange) * width;
                }

                // Width calculations for segments
                final uwWidth = math.max(0.0, minNormal - minScale);
                final normalWidth = math.max(0.0, maxNormal - minNormal);
                final owWidth = math.max(0.0, overweightLimit - maxNormal);

                // Helper for Labels
                Widget buildLabel(double value, String text) {
                  final pos = getPos(value);
                  // Don't show if off-screen or too close to edges (prevents clipping)
                  if (pos < 10 || pos > width - 10) return const SizedBox.shrink();
                  
                  return Positioned(
                    left: pos - 20, // Center the 40px wide text box
                    top: 60, // Adjusted for thicker bar
                    child: SizedBox(
                      width: 40,
                      child: Text(
                        text,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
                      ),
                    ),
                  );
                }

                return Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.centerLeft,
                  children: [
                    // A. The Track (Bar)
                    Positioned(
                      top: 15, // Pushed down to make room for marker
                      left: 0, 
                      right: 0,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          height: 40, // RESTORED HEIGHT
                          child: Row(
                            children: [
                              Container(width: (uwWidth / totalRange) * width, color: AppTheme.primaryBlue.withOpacity(0.3)),
                              Container(width: (normalWidth / totalRange) * width, color: AppTheme.primaryGreen.withOpacity(0.3)),
                              Container(width: (owWidth / totalRange) * width, color: AppTheme.warningColor.withOpacity(0.3)),
                              Expanded(child: Container(color: AppTheme.errorColor.withOpacity(0.3))),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // B. The Labels (Aligned to transitions)
                    // 1. Lower Target Bound (e.g. 18.5)
                    buildLabel(minNormal, minNormal.toStringAsFixed(1)),
                    // 2. Upper Target Bound (e.g. 24.9)
                    buildLabel(maxNormal, maxNormal.toStringAsFixed(1)),
                    // 3. Warning Limit (e.g. 29.9)
                    buildLabel(overweightLimit, overweightLimit.toStringAsFixed(1)),

                    // C. Marker (Only show if we have data)
                    if (latestReading != null)
                      Positioned(
                        left: getPos(bmi) - 14,
                        top: 1, // Overlaps the bar
                        child: Icon(Icons.arrow_drop_down, size: 28, color: AppTheme.textPrimaryColor),
                      ),
                  ],
                );
              }),
            ),
            const SizedBox(height: 16),

            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Text(
                category.toUpperCase(),
                style: TextStyle(
                  color: color,
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
// 2. TREND CHART (PROGRESS)
// ============================================================================

class _BmiTrendSection extends StatelessWidget {
  final List<MonitorData> readings;
  final HealthThreshold? threshold;

  const _BmiTrendSection({required this.readings, this.threshold});

  @override
  Widget build(BuildContext context) {
    // Defaults
    final minNormal = threshold?.minValue ?? 18.5;
    final maxNormal = threshold?.maxValue ?? 24.9;

    return _ChartSection(
      title: 'BMI Trends',
      icon: Icons.show_chart,
      ranges: const ['3M', '6M', '1Y', 'ALL'],
      infoText: 'Visualizes your BMI trends over time.\n\n'
          '• Y-Axis: BMI (kg/m²)\n'
          '• X-Axis: Time\n'
          '• Green Band: Normal BMI Range ($minNormal - $maxNormal).',
      allData: readings,
      builder: (range, data) {
        // Calculate X-Axis bounds with "Snap to Day/Hour" logic
        double minX, maxX;
        final now = DateTime.now();
        
        // Snap end time to next hour for clean grid lines
        final endOfWindow = DateTime(now.year, now.month, now.day, now.hour + 1);

        if (range == 'ALL') {
          if (data.isNotEmpty) {
            minX = data.first.measuredAt.millisecondsSinceEpoch.toDouble();
            maxX = endOfWindow.millisecondsSinceEpoch.toDouble();
            
            // Ensure meaningful span if only 1 data point
            if (maxX - minX < 86400000) { // < 1 day
               minX -= 2629743000; // -1 Month buffer
            }
          } else {
            maxX = endOfWindow.millisecondsSinceEpoch.toDouble();
            minX = endOfWindow.subtract(const Duration(days: 90)).millisecondsSinceEpoch.toDouble();
          }
        } else {
          maxX = endOfWindow.millisecondsSinceEpoch.toDouble();
          Duration duration;
          switch (range) {
            case '3M': duration = const Duration(days: 90); break;
            case '6M': duration = const Duration(days: 180); break;
            case '1Y': duration = const Duration(days: 365); break;
            default: duration = const Duration(days: 90); break;
          }
          minX = endOfWindow.subtract(duration).millisecondsSinceEpoch.toDouble();
        }

        double minY, maxY;
        if (data.isNotEmpty) {
          final vals = data.map((e) => e.value);
          double dataMin = vals.reduce(math.min);
          double dataMax = vals.reduce(math.max);
          minY = dataMin - 3.0;
          maxY = dataMax + 3.0;
          minY = math.min(minY, minNormal - 2.0);
          maxY = math.max(maxY, maxNormal + 2.0);
        } else {
          // Default empty bounds
          minY = minNormal - 5.0;
          maxY = maxNormal + 5.0;
        }

        // Snap to nearest 5
        minY = (minY / 5).floor() * 5.0;
        maxY = (maxY / 5).ceil() * 5.0;

        // Prevent zero-height chart if values are identical
        if (maxY == minY) maxY += 5.0;

        // Calculate interval (Fixed 4h for Daily, Dynamic for others)
        final interval = range == '1D' 
            ? 14400000.0 // 4 hours in ms
            : (maxX - minX) / (context.isMobile ? 2.5 : 4);

        return Column(
          children: [
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  clipData: const FlClipData.all(),
                  minX: minX, maxX: maxX, minY: minY, maxY: maxY,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: 5,
                    verticalInterval: interval,
                    getDrawingHorizontalLine: (_) => FlLine(color: AppTheme.getBorderColor(context).withOpacity(0.2), strokeWidth: 1),
                    getDrawingVerticalLine: (_) => FlLine(color: AppTheme.getBorderColor(context).withOpacity(0.2), strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false, reservedSize: 0)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false, reservedSize: 0)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: interval,
                        getTitlesWidget: (val, meta) {
                          // Prevent edge labels from clipping strictly at the bounds
                          final tolerance = (meta.max - meta.min) * 0.05; // 5% margin
                          if (val <= meta.min + tolerance || val >= meta.max - tolerance) {
                            return const SizedBox.shrink();
                          }

                          final date = DateTime.fromMillisecondsSinceEpoch(val.toInt());
                          final durationDays = Duration(milliseconds: (maxX - minX).toInt()).inDays;
                          
                          DateFormat fmt;
                          if (durationDays > 365) {
                            fmt = DateFormat('MMM yy');
                          } else if (durationDays >= 90) { 
                            // 3M view (90 days) should show Month (e.g. "Jan", "Feb")
                            fmt = DateFormat('MMM');
                          } else if (durationDays < 2) {
                            fmt = DateFormat('h a'); // Show time if span is very short
                          } else {
                            fmt = DateFormat('d/M');
                          }

                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              fmt.format(date),
                              style: TextStyle(
                                fontSize: 10,
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: true, border: Border.all(color: AppTheme.getBorderColor(context).withOpacity(0.5))),
                  rangeAnnotations: RangeAnnotations(
                    horizontalRangeAnnotations: [
                      HorizontalRangeAnnotation(y1: minNormal, y2: maxNormal, color: AppTheme.primaryGreen.withOpacity(0.1)),
                    ],
                  ),
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(y: minNormal, color: AppTheme.primaryGreen.withOpacity(0.8), strokeWidth: 1, dashArray: [4, 4]),
                      HorizontalLine(y: maxNormal, color: AppTheme.primaryGreen.withOpacity(0.8), strokeWidth: 1, dashArray: [4, 4]),
                    ],
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: data.map((r) => FlSpot(r.measuredAt.millisecondsSinceEpoch.toDouble(), r.value)).toList(),
                      isCurved: true,
                      color: AppTheme.primaryBlue,
                      barWidth: 2,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(radius: 3, color: AppTheme.primaryBlue, strokeColor: Colors.white, strokeWidth: 1.5),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppTheme.primaryBlue.withOpacity(0.1),
                            AppTheme.primaryBlue.withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    getTouchedSpotIndicator: (barData, spotIndexes) {
                      return spotIndexes.map((index) {
                        return TouchedSpotIndicatorData(
                          const FlLine(color: AppTheme.textSecondaryColor, strokeWidth: 1),
                          FlDotData(show: true, getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(radius: 4, color: AppTheme.primaryBlue, strokeColor: Colors.white)),
                        );
                      }).toList();
                    },
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (touchedSpot) => Colors.black.withOpacity(0.8),
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final date = DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
                          return LineTooltipItem(
                            '${DateFormat('MMM d, y').format(date)}\n',
                            const TextStyle(color: Colors.white70, fontSize: 10),
                            children: [
                              TextSpan(
                                text: '${DateFormat('h:mm a').format(date)}\n',
                                style: const TextStyle(color: Colors.white70, fontSize: 10),
                              ),
                              TextSpan(
                                text: '${spot.y.toStringAsFixed(1)} kg/m²',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12, runSpacing: 8, alignment: WrapAlignment.center,
              children: [
                const _LegendItem('Target Range', AppTheme.primaryGreen, isBox: true),
              ],
            ),
          ],
        );
      },
    );
  }
}

// ============================================================================
// 3. CORRELATION (BMI vs HbA1c)
// ============================================================================

class _BmiCorrelationSection extends StatelessWidget {
  final List<MonitorData> bmiReadings;
  final List<MonitorData> hba1cReadings;

  const _BmiCorrelationSection({
    required this.bmiReadings,
    required this.hba1cReadings,
  });

  @override
  Widget build(BuildContext context) {
    return _ChartSection(
      title: 'BMI vs. HbA1c',
      icon: Icons.insights,
      infoText: 'Compares your BMI trends against HbA1c levels over time.\n\n'
          '• Blue Line: BMI\n'
          '• Purple Line: HbA1c %\n'
          '• Goal: Observe if weight changes correlate with better blood sugar control.',
      allData: bmiReadings, // Pass BMI to drive range logic
      ranges: const ['3M', '6M', '1Y', 'ALL'],
      builder: (range, data) {
        // Calculate X-Axis bounds based on selected range
        double minX, maxX;
        final now = DateTime.now();

        if (range == 'ALL') {
          if (data.isNotEmpty) {
            minX = data.first.measuredAt.millisecondsSinceEpoch.toDouble();
            maxX = data.last.measuredAt.millisecondsSinceEpoch.toDouble();
            if (minX == maxX) {
              minX -= 2629743000; // -1 Month
              maxX += 2629743000; // +1 Month
            }
          } else {
            maxX = now.millisecondsSinceEpoch.toDouble();
            minX = now.subtract(const Duration(days: 90)).millisecondsSinceEpoch.toDouble();
          }
        } else {
          maxX = now.millisecondsSinceEpoch.toDouble();
          Duration duration;
          switch (range) {
            case '3M': duration = const Duration(days: 90); break;
            case '6M': duration = const Duration(days: 180); break;
            case '1Y': duration = const Duration(days: 365); break;
            default: duration = const Duration(days: 90); break;
          }
          minX = now.subtract(duration).millisecondsSinceEpoch.toDouble();
        }

        // Filter HbA1c based on the calculated time range
        final startDt = DateTime.fromMillisecondsSinceEpoch(minX.toInt());
        final endDt = DateTime.fromMillisecondsSinceEpoch(maxX.toInt());
        
        final displayHba1c = hba1cReadings.where((r) => 
          r.measuredAt.isAfter(startDt.subtract(const Duration(days: 7))) && 
          r.measuredAt.isBefore(endDt.add(const Duration(days: 7)))
        ).toList();

        // Dynamic Y-Axis Calculation to prevent clipping
        double minY = 15;
        double maxY = 40;
        
        if (data.isNotEmpty) {
          final bmis = data.map((e) => e.value);
          final minBmi = bmis.reduce(math.min);
          final maxBmi = bmis.reduce(math.max);
          
          if (minBmi < 15) minY = minBmi - 2;
          if (maxBmi > 40) maxY = maxBmi + 2;
        }

        // Snap to nearest 5
        minY = (minY / 5).floor() * 5.0;
        maxY = (maxY / 5).ceil() * 5.0;
        if (maxY == minY) maxY += 5.0;

        // Constants for HbA1c Scaling (map 4.0-12.0% to minY-maxY)
        final double hba1cMin = 4.0;
        final double hba1cRange = 8.0; // 12 - 4
        final double chartRange = maxY - minY;

        return Column(
          children: [
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  clipData: const FlClipData.all(),
                  minX: minX, maxX: maxX,
                  minY: minY, maxY: maxY,
                  
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false, reservedSize: 0)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false, reservedSize: 0)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: (maxX - minX) / (context.isMobile ? 2.5 : 4),
                        getTitlesWidget: (val, meta) {
                            if (val <= meta.min || val >= meta.max) return const SizedBox.shrink();

                            final date = DateTime.fromMillisecondsSinceEpoch(val.toInt());
                            // Determine format based on range
                            final durationDays = Duration(milliseconds: (maxX - minX).toInt()).inDays;
                            final fmt = (durationDays > 365 ? DateFormat('MMM yy') : DateFormat('d/M'));

                           return Padding(
                             padding: const EdgeInsets.only(top: 8.0),
                             child: Text(fmt.format(date), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                           );
                        }
                      ),
                    ),
                  ),
                  gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: AppTheme.getBorderColor(context).withOpacity(0.2), strokeWidth: 1)),
                  borderData: FlBorderData(show: true, border: Border.all(color: AppTheme.getBorderColor(context).withOpacity(0.5))),
                  lineBarsData: [
                    // BMI Line (Blue)
                    LineChartBarData(
                      spots: data.map((r) => FlSpot(r.measuredAt.millisecondsSinceEpoch.toDouble(), r.value)).toList(),
                      color: AppTheme.primaryBlue,
                      barWidth: 2,
                      isCurved: true,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                          radius: 3,
                          color: AppTheme.primaryBlue,
                          strokeColor: Colors.white,
                          strokeWidth: 1.5,
                        ),
                      ),
                    ),
                    // HbA1c Line (Purple - Scaled)
                    LineChartBarData(
                      spots: displayHba1c.map((r) {
                        // Dynamic scaling based on the calculated chart bounds
                        final scaledY = ((r.value - hba1cMin) / hba1cRange) * chartRange + minY;
                        return FlSpot(r.measuredAt.millisecondsSinceEpoch.toDouble(), scaledY);
                      }).toList(),
                      color: Colors.purple,
                      barWidth: 2,
                      isCurved: true,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                          radius: 3,
                          color: Colors.purple,
                          strokeColor: Colors.white,
                          strokeWidth: 1.5,
                        ),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    getTouchedSpotIndicator: (barData, spotIndexes) {
                      return spotIndexes.map((index) {
                        return TouchedSpotIndicatorData(
                          const FlLine(color: AppTheme.textSecondaryColor, strokeWidth: 1),
                          FlDotData(show: true, getDotPainter: (spot, percent, bar, index) {
                            // Match color of the line being touched
                            return FlDotCirclePainter(
                              radius: 4, 
                              color: barData.color ?? AppTheme.primaryBlue, 
                              strokeColor: Colors.white
                            );
                          }),
                        );
                      }).toList();
                    },
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (touchedSpot) => Colors.black.withOpacity(0.8),
                      getTooltipItems: (spots) {
                        return spots.map((spot) {
                          final date = DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
                          final dateStr = DateFormat('MMM d, y').format(date);
                          
                          if (spot.barIndex == 0) {
                            return LineTooltipItem(
                              '$dateStr\n',
                              const TextStyle(color: Colors.white70, fontSize: 10),
                              children: [
                                TextSpan(
                                  text: "BMI: ${spot.y.toStringAsFixed(1)} kg/m²",
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ],
                            );
                          } else {
                            // Reverse the scaling logic to show actual HbA1c value
                            final realVal = ((spot.y - minY) / chartRange) * hba1cRange + hba1cMin;
                            return LineTooltipItem(
                              '$dateStr\n',
                              const TextStyle(color: Colors.white70, fontSize: 10),
                              children: [
                                TextSpan(
                                  text: "HbA1c: ${realVal.toStringAsFixed(1)}%",
                                  style: const TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ],
                            );
                          }
                        }).toList();
                      }
                    )
                  )
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const _LegendItem('BMI', AppTheme.primaryBlue, isCircle: true),
                const SizedBox(width: 16),
                const _LegendItem('HbA1c', Colors.purple, isCircle: true),
              ],
            ),
          ],
        );
      },
    );
  }
}

// ============================================================================
// 4. HISTORY LIST
// ============================================================================

class _HistorySection extends StatefulWidget {
  final List<MonitorData> readings;
  final HealthThreshold? threshold;

  const _HistorySection({required this.readings, this.threshold});

  @override
  State<_HistorySection> createState() => _HistorySectionState();
}

class _HistorySectionState extends State<_HistorySection> {
  int _currentPage = 0;
  static const int _itemsPerPage = 5;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerColor = isDark ? AppTheme.midnightSurface : Colors.white;
    final borderColor = AppTheme.getBorderColor(context);

    // Defaults
    final minNormal = widget.threshold?.minValue ?? 18.5;
    final maxNormal = widget.threshold?.maxValue ?? 24.9;
    final overweightLimit = maxNormal + 5.0; // Dynamic approximation

    final reversed = widget.readings.reversed.toList();
    final totalItems = reversed.length;
    final totalPages = (totalItems / _itemsPerPage).ceil();
    
    if (_currentPage >= totalPages && totalPages > 0) _currentPage = totalPages - 1;
    if (totalPages == 0) _currentPage = 0;
    
    final start = _currentPage * _itemsPerPage;
    final end = math.min(start + _itemsPerPage, totalItems);
    final currentItems = totalItems > 0 ? reversed.sublist(start, end) : <MonitorData>[];

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
          // Header with Pagination
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.history, color: AppTheme.primaryBlue, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'History',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '${_currentPage + 1}/${totalPages > 0 ? totalPages : 1}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
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
                  "No history available",
                  style: TextStyle(color: AppTheme.textSecondaryColor),
                ),
              ),
            )
          else
            ...currentItems.map((r) {
              String label;
              Color color;
              if (r.value < minNormal) { 
                label = "LOW"; 
                color = AppTheme.primaryBlue; 
              } else if (r.value <= maxNormal) { 
                label = "NORMAL"; 
                color = AppTheme.primaryGreen; 
              } else if (r.value <= overweightLimit) { 
                label = "HIGH"; 
                color = AppTheme.warningColor; 
              } else { 
                label = "VERY HIGH"; 
                color = AppTheme.errorColor; 
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: containerColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.3)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          r.value.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.normal,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'kg/m²',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondaryColor,
                                fontSize: 12,
                              ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          DateFormat('dd/MM/yy HH:mm').format(r.measuredAt.toLocal()),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontSize: 11,
                                color: AppTheme.textSecondaryColor,
                              ),
                        ),
                      ],
                    )
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ============================================================================
// HELPERS
// ============================================================================

class _BmiCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String infoText;
  final Widget child;

  const _BmiCard({required this.title, required this.icon, required this.infoText, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
              Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))),
              IconButton(
                icon: Icon(Icons.info_outline, color: AppTheme.textSecondaryColor, size: 20),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: Theme.of(context).cardColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: Row(
                        children: [
                          Icon(icon, color: AppTheme.primaryBlue),
                          const SizedBox(width: 12),
                          Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))),
                        ],
                      ),
                      content: Text(infoText, style: Theme.of(context).textTheme.bodyMedium),
                      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Got it"))],
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;
  final bool isBox;
  final bool isCircle;
  final bool isDashed;

  const _LegendItem(this.label, this.color, {this.isBox = false, this.isCircle = false, this.isDashed = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isBox)
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)))
        else if (isCircle)
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle))
        else if (isDashed)
          SizedBox(width: 16, height: 2, child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Container(width: 4, height: 2, color: color), Container(width: 4, height: 2, color: color), Container(width: 4, height: 2, color: color)]))
        else
          Container(width: 12, height: 2, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}
