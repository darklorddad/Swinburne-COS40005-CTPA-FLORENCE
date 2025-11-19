import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../../../../config/theme.dart';
import '../../core/models/health_data_models.dart';
import '../../dashboard/providers/dashboard_providers.dart';

class GlucoseDetailScreen extends ConsumerWidget {
  final int patientId;

  const GlucoseDetailScreen({super.key, required this.patientId});

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
          return dailyLogsAsync.when(
            data: (mealLogs) {
              // 1. Global Data Prep
              final allReadings = dataList
                  .where((d) => d.dataType == MonitorDataType.GLUCOSE)
                  .toList();

              if (allReadings.isEmpty) {
                return const Center(child: Text('No glucose data available'));
              }
              // Sort ascending for charts logic (Timeline needs X-axis increasing)
              allReadings.sort((a, b) => a.measuredAt.compareTo(b.measuredAt));

              final thresholds = thresholdsAsync.value ?? [];
              final glucoseThreshold = thresholds.firstWhere(
                (t) => t.dataType == MonitorDataType.GLUCOSE,
                orElse: () => const HealthThreshold(
                    dataType: MonitorDataType.GLUCOSE,
                    minValue: 70,
                    maxValue: 180),
              );

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Statistics
                    _StatisticsSection(
                      readings: allReadings, 
                      threshold: glucoseThreshold
                    ),
                    const SizedBox(height: 20),

                    // 2. Annotated Line Chart
                    _GlucoseTrendsSection(
                      allReadings: allReadings,
                      allMeals: mealLogs,
                      threshold: glucoseThreshold,
                    ),
                    const SizedBox(height: 20),

                    // 3. Time in Range
                    _TimeInRangeSection(
                      allReadings: allReadings,
                      threshold: glucoseThreshold,
                    ),
                    const SizedBox(height: 20),

                    // 4. Modal Day
                    _ModalDaySection(
                      allReadings: allReadings,
                      threshold: glucoseThreshold,
                    ),
                    const SizedBox(height: 20),

                    // 5. History List
                    _HistorySection(
                      allReadings: allReadings, // Pass sorted list, we will reverse it inside
                      thresholds: thresholds,
                    ),
                    
                    // Bottom Spacing to match Dashboard
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error loading logs: $err')),
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
    Duration duration;
    switch (_selectedRange) {
      case '7D': duration = const Duration(days: 7); break;
      case '14D': duration = const Duration(days: 14); break;
      case '30D': duration = const Duration(days: 30); break;
      case '1D':
      default: duration = const Duration(hours: 24); break;
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
            Expanded(child: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold))),
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
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
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
  final HealthThreshold threshold;

  const _StatisticsSection({required this.readings, required this.threshold});

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
                '• CV: Coefficient of Variation. Target < 36% for stable control.\n\n'
                'Your Target Range: ${threshold.minValue.toInt()} - ${threshold.maxValue.toInt()} mg/dL.',
      allData: readings,
      builder: (range, data) {
        final stats = _calculateStats(data);
        return Row(
          children: [
            Expanded(child: _buildStatBox(context, 'Average', '${(stats['avg'] as double).toStringAsFixed(0)}', 'mg/dL', Colors.blue)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatBox(context, 'GMI', '${(stats['gmi'] as double).toStringAsFixed(1)}', '%', Colors.purple)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatBox(context, 'Variability', '${(stats['cv'] as double).toStringAsFixed(1)}', '%', (stats['cv'] as double) < 36 ? AppTheme.successColor : AppTheme.warningColor)),
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
          Text(title, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10)),
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
  final List<DailyPatientLog> allMeals;
  final HealthThreshold threshold;

  const _GlucoseTrendsSection({
    required this.allReadings,
    required this.allMeals,
    required this.threshold,
  });

  @override
  Widget build(BuildContext context) {
    return _ChartSection(
      title: 'Glucose Trends',
      icon: Icons.show_chart,
      infoText: 'Visualizes your glucose readings.\n\n'
                '• Green Band: Your target range (${threshold.minValue.toInt()}-${threshold.maxValue.toInt()} mg/dL).\n'
                '• Vertical Dashed Lines: Logged Meals.',
      allData: allReadings,
      builder: (range, data) {
        if (data.isEmpty) return const SizedBox(height: 200, child: Center(child: Text('No data')));

        final minDate = data.first.measuredAt;
        final relevantMeals = allMeals.where((m) => m.logDate.isAfter(minDate)).toList();

        double minX = data.first.measuredAt.millisecondsSinceEpoch.toDouble();
        double maxX = data.last.measuredAt.millisecondsSinceEpoch.toDouble();
        if (minX == maxX) { minX -= 3600000; maxX += 3600000; }

        double minY = (threshold.minValue - 20).clamp(0, double.infinity);
        double maxY = threshold.maxValue + 40;
        double dataMin = data.map((e) => e.value).reduce(math.min);
        double dataMax = data.map((e) => e.value).reduce(math.max);
        minY = math.min(minY, dataMin - 10);
        maxY = math.max(maxY, dataMax + 10);

        // Centering Logic: Ensure leftTitles reservedSize matches a hidden rightTitles
        const double yAxisWidth = 35.0;

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
                    // Left Titles
                    leftTitles: AxisTitles(
                      axisNameWidget: Text('Glucose (mg/dL)', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10)),
                      axisNameSize: 20,
                      sideTitles: SideTitles(
                        showTitles: true, 
                        reservedSize: yAxisWidth, 
                        interval: 50, 
                        getTitlesWidget: (val, _) => Text(val.toInt().toString(), style: const TextStyle(fontSize: 9)),
                      ),
                    ),
                    // Bottom Titles
                    bottomTitles: AxisTitles(
                      axisNameWidget: Padding(padding: const EdgeInsets.only(top: 4), child: Text('Time', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10))),
                      axisNameSize: 20,
                      sideTitles: SideTitles(
                        showTitles: true, 
                        interval: (maxX - minX) / 4, 
                        getTitlesWidget: (val, _) {
                          final date = DateTime.fromMillisecondsSinceEpoch(val.toInt());
                          final fmt = range == '1D' ? DateFormat('HH:mm') : DateFormat('MM/dd');
                          return Padding(padding: const EdgeInsets.only(top: 8), child: Text(fmt.format(date), style: const TextStyle(fontSize: 9)));
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    // Right Titles (Invisible but reserved space to center graph)
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: yAxisWidth, getTitlesWidget: _emptyTitle),
                    ),
                  ),
                  borderData: FlBorderData(show: true, border: Border.all(color: AppTheme.getBorderColor(context).withOpacity(0.5))),
                  rangeAnnotations: RangeAnnotations(
                    horizontalRangeAnnotations: [HorizontalRangeAnnotation(y1: threshold.minValue, y2: threshold.maxValue, color: AppTheme.primaryGreen.withOpacity(0.1))],
                  ),
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(y: threshold.minValue, color: AppTheme.primaryGreen.withOpacity(0.8), strokeWidth: 1, dashArray: [4, 4]),
                      HorizontalLine(y: threshold.maxValue, color: AppTheme.primaryGreen.withOpacity(0.8), strokeWidth: 1, dashArray: [4, 4]),
                    ],
                    verticalLines: relevantMeals.map((m) => VerticalLine(
                      x: m.logDate.millisecondsSinceEpoch.toDouble(),
                      color: _getMealColor(m.mealTime).withOpacity(0.8),
                      strokeWidth: 2, // Thicker line
                      dashArray: [4, 4],
                      label: VerticalLineLabel(show: true, labelResolver: (_) => m.mealTime[0], style: TextStyle(color: _getMealColor(m.mealTime), fontSize: 9, fontWeight: FontWeight.bold)),
                    )).toList(),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: data.map((r) => FlSpot(r.measuredAt.millisecondsSinceEpoch.toDouble(), r.value)).toList(),
                      isCurved: true,
                      color: AppTheme.primaryBlue,
                      barWidth: 2,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                          radius: 2.5,
                          color: AppTheme.primaryBlue,
                          strokeWidth: 1,
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
                          const FlLine(color: AppTheme.textSecondaryColor, strokeWidth: 1), // Thinner line
                          FlDotData(show: true, getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(radius: 4, color: AppTheme.primaryBlue, strokeColor: Colors.white)),
                        );
                      }).toList();
                    },
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => Colors.black.withOpacity(0.8), // Black transparent background
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          return LineTooltipItem(
                            '${spot.y.toInt()}',
                            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                _buildLegendItem('Safe Zone', AppTheme.primaryGreen.withOpacity(0.5), isBox: true),
                _buildLegendItem('Breakfast', Colors.orange, isDashed: true),
                _buildLegendItem('Lunch', Colors.blue, isDashed: true),
                _buildLegendItem('Dinner', Colors.purple, isDashed: true),
              ],
            ),
          ],
        );
      },
    );
  }

  static Widget _emptyTitle(double value, TitleMeta meta) => const SizedBox.shrink();

  Color _getMealColor(String meal) {
    final m = meal.toUpperCase();
    if (m.contains('BREAKFAST')) return Colors.orange;
    if (m.contains('LUNCH')) return Colors.blue;
    if (m.contains('DINNER')) return Colors.purple;
    return Colors.grey;
  }
}

