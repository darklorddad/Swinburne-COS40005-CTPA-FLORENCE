import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../../../../config/theme.dart';
import '../../core/models/health_data_models.dart';
import '../../dashboard/providers/dashboard_providers.dart';

class GlucoseDetailScreen extends ConsumerStatefulWidget {
  final int patientId;

  const GlucoseDetailScreen({super.key, required this.patientId});

  @override
  ConsumerState<GlucoseDetailScreen> createState() => _GlucoseDetailScreenState();
}

class _GlucoseDetailScreenState extends ConsumerState<GlucoseDetailScreen> {
  String _selectedRange = '1D'; // 1D, 7D (1W), 14D (2W), 30D (1M)
  int _currentPage = 0;
  static const int _itemsPerPage = 5;

  @override
  Widget build(BuildContext context) {
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
              // 1. Filter Glucose Data
              final allReadings = dataList
                  .where((d) => d.dataType == MonitorDataType.GLUCOSE)
                  .toList();

              if (allReadings.isEmpty) {
                return const Center(child: Text('No glucose data available'));
              }
              allReadings.sort((a, b) => b.measuredAt.compareTo(a.measuredAt));

              // 2. Get Thresholds
              final thresholds = thresholdsAsync.value ?? [];
              final glucoseThreshold = thresholds.firstWhere(
                (t) => t.dataType == MonitorDataType.GLUCOSE,
                orElse: () => const HealthThreshold(
                    dataType: MonitorDataType.GLUCOSE,
                    minValue: 70,
                    maxValue: 180),
              );

              // 3. Filter Data by Selected Range
              final now = DateTime.now();
              Duration rangeDuration;
              switch (_selectedRange) {
                case '7D': rangeDuration = const Duration(days: 7); break;
                case '14D': rangeDuration = const Duration(days: 14); break;
                case '30D': rangeDuration = const Duration(days: 30); break;
                case '1D':
                default: rangeDuration = const Duration(hours: 24); break;
              }
              final cutoff = now.subtract(rangeDuration);

              final rangeReadings = allReadings
                  .where((d) => d.measuredAt.isAfter(cutoff))
                  .toList();
                  
              // Sort ascending for charts
              rangeReadings.sort((a, b) => a.measuredAt.compareTo(b.measuredAt));

              final rangeMeals = mealLogs
                  .where((m) => m.logDate.isAfter(cutoff))
                  .toList();

              // 4. Calculate Analytics
              final analytics = _calculateAnalytics(rangeReadings, glucoseThreshold);

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Time Range Selector
                    _buildTimeRangeSelector(),
                    const SizedBox(height: 20),

                    // 1. Annotated Line Chart (Main Visual)
                    Text('Glucose Trends', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    _buildAnnotatedChart(rangeReadings, rangeMeals, glucoseThreshold),
                    const SizedBox(height: 24),

                    // 2. Time in Range (Stacked Bar)
                    Text('Time in Range', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    _buildTIRBar(analytics),
                    const SizedBox(height: 24),

                    // 3. Modal Day (Spaghetti Plot)
                    Text('Modal Day (Daily Overlays)', style: Theme.of(context).textTheme.titleLarge),
                    Text('Comparing daily patterns over the selected period', style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 12),
                    _buildSpaghettiChart(rangeReadings, glucoseThreshold),
                    const SizedBox(height: 24),

                    // Statistics Summary
                    _buildSummaryRow(analytics),
                    const SizedBox(height: 20),
                    
                    // History List
                    _buildPaginatedHistory(allReadings, thresholds),
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

  // --- 1. Annotated Line Chart ---

  Widget _buildAnnotatedChart(
    List<MonitorData> readings,
    List<DailyPatientLog> meals,
    HealthThreshold threshold,
  ) {
    if (readings.isEmpty) return const Center(child: Text('No data'));

    // Dynamic Y-Axis
    double minY = (threshold.minValue - 20).clamp(0, double.infinity);
    double maxY = threshold.maxValue + 40;
    if (readings.isNotEmpty) {
      double dataMin = readings.map((e) => e.value).reduce(math.min);
      double dataMax = readings.map((e) => e.value).reduce(math.max);
      minY = math.min(minY, dataMin - 10);
      maxY = math.max(maxY, dataMax + 10);
    }

    // X-Axis Bounds
    double minX = readings.first.measuredAt.millisecondsSinceEpoch.toDouble();
    double maxX = readings.last.measuredAt.millisecondsSinceEpoch.toDouble();
    
    // Add padding to X axis if single point
    if (minX == maxX) {
      minX -= 3600000; // -1 hour
      maxX += 3600000; // +1 hour
    }

    return Column(
      children: [
        Container(
          height: 300,
          padding: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.getBorderColor(context)),
          ),
          child: LineChart(
            LineChartData(
              minX: minX,
              maxX: maxX,
              minY: minY,
              maxY: maxY,
              // Safe Zone (Shaded Band)
              rangeAnnotations: RangeAnnotations(
                horizontalRangeAnnotations: [
                  HorizontalRangeAnnotation(
                    y1: threshold.minValue,
                    y2: threshold.maxValue,
                    color: AppTheme.primaryGreen.withOpacity(0.15),
                  ),
                ],
              ),
              // Event Lines (Meals)
              extraLinesData: ExtraLinesData(
                verticalLines: meals.map((meal) {
                  Color lineColor;
                  switch(meal.mealTime) {
                    case 'BREAKFAST': lineColor = Colors.orange; break;
                    case 'LUNCH': lineColor = Colors.blue; break;
                    case 'DINNER': lineColor = Colors.purple; break;
                    default: lineColor = Colors.grey;
                  }
                  return VerticalLine(
                    x: meal.logDate.millisecondsSinceEpoch.toDouble(),
                    color: lineColor.withOpacity(0.5),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                    label: VerticalLineLabel(
                      show: true,
                      alignment: Alignment.topRight,
                      padding: const EdgeInsets.only(top: 5),
                      style: TextStyle(color: lineColor, fontSize: 9, fontWeight: FontWeight.bold),
                      labelResolver: (_) => meal.mealTime[0], // First letter only
                    ),
                  );
                }).toList(),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: readings.map((r) => FlSpot(
                    r.measuredAt.millisecondsSinceEpoch.toDouble(), 
                    r.value
                  )).toList(),
                  isCurved: true,
                  color: AppTheme.primaryBlue,
                  barWidth: 3,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(show: false),
                ),
              ],
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: AppTheme.getBorderColor(context).withOpacity(0.3),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 35,
                    interval: 40,
                    getTitlesWidget: (value, meta) => Text(
                      value.toInt().toString(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: (maxX - minX) / 4,
                    getTitlesWidget: (value, meta) {
                      final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                      final fmt = _selectedRange == '1D' ? DateFormat('HH:mm') : DateFormat('MM/dd');
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          fmt.format(date),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
        // Legend
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Safe Zone', AppTheme.primaryGreen.withOpacity(0.5), isBox: true),
              const SizedBox(width: 12),
              _buildLegendItem('B: Brkfst', Colors.orange, isDashed: true),
              const SizedBox(width: 8),
              _buildLegendItem('L: Lunch', Colors.blue, isDashed: true),
              const SizedBox(width: 8),
              _buildLegendItem('D: Dinner', Colors.purple, isDashed: true),
            ],
          ),
        ),
      ],
    );
  }

  // --- 2. Time in Range (TIR) Bar ---

  Widget _buildTIRBar(Map<String, dynamic> analytics) {
    final lowPct = (analytics['low_pct'] as double);
    final inRangePct = (analytics['tir'] as double);
    final highPct = (analytics['high_pct'] as double);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.getBorderColor(context)),
      ),
      child: Column(
        children: [
          // The Stacked Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 30,
              child: Row(
                children: [
                  if (lowPct > 0) Expanded(flex: (lowPct * 10).toInt(), child: Container(color: AppTheme.errorColor)),
                  if (inRangePct > 0) Expanded(flex: (inRangePct * 10).toInt(), child: Container(color: AppTheme.primaryGreen)),
                  if (highPct > 0) Expanded(flex: (highPct * 10).toInt(), child: Container(color: AppTheme.warningColor)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Legend / Values
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTIRValue('Low', lowPct, AppTheme.errorColor),
              _buildTIRValue('In Range', inRangePct, AppTheme.primaryGreen, isMain: true),
              _buildTIRValue('High', highPct, AppTheme.warningColor),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 4),
          Text(
            inRangePct >= 70 
              ? 'Target Met (>70%)' 
              : 'Target Not Met (<70%)',
            style: TextStyle(
              color: inRangePct >= 70 ? AppTheme.primaryGreen : AppTheme.textSecondaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTIRValue(String label, double pct, Color color, {bool isMain = false}) {
    return Column(
      children: [
        Text(
          '${pct.toStringAsFixed(0)}%',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: isMain ? 18 : 14,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodySmall?.color,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  // --- 3. Modal Day (Spaghetti Plot) ---

  Widget _buildSpaghettiChart(List<MonitorData> readings, HealthThreshold threshold) {
    if (readings.isEmpty) return const SizedBox.shrink();

    // Group data by day
    final Map<int, List<FlSpot>> dailySpots = {};
    
    for (var r in readings) {
      // Key is day of year (simple approximation)
      final dayKey = r.measuredAt.day; 
      // Normalize time to 0.0 - 24.0
      final timeVal = r.measuredAt.hour + (r.measuredAt.minute / 60.0);
      
      dailySpots.putIfAbsent(dayKey, () => []).add(FlSpot(timeVal, r.value));
    }

    // Create lines for each day
    List<LineChartBarData> lines = [];
    dailySpots.forEach((key, spots) {
      // Sort spots by time
      spots.sort((a, b) => a.x.compareTo(b.x));
      lines.add(LineChartBarData(
        spots: spots,
        isCurved: true,
        color: AppTheme.textSecondaryColor.withOpacity(0.3), // Low opacity for background lines
        barWidth: 1.5,
        dotData: const FlDotData(show: false),
      ));
    });

    return Container(
      height: 250,
      padding: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.getBorderColor(context)),
      ),
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: 24,
          minY: 40,
          maxY: 250, // Fixed range for modal day often helps comparison
          lineBarsData: lines,
          gridData: FlGridData(
            show: true,
            horizontalInterval: 50,
            verticalInterval: 6, // Every 6 hours
            getDrawingHorizontalLine: (value) => FlLine(color: AppTheme.getBorderColor(context).withOpacity(0.3), strokeWidth: 1),
            getDrawingVerticalLine: (value) => FlLine(color: AppTheme.getBorderColor(context).withOpacity(0.3), strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true, 
                reservedSize: 30, 
                interval: 50,
                getTitlesWidget: (val, _) => Text(val.toInt().toString(), style: const TextStyle(fontSize: 10)),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 6,
                getTitlesWidget: (val, _) => Text('${val.toInt()}:00', style: const TextStyle(fontSize: 10)),
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          // Add Safe Zone here too
          rangeAnnotations: RangeAnnotations(
            horizontalRangeAnnotations: [
              HorizontalRangeAnnotation(
                y1: threshold.minValue,
                y2: threshold.maxValue,
                color: AppTheme.primaryGreen.withOpacity(0.1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helpers & Other Widgets ---

  Widget _buildTimeRangeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.getBorderColor(context)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: ['1D', '7D', '14D', '30D'].map((range) {
          final isSelected = _selectedRange == range;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedRange = range),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  range,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Theme.of(context).textTheme.bodySmall?.color,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, {bool isBox = false, bool isDashed = false}) {
    return Row(
      children: [
        if (isBox)
          Container(width: 12, height: 12, color: color)
        else if (isDashed)
          Container(width: 2, height: 12, color: color) // Simulating vertical line
        else
          Container(width: 12, height: 2, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }

  Map<String, dynamic> _calculateAnalytics(List<MonitorData> readings, HealthThreshold threshold) {
    if (readings.isEmpty) return {'avg': 0.0, 'gmi': 0.0, 'cv': 0.0, 'tir': 0.0, 'low_pct': 0.0, 'high_pct': 0.0};

    final values = readings.map((e) => e.value).toList();
    final avg = values.reduce((a, b) => a + b) / values.length;
    
    // CV
    final variance = values.map((v) => math.pow(v - avg, 2)).reduce((a, b) => a + b) / values.length;
    final stdDev = math.sqrt(variance);
    final cv = (stdDev / avg) * 100;
    final gmi = 3.31 + (0.02392 * avg);

    final total = readings.length;
    final lows = readings.where((r) => r.value < threshold.minValue).length;
    final highs = readings.where((r) => r.value > threshold.maxValue).length;
    final inRange = total - lows - highs;

    return {
      'avg': avg,
      'gmi': gmi,
      'cv': cv,
      'tir': (inRange / total) * 100,
      'low_pct': (lows / total) * 100,
      'high_pct': (highs / total) * 100,
    };
  }

  // Keeping the Summary Row and History as they were useful
  Widget _buildSummaryRow(Map<String, dynamic> analytics) {
    return Row(
      children: [
        Expanded(child: _buildStatCard('Average', '${(analytics['avg'] as double).toStringAsFixed(0)}', 'mg/dL', Colors.blue)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('GMI (A1c)', '${(analytics['gmi'] as double).toStringAsFixed(1)}', '%', Colors.purple)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Variability', '${(analytics['cv'] as double).toStringAsFixed(1)}', '%', (analytics['cv'] as double) < 36 ? Colors.green : Colors.orange)),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, String unit, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.getBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color, fontWeight: FontWeight.bold)),
              const SizedBox(width: 2),
              Text(unit, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildPaginatedHistory(List<MonitorData> allReadings, List<HealthThreshold> thresholds) {
    final totalItems = allReadings.length;
    final totalPages = (totalItems / _itemsPerPage).ceil();
    
    // Ensure current page is valid
    if (_currentPage >= totalPages && totalPages > 0) {
      _currentPage = totalPages - 1;
    }

    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = math.min(startIndex + _itemsPerPage, totalItems);
    final currentItems = allReadings.sublist(startIndex, endIndex);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('History', style: Theme.of(context).textTheme.titleLarge),
            Row(
              children: [
                IconButton(
                  onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
                  icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 12),
                Text('${_currentPage + 1} / ${totalPages == 0 ? 1 : totalPages}', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: _currentPage < totalPages - 1 ? () => setState(() => _currentPage++) : null,
                  icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: currentItems.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = currentItems[index];
            final status = HealthStatusEvaluator.evaluate(item.value, item.dataType, thresholds);
            
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.getBorderColor(context)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.water_drop_outlined, color: AppTheme.primaryBlue, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('MMM d, yyyy').format(item.measuredAt),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          DateFormat('h:mm a').format(item.measuredAt),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${item.value.toInt()} mg/dL',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
