import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../config/routes.dart';
import '../../../../config/routes.dart';
import '../../../../config/routes.dart';
import '../../../../config/routes.dart';
import '../../../../config/routes.dart';
import '../../../../config/routes.dart';
import '../../../../config/theme.dart';
import '../../../../core/layout/responsive_layout_system.dart';
import '../../core/models/health_data_models.dart';
import '../../core/providers/monitor_data_providers.dart' as core_data;
import '../../dashboard/providers/dashboard_providers.dart';

class GlucoseDetailScreen extends ConsumerWidget {
  const GlucoseDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glucoseAsync = ref.watch(monitorDataProvider);
    final thresholdsAsync = ref.watch(patientThresholdsProvider);
    final dailyLogsAsync = ref.watch(dailyPatientLogsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Glucose Analytics'),
        elevation: 0,
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => AppRoutes.push(context, AppRoutes.logGlucose),
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
      body: glucoseAsync.when(
        data: (dataList) {
          // 1. Global Data Prep
          // Filter glucose readings from the consolidated dataList
          final allReadings = dataList
              .where((d) => d.dataType == MonitorDataType.GLUCOSE)
              .toList();

          // Sort ascending for charts logic (Timeline needs X-axis increasing)
          allReadings.sort((a, b) => a.measuredAt.compareTo(b.measuredAt));

          final thresholds = thresholdsAsync.value ?? [];
          
          // Check if user actually has a set threshold
          HealthThreshold? userThreshold;
          try {
            userThreshold = thresholds.firstWhere((t) => t.dataType == MonitorDataType.GLUCOSE);
          } catch (_) {}

          final isDefault = userThreshold == null;
          
          // Use user's threshold or safe default
          final effectiveThreshold = userThreshold;

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
                      padding: const EdgeInsets.all(20.0),
                      child: context.isDesktop
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left Column
                                Expanded(
                                  child: Column(
                                    children: [
                                      _StatisticsSection(
                                        readings: allReadings,
                                        threshold: effectiveThreshold,
                                        isDefault: isDefault,
                                      ),
                                      const SizedBox(height: 20),
                                      _GlucoseTrendsSection(
                                        allReadings: allReadings,
                                        threshold: effectiveThreshold,
                                        isDefault: isDefault,
                                      ),
                                      const SizedBox(height: 20),
                                      _TimeInRangeSection(
                                        readings: allReadings,
                                        threshold: effectiveThreshold,
                                        isDefault: isDefault,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 20),
                                // Right Column
                                Expanded(
                                  child: Column(
                                    children: [
                                      _ModalDaySection(
                                        allReadings: allReadings,
                                        threshold: effectiveThreshold,
                                        isDefault: isDefault,
                                      ),
                                      const SizedBox(height: 20),
                                      _HistorySection(
                                        allReadings: allReadings,
                                        thresholds: thresholds,
                                      ),
                                      const SizedBox(height: 24),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _StatisticsSection(
                                  readings: allReadings,
                                  threshold: effectiveThreshold,
                                  isDefault: isDefault,
                                ),
                                const SizedBox(height: 20),
                                _GlucoseTrendsSection(
                                  allReadings: allReadings,
                                  threshold: effectiveThreshold,
                                  isDefault: isDefault,
                                ),
                                const SizedBox(height: 20),
                                _TimeInRangeSection(
                                  readings: allReadings,
                                  threshold: effectiveThreshold,
                                  isDefault: isDefault,
                                ),
                                const SizedBox(height: 20),
                                _ModalDaySection(
                                  allReadings: allReadings,
                                  threshold: effectiveThreshold,
                                  isDefault: isDefault,
                                ),
                                const SizedBox(height: 20),
                                _HistorySection(
                                  allReadings: allReadings,
                                  thresholds: thresholds,
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
        error: (err, stack) => Center(child: Text('Error loading glucose: $err')),
      ),
    );
  }
}

/// Reusable Wrapper with Styled Info
class _ChartSection extends StatefulWidget {
  final String title;
  final IconData icon;
  final String infoText;
  final Widget Function(String range, List<MonitorData> filteredData) builder;
  final List<MonitorData> allData;
  final List<String> ranges; // Internal keys: 1D, 7D, 14D, 30D

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

  List<MonitorData> _filterData() {
    if (widget.allData.isEmpty) return [];
    final now = DateTime.now();
    
    if (_selectedRange == '1D') {
      // For Daily, filter from start of TODAY (00:00) to show calendar day
      final startOfDay = DateTime(now.year, now.month, now.day);
      return widget.allData.where((d) => d.measuredAt.isAfter(startOfDay)).toList();
    }

    Duration duration;
    switch (_selectedRange) {
      case '7D': duration = const Duration(days: 7); break;
      case '14D': duration = const Duration(days: 14); break;
      case '30D': duration = const Duration(days: 30); break;
      default: duration = const Duration(days: 7); break;
    }
    final cutoff = now.subtract(duration);
    return widget.allData.where((d) => d.measuredAt.isAfter(cutoff)).toList();
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

  void _showInfoDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it', style: TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.icon, color: AppTheme.primaryBlue, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: Icon(Icons.info_outline, color: AppTheme.textSecondaryColor, size: 20),
                onPressed: () => _showInfoDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Timeline Tabs
          Container(
            height: 36,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: widget.ranges.map((range) {
                final isSelected = _selectedRange == range;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedRange = range),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getRangeLabel(range),
                        style: TextStyle(
                          fontSize: 11, // Smaller text to fit words
                          fontWeight: FontWeight.w600,
                          color: isSelected 
                            ? Colors.white 
                            : Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // Content
          widget.builder(_selectedRange, filteredData),
        ],
      ),
    );
  }
}

// ============================================================================
// SECTION 1: STATISTICS SUMMARY
// ============================================================================

class _StatisticsSection extends StatelessWidget {
  final List<MonitorData> readings;
  final HealthThreshold? threshold;
  final bool isDefault;

  const _StatisticsSection({
    required this.readings, 
    this.threshold,
    this.isDefault = false,
  });

  Map<String, dynamic> _calculateStats(List<MonitorData> data) {
    if (data.isEmpty) return {'avg': 0.0, 'gmi': 0.0, 'cv': 0.0};
    final values = data.map((e) => e.value).toList();
    final avg = values.reduce((a, b) => a + b) / values.length;
    final variance = values.map((v) => math.pow(v - avg, 2)).reduce((a, b) => a + b) / values.length;
    final stdDev = math.sqrt(variance);
    final cv = (stdDev / avg) * 100;
    final gmi = 3.31 + (0.02392 * avg);
    return {'avg': avg, 'gmi': gmi, 'cv': cv};
  }

  @override
  Widget build(BuildContext context) {
    return _ChartSection(
      title: 'Overview',
      icon: Icons.analytics_outlined,
      infoText: 'Key statistics derived from your glucose readings.\n\n'
                '• Average: Mean glucose level.\n'
                '• GMI: Glucose Management Indicator (Estimated A1c).\n'
                '• CV: Coefficient of Variation. Target < 36% for stable control.\n'
                '• Target: Your configured safe range.',
      allData: readings,
      builder: (range, data) {
        final stats = _calculateStats(data);
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
                  border: Border.all(
                    color: AppTheme.primaryGreen.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.track_changes,
                              size: 18,
                              color: AppTheme.primaryGreen,
                            ),
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
                        Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: AppTheme.primaryGreen.withOpacity(0.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (threshold != null)
                      _buildMiniTargetRow(
                        'Glucose',
                        '${threshold!.minValue.toInt()} - ${threshold!.maxValue.toInt()} mg/dL',
                        AppTheme.primaryGreen,
                      )
                    else
                      _buildMiniTargetRow(
                        'Glucose',
                        'Not Set',
                        AppTheme.textSecondaryColor,
                      ),
                  ],
                ),
              ),
            ),
            // Statistics Row
            Row(
              children: [
                Expanded(child: _buildStatBox(context, 'Average', (stats['avg'] as double) > 0 ? (stats['avg'] as double).toStringAsFixed(0) : '--', 'mg/dL', Colors.blue)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatBox(context, 'GMI', (stats['gmi'] as double) > 0 ? (stats['gmi'] as double).toStringAsFixed(1) : '--', '%', Colors.purple)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatBox(context, 'Variability', (stats['cv'] as double) > 0 ? (stats['cv'] as double).toStringAsFixed(1) : '--', '%', threshold != null ? ((stats['cv'] as double) < 36 ? AppTheme.successColor : AppTheme.warningColor) : AppTheme.textSecondaryColor)),
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

// ============================================================================
// SECTION 2: ANNOTATED GLUCOSE TRENDS
// ============================================================================

class _GlucoseTrendsSection extends StatelessWidget {
  final List<MonitorData> allReadings;
  final HealthThreshold? threshold;
  final bool isDefault;

  const _GlucoseTrendsSection({
    required this.allReadings,
    this.threshold,
    this.isDefault = false,
  });

  @override
  Widget build(BuildContext context) {
    return _ChartSection(
      title: 'Glucose Trends',
      icon: Icons.show_chart,
      infoText: 'Visualizes your glucose readings over time.\n\n'
                '• Y-Axis: Glucose (mg/dL)\n'
                '• X-Axis: Time\n'
                '• Green Band: Readings within your target safe zone.',
      allData: allReadings,
      builder: (range, data) {
        // Enforce a fixed time window based on selected range (1D, 7D, etc.)
        final now = DateTime.now();
        
        DateTime startOfWindow;
        DateTime endOfWindow;
        double interval;
        DateFormat dateFormat;

        if (range == '1D') {
          // Fixed Today View (00:00 to 24:00)
          startOfWindow = DateTime(now.year, now.month, now.day);
          endOfWindow = startOfWindow.add(const Duration(days: 1));
          interval = 14400000; // 4 hours
          dateFormat = DateFormat('h a');
        } else {
          // Rolling Window for others (e.g., last 7 days ending now)
          // Snap 'now' to next hour to avoid odd minutes
          endOfWindow = DateTime(now.year, now.month, now.day, now.hour + 1);
          
          switch (range) {
            case '7D':
              startOfWindow = endOfWindow.subtract(const Duration(days: 7));
              interval = 86400000; // 1 day
              dateFormat = DateFormat('M/d');
              break;
            case '14D':
              startOfWindow = endOfWindow.subtract(const Duration(days: 14));
              interval = 172800000; // 2 days
              dateFormat = DateFormat('M/d');
              break;
            case '30D':
              startOfWindow = endOfWindow.subtract(const Duration(days: 30));
              interval = 432000000; // 5 days
              dateFormat = DateFormat('M/d');
              break;
            default:
              startOfWindow = endOfWindow.subtract(const Duration(days: 7));
              interval = 86400000;
              dateFormat = DateFormat('M/d');
          }
        }

        final double minX = startOfWindow.millisecondsSinceEpoch.toDouble();
        final double maxX = endOfWindow.millisecondsSinceEpoch.toDouble();

        // Determine Y-Axis range
        double minY = threshold != null ? (threshold!.minValue - 20).clamp(0, double.infinity) : 60;
        double maxY = threshold != null ? threshold!.maxValue + 40 : 200;
        
        if (data.isNotEmpty) {
          double dataMin = data.map((e) => e.value).reduce(math.min);
          double dataMax = data.map((e) => e.value).reduce(math.max);
          minY = math.min(minY, dataMin - 10);
          maxY = math.max(maxY, dataMax + 10);
        }

        // Snap to grid (50) to ensure equal spacing
        minY = (minY / 50).floor() * 50.0;
        maxY = (maxY / 50).ceil() * 50.0;
        if (maxY == minY) maxY += 50;

        return Column(
          children: [
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  minX: minX, maxX: maxX, minY: minY, maxY: maxY,
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
                        reservedSize: 30,
                        interval: interval,
                        getTitlesWidget: (val, meta) {
                          // Prevent edge labels from clipping strictly at the bounds
                          if (val <= meta.min || val >= meta.max) {
                            return const SizedBox.shrink();
                          }

                          final date = DateTime.fromMillisecondsSinceEpoch(val.toInt());
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              dateFormat.format(date),
                              style: TextStyle(
                                fontSize: 10,
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true, border: Border.all(color: AppTheme.getBorderColor(context).withOpacity(0.5))),
                  // 1. Safe Zone Background (Green Band)
                  rangeAnnotations: threshold != null ? RangeAnnotations(
                    horizontalRangeAnnotations: [
                      HorizontalRangeAnnotation(
                        y1: threshold!.minValue, 
                        y2: threshold!.maxValue, 
                        color: AppTheme.primaryGreen.withOpacity(0.1)
                      )
                    ],
                  ) : null,
                  
                  // 2. Dotted Lines for Thresholds (Matches Trends)
                  extraLinesData: threshold != null ? ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(y: threshold!.minValue, color: AppTheme.primaryGreen.withOpacity(0.8), strokeWidth: 1, dashArray: [4, 4]),
                      HorizontalLine(y: threshold!.maxValue, color: AppTheme.primaryGreen.withOpacity(0.8), strokeWidth: 1, dashArray: [4, 4]),
                    ],
                  ) : null,
                  lineBarsData: [
                    LineChartBarData(
                      spots: data.map((r) => FlSpot(r.measuredAt.millisecondsSinceEpoch.toDouble(), r.value)).toList(),
                      isCurved: true,
                      color: AppTheme.primaryBlue,
                      barWidth: 2,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                          radius: 3, // Visible dots
                          color: AppTheme.primaryBlue,
                          strokeWidth: 1.5,
                          strokeColor: Colors.white,
                        ),
                      ),
                      belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [AppTheme.primaryBlue.withOpacity(0.1), AppTheme.primaryBlue.withOpacity(0)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
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
                          // Include Date, Time, Value, and Unit
                          return LineTooltipItem(
                            '${DateFormat('MMM d, y').format(date)}\n', // Date Line
                            const TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                              fontSize: 10,
                            ),
                            children: [
                              TextSpan(
                                text: '${DateFormat('h:mm a').format(date)}\n', // Time Line
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                ),
                              ),
                              TextSpan(
                                text: '${spot.y.toInt()} mg/dL', // Value + Unit
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  height: 1.5,
                                ),
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
            if (threshold != null) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 12, runSpacing: 8, alignment: WrapAlignment.center,
                children: [
                  _buildLegendItem('Target Range', AppTheme.primaryGreen.withOpacity(0.5), isBox: true),
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  static Widget _emptyTitle(double value, TitleMeta meta) => const SizedBox.shrink();
}

// ============================================================================
// SECTION 3: TIME IN RANGE
// ============================================================================

class _TimeInRangeSection extends StatelessWidget {
  final List<MonitorData> readings;
  final HealthThreshold? threshold;
  final bool isDefault;

  const _TimeInRangeSection({
    required this.readings,
    this.threshold,
    this.isDefault = false,
  });

  @override
  Widget build(BuildContext context) {
    return _ChartSection(
      title: 'Time in Range',
      icon: Icons.track_changes_outlined,
      infoText: 'Percentage of time your glucose is within target.\n\n'
                'Goal: Keep "In Range" (Green) above 70%.',
      allData: readings,
      builder: (range, data) {
        if (threshold == null) {
          return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('Set target to view time in range.')));
        }

        final total = data.length;
        final lows = data.where((r) => r.value < threshold!.minValue).length;
        final highs = data.where((r) => r.value > threshold!.maxValue).length;
        final inRange = total - lows - highs;
        
        final lowPct = total > 0 ? (lows / total) * 100 : 0.0;
        final highPct = total > 0 ? (highs / total) * 100 : 0.0;
        final inPct = total > 0 ? (inRange / total) * 100 : 0.0;

        return Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 36,
                child: total == 0 
                  ? Container(color: Colors.grey.shade200) // Empty state
                  : Row(
                      children: [
                        if (lowPct > 0) Expanded(flex: (lowPct * 10).toInt(), child: Container(color: AppTheme.errorColor)),
                        if (inPct > 0) Expanded(flex: (inPct * 10).toInt(), child: Container(color: AppTheme.primaryGreen)),
                        if (highPct > 0) Expanded(flex: (highPct * 10).toInt(), child: Container(color: AppTheme.errorColor)),
                      ],
                    ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTIRLegend(context, 'Low', lowPct, AppTheme.errorColor),
                _buildTIRLegend(context, 'In Range', inPct, AppTheme.primaryGreen, isBig: true),
                _buildTIRLegend(context, 'High', highPct, AppTheme.errorColor),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildTIRLegend(BuildContext context, String label, double val, Color color, {bool isBig = false}) {
    return Column(
      children: [
        Text(
          '${val.toStringAsFixed(0)}%',
          style: TextStyle(fontSize: isBig ? 20 : 16, fontWeight: FontWeight.bold, color: color),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

// ============================================================================
// SECTION 4: MODAL DAY
// ============================================================================

class _ModalDaySection extends StatelessWidget {
  final List<MonitorData> allReadings;
  final HealthThreshold? threshold;
  final bool isDefault;

  const _ModalDaySection({
    required this.allReadings, 
    this.threshold,
    this.isDefault = false,
  });

  @override
  Widget build(BuildContext context) {
    return _ChartSection(
      title: 'Daily Patterns',
      icon: Icons.auto_graph_outlined,
      infoText: 'Overlays multiple days onto a single 24h axis to spot recurring patterns.\n\n'
                '• Y-Axis: Glucose (mg/dL)\n'
                '• X-Axis: Hour of day (0-24)\n'
                '• Green Band: Readings within your target safe zone.',
      allData: allReadings,
      builder: (range, data) {
        final Map<int, List<FlSpot>> lines = {};
        for (var r in data) {
          // Convert to local time so the hour (0-24) matches the user's timezone
          final localDate = r.measuredAt.toLocal();
          
          // Use unique date identifier (YYYYMMDD) so distinct days don't merge
          final key = localDate.year * 10000 + localDate.month * 100 + localDate.day;
          final x = localDate.hour + (localDate.minute / 60.0);
          lines.putIfAbsent(key, () => []).add(FlSpot(x, r.value));
        }
        List<LineChartBarData> chartLines = [];
        lines.forEach((_, spots) {
          spots.sort((a, b) => a.x.compareTo(b.x));
          chartLines.add(LineChartBarData(
            spots: spots, 
            isCurved: true, 
            color: AppTheme.textSecondaryColor.withOpacity(0.3), 
            barWidth: 1.5, 
            // Enable dots so single readings are visible
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                radius: 2,
                color: AppTheme.textSecondaryColor.withOpacity(0.5),
                strokeWidth: 0,
              ),
            ),
          ));
        });

        // CRITICAL FIX: If no data, add an empty series to force chart lines/grid to render
        if (chartLines.isEmpty) {
          chartLines.add(LineChartBarData(
            spots: [], // No dummy points, just an empty series
            color: Colors.transparent,
          ));
        }

        return Column(
          children: [
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  minX: 0, maxX: 24, minY: 40, maxY: 250,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true, // Enabled vertical grid
                    horizontalInterval: 50,
                    verticalInterval: 6,
                    getDrawingHorizontalLine: (_) => FlLine(color: AppTheme.getBorderColor(context).withOpacity(0.2), strokeWidth: 1),
                    getDrawingVerticalLine: (_) => FlLine(color: AppTheme.getBorderColor(context).withOpacity(0.2), strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    // Hide Y Axis Labels
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, interval: 6, getTitlesWidget: (v, _) {
                        if (v == 0 || v == 24) return const SizedBox(); // Hide first & last
                        return Text('${v.toInt()}:00', style: const TextStyle(fontSize: 9));
                      }),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    // Hide Right Axis Labels
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true, border: Border.all(color: AppTheme.getBorderColor(context).withOpacity(0.5))),
                  rangeAnnotations: threshold != null ? RangeAnnotations(
                    horizontalRangeAnnotations: [HorizontalRangeAnnotation(y1: threshold!.minValue, y2: threshold!.maxValue, color: AppTheme.primaryGreen.withOpacity(0.1))],
                  ) : null,
                  extraLinesData: threshold != null ? ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(y: threshold!.minValue, color: AppTheme.primaryGreen.withOpacity(0.8), strokeWidth: 1, dashArray: [4, 4]),
                      HorizontalLine(y: threshold!.maxValue, color: AppTheme.primaryGreen.withOpacity(0.8), strokeWidth: 1, dashArray: [4, 4]),
                    ],
                  ) : null,
                  lineBarsData: chartLines,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Legend
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (threshold != null) ...[
                _buildLegendItem('Target Range', AppTheme.primaryGreen.withOpacity(0.5), isBox: true),
                const SizedBox(width: 12),
              ],
              _buildLegendItem('Daily Traces', AppTheme.textSecondaryColor, isDashed: false),
            ]),
          ],
        );
      },
    );
  }
}

// ============================================================================
// SECTION 5: HISTORY
// ============================================================================

class _HistorySection extends StatefulWidget {
  final List<MonitorData> allReadings;
  final List<HealthThreshold> thresholds;

  const _HistorySection({required this.allReadings, required this.thresholds});

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

    // Data is passed sorted ASC by parent. Reverse it here for Latest First.
    final sortedReadings = widget.allReadings.reversed.toList();

    final totalItems = sortedReadings.length;
    final totalPages = (totalItems / _itemsPerPage).ceil();
    if (_currentPage >= totalPages && totalPages > 0) _currentPage = totalPages - 1;
    
    final start = _currentPage * _itemsPerPage;
    final end = math.min(start + _itemsPerPage, totalItems);
    final currentItems = sortedReadings.sublist(start, end);

    // Get threshold from backend data (no fallback)
    HealthThreshold? t;
    try {
      t = widget.thresholds.firstWhere((t) => t.dataType == MonitorDataType.GLUCOSE);
    } catch (_) {}

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppTheme.primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.history, color: AppTheme.primaryBlue, size: 24)),
                  const SizedBox(width: 12),
                  Text('History', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              // Navigation arrows
              Row(children: [
                IconButton(onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null, icon: const Icon(Icons.chevron_left)),
                Text('${_currentPage + 1}/$totalPages', style: const TextStyle(fontWeight: FontWeight.bold)),
                IconButton(onPressed: _currentPage < totalPages - 1 ? () => setState(() => _currentPage++) : null, icon: const Icon(Icons.chevron_right)),
              ]),
            ],
          ),
          const SizedBox(height: 20),
          ...currentItems.map((item) {
            // Unique Status Logic for Glucose
            // LOW (< Min) = Critical/Red
            // HIGH (> Max) = Warning/Amber
            // NORMAL = Green
            
            String statusText;
            Color statusColor;
            
            if (t != null) {
              if (item.value < t.minValue) {
                statusText = 'LOW';
                statusColor = AppTheme.errorColor;
              } else if (item.value > t.maxValue) {
                statusText = 'HIGH';
                statusColor = AppTheme.errorColor;
              } else {
                statusText = 'NORMAL';
                statusColor = AppTheme.primaryGreen;
              }
            } else {
              statusText = 'RECORDED';
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
                  width: 1
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
                        item.value.toStringAsFixed(0),
                        style: TextStyle(
                          fontWeight: FontWeight.normal, 
                          fontSize: 20,
                          color: AppTheme.textPrimaryColor
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'mg/dL', 
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondaryColor,
                          fontSize: 12
                        )
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
                          borderRadius: BorderRadius.circular(8)
                        ),
                        child: Text(
                          statusText, 
                          style: TextStyle(
                            color: statusColor, 
                            fontSize: 10, 
                            fontWeight: FontWeight.bold
                          )
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        DateFormat('dd/MM/yy HH:mm').format(item.measuredAt.toLocal()), 
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: AppTheme.textSecondaryColor
                        )
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

// --- GLOBAL HELPERS ---

Widget _buildLegendItem(String label, Color color, {bool isBox = false, bool isDashed = false}) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (isBox)
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)))
      else if (isDashed)
        Container(width: 2, height: 12, color: color)
      else
        Container(width: 12, height: 2, color: color),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 10)),
    ],
  );
}