// ============================================================================
// SECTION 3: TIME IN RANGE
// ============================================================================

class _TimeInRangeSection extends StatelessWidget {
  final List<MonitorData> allReadings;
  final HealthThreshold threshold;

  const _TimeInRangeSection({required this.allReadings, required this.threshold});

  @override
  Widget build(BuildContext context) {
    return _ChartSection(
      title: 'Time in Range',
      icon: Icons.track_changes_outlined,
      infoText: 'Your Target Range: ${threshold.minValue.toInt()} - ${threshold.maxValue.toInt()} mg/dL.\n\n'
                'Goal: Keep "In Range" (Green) above 70%.',
      allData: allReadings,
      builder: (range, data) {
        if (data.isEmpty) return const SizedBox(height: 100, child: Center(child: Text('No data')));

        final total = data.length;
        final lows = data.where((r) => r.value < threshold.minValue).length;
        final highs = data.where((r) => r.value > threshold.maxValue).length;
        final inRange = total - lows - highs;
        
        final lowPct = (lows / total) * 100;
        final highPct = (highs / total) * 100;
        final inPct = (inRange / total) * 100;

        return Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 36,
                child: Row(
                  children: [
                    if (lowPct > 0) Expanded(flex: (lowPct * 10).toInt(), child: Container(color: AppTheme.errorColor)),
                    if (inPct > 0) Expanded(flex: (inPct * 10).toInt(), child: Container(color: AppTheme.primaryGreen)),
                    if (highPct > 0) Expanded(flex: (highPct * 10).toInt(), child: Container(color: AppTheme.warningColor)),
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
                _buildTIRLegend(context, 'High', highPct, AppTheme.warningColor),
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
  final HealthThreshold threshold;

  const _ModalDaySection({required this.allReadings, required this.threshold});

  @override
  Widget build(BuildContext context) {
    const double yAxisWidth = 35.0;
    
    return _ChartSection(
      title: 'Daily Patterns',
      icon: Icons.auto_graph_outlined,
      infoText: 'Overlays multiple days onto a single 24h axis to spot recurring patterns.',
      allData: allReadings,
      builder: (range, data) {
        if (data.isEmpty) return const SizedBox(height: 200, child: Center(child: Text('No data')));

        final Map<int, List<FlSpot>> lines = {};
        for (var r in data) {
          final key = r.measuredAt.day;
          final x = r.measuredAt.hour + (r.measuredAt.minute / 60.0);
          lines.putIfAbsent(key, () => []).add(FlSpot(x, r.value));
        }
        List<LineChartBarData> chartLines = [];
        lines.forEach((_, spots) {
          spots.sort((a, b) => a.x.compareTo(b.x));
          chartLines.add(LineChartBarData(spots: spots, isCurved: true, color: AppTheme.textSecondaryColor.withOpacity(0.3), barWidth: 1.5, dotData: const FlDotData(show: false)));
        });

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
                    leftTitles: AxisTitles(
                      axisNameWidget: Text('Glucose', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10)),
                      axisNameSize: 20,
                      sideTitles: SideTitles(showTitles: true, reservedSize: yAxisWidth, interval: 50, getTitlesWidget: (v, _) => Text(v.toInt().toString(), style: const TextStyle(fontSize: 9))),
                    ),
                    bottomTitles: AxisTitles(
                      axisNameWidget: Padding(padding: const EdgeInsets.only(top: 4), child: Text('Hour', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10))),
                      axisNameSize: 20,
                      sideTitles: SideTitles(showTitles: true, interval: 6, getTitlesWidget: (v, _) => Text('${v.toInt()}:00', style: const TextStyle(fontSize: 9))),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: yAxisWidth, getTitlesWidget: _GlucoseTrendsSection._emptyTitle)),
                  ),
                  borderData: FlBorderData(show: true, border: Border.all(color: AppTheme.getBorderColor(context).withOpacity(0.5))),
                  rangeAnnotations: RangeAnnotations(
                    horizontalRangeAnnotations: [HorizontalRangeAnnotation(y1: threshold.minValue, y2: threshold.maxValue, color: AppTheme.primaryGreen.withOpacity(0.1))],
                  ),
                  lineBarsData: chartLines,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Legend
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _buildLegendItem('Safe Zone', AppTheme.primaryGreen.withOpacity(0.5), isBox: true),
              const SizedBox(width: 12),
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
          const SizedBox(height: 16),
          ...currentItems.map((item) {
            final status = HealthStatusEvaluator.evaluate(item.value, item.dataType, widget.thresholds);
            final statusColor = AppTheme.getStatusColor(status.name);
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
              ),
              child: Row(
                children: [
                   // No vertical bar
                   Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(DateFormat('MMM d, yyyy').format(item.measuredAt), style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(DateFormat('h:mm a').format(item.measuredAt), style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${item.value.toInt()} mg/dL', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                        child: Text(status.name.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold)),
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
