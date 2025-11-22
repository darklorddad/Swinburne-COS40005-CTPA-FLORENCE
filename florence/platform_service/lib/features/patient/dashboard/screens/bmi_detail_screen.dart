import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../../../../config/theme.dart';
import '../../core/models/health_data_models.dart';
import '../../dashboard/providers/dashboard_providers.dart';

class BmiDetailScreen extends ConsumerWidget {
  const BmiDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monitorAsync = ref.watch(monitorDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('BMI Analytics'),
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
              await ref.refresh(monitorDataProvider.future);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // 1. Linear Gauge (Current Status)
                  _BmiGaugeSection(latestReading: latestBmi),
                  const SizedBox(height: 20),

                  // 2. Progress Chart (BMI Trend)
                  _BmiTrendSection(readings: bmiReadings),
                  const SizedBox(height: 20),

                  // 3. Clinical Insight (Correlation)
                  _BmiCorrelationSection(
                    bmiReadings: bmiReadings,
                    hba1cReadings: hba1cReadings,
                  ),
                  const SizedBox(height: 20),

                  // 4. History List
                  _BmiHistorySection(readings: bmiReadings),
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
  }

  List<MonitorData> _filterData() {
    if (widget.allData.isEmpty) return [];
    if (_selectedRange == 'ALL') return widget.allData;

    final now = DateTime.now();
    Duration duration;
    switch (_selectedRange) {
      case '1M': duration = const Duration(days: 30); break;
      case '3M': duration = const Duration(days: 90); break;
      case '6M': duration = const Duration(days: 180); break;
      case '1Y': duration = const Duration(days: 365); break;
      default: duration = const Duration(days: 365); break;
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

  const _BmiGaugeSection({this.latestReading});

  @override
  Widget build(BuildContext context) {
    final bmi = latestReading?.value ?? 0.0;
    String category;
    Color color;

    if (bmi == 0) {
      category = "No Data";
      color = AppTheme.textSecondaryColor;
    } else if (bmi < 18.5) {
      category = "Underweight";
      color = AppTheme.primaryBlue;
    } else if (bmi < 25) {
      category = "Normal";
      color = AppTheme.primaryGreen;
    } else if (bmi < 30) {
      category = "Overweight";
      color = AppTheme.warningColor;
    } else {
      category = "Obese";
      color = AppTheme.errorColor;
    }

    return _BmiCard(
      title: 'Current Status',
      icon: Icons.speed,
      infoText: 'Body Mass Index (BMI) Categories:\n\n'
          '• Underweight: < 18.5\n'
          '• Normal: 18.5 – 24.9\n'
          '• Overweight: 25 – 29.9\n'
          '• Obese: 30+',
      child: Column(
        children: [
          // 1. Target Range Display (Top)
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
                          Icon(Icons.track_changes, size: 18, color: AppTheme.primaryGreen),
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
                      Text('18.5 - 24.9', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (latestReading == null)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text("No BMI data recorded."),
            )
          else ...[
            // 2. Value (Moved Above Chart)
            Text(
              bmi.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
                height: 1.0,
              ),
            ),
            
            const SizedBox(height: 24),

            // 3. Linear Gauge (Middle)
            SizedBox(
              height: 40,
              child: LayoutBuilder(builder: (context, constraints) {
                final width = constraints.maxWidth;
                const minScale = 15.0;
                const maxScale = 35.0;
                final totalRange = maxScale - minScale;

                double getPos(double val) {
                  return ((val.clamp(minScale, maxScale) - minScale) / totalRange) * width;
                }

                return Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.centerLeft,
                  children: [
                    // Track
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Row(
                        children: [
                          Container(width: (3.5 / totalRange) * width, color: AppTheme.primaryBlue.withOpacity(0.3)), // Underweight
                          Container(width: (6.5 / totalRange) * width, color: AppTheme.primaryGreen.withOpacity(0.3)), // Normal
                          Container(width: (5.0 / totalRange) * width, color: AppTheme.warningColor.withOpacity(0.3)), // Overweight
                          Expanded(child: Container(color: AppTheme.errorColor.withOpacity(0.3))), // Obese
                        ],
                      ),
                    ),
                    // Marker
                    Positioned(
                      left: getPos(bmi) - 12,
                      top: -12,
                      child: Column(
                        children: [
                          Icon(Icons.arrow_drop_down, size: 24, color: AppTheme.textPrimaryColor),
                        ],
                      ),
                    ),
                  ],
                );
              }),
            ),
            const SizedBox(height: 8),
            // Scale Labels
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("15.0", style: Theme.of(context).textTheme.bodySmall),
                Text("18.5", style: Theme.of(context).textTheme.bodySmall),
                Text("25.0", style: Theme.of(context).textTheme.bodySmall),
                Text("30.0", style: Theme.of(context).textTheme.bodySmall),
                Text("35+", style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            
            const SizedBox(height: 24),

            // 4. Status Badge (Below Chart)
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

  const _BmiTrendSection({required this.readings});

  @override
  Widget build(BuildContext context) {
    return _ChartSection(
      title: 'Progress',
      icon: Icons.show_chart,
      ranges: const ['3M', '6M', '1Y', 'ALL'],
      infoText: 'Visualizes your BMI trends over time.\n\n'
          '• Y-Axis: BMI (kg/m²)\n'
          '• X-Axis: Time\n'
          '• Green Band: Normal BMI Range (18.5 - 25).',
      allData: readings,
      builder: (range, data) {
        if (data.isEmpty) {
          return const Padding(padding: EdgeInsets.all(20), child: Center(child: Text("No data available for this period.")));
        }

        double minX = data.first.measuredAt.millisecondsSinceEpoch.toDouble();
        double maxX = data.last.measuredAt.millisecondsSinceEpoch.toDouble();
        if (minX == maxX) {
          minX -= 2629743000; 
          maxX += 2629743000;
        }

        // Dynamic Y Axis
        final vals = data.map((e) => e.value);
        double minY = vals.reduce(math.min) - 2;
        double maxY = vals.reduce(math.max) + 2;
        
        // Ensure reasonable bounds
        minY = math.max(15, minY);
        maxY = math.max(30, maxY);

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
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(color: AppTheme.getBorderColor(context).withOpacity(0.2), strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false, reservedSize: 0)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false, reservedSize: 0)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: (maxX - minX) / 4,
                        getTitlesWidget: (val, _) {
                          if (val <= minX || val >= maxX) return const SizedBox();
                          final date = DateTime.fromMillisecondsSinceEpoch(val.toInt());
                          
                          final durationDays = Duration(milliseconds: (maxX - minX).toInt()).inDays;
                          final fmt = durationDays > 90 ? DateFormat('MMM y') : DateFormat('d/M');

                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(fmt.format(date), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: true, border: Border.all(color: AppTheme.getBorderColor(context).withOpacity(0.5))),
                  rangeAnnotations: RangeAnnotations(
                    horizontalRangeAnnotations: [
                      HorizontalRangeAnnotation(y1: 18.5, y2: 25, color: AppTheme.primaryGreen.withOpacity(0.05)),
                    ],
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: data.map((r) => FlSpot(r.measuredAt.millisecondsSinceEpoch.toDouble(), r.value)).toList(),
                      isCurved: true,
                      color: AppTheme.primaryBlue,
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(radius: 3, color: AppTheme.primaryBlue, strokeColor: Colors.white, strokeWidth: 1.5),
                      ),
                      belowBarData: BarAreaData(show: true, color: AppTheme.primaryBlue.withOpacity(0.1)),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => Colors.black.withOpacity(0.8),
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          return LineTooltipItem(
                            '${spot.y.toStringAsFixed(1)}',
                            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendItem('BMI Trend', AppTheme.primaryBlue, isCircle: true),
                const SizedBox(width: 16),
                _LegendItem('Normal Range', AppTheme.primaryGreen.withOpacity(0.5), isBox: true),
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
          '• Purple Dots: HbA1c %\n'
          '• Goal: Observe if weight changes correlate with better blood sugar control.',
      allData: bmiReadings, // Pass BMI to drive range logic
      ranges: const ['6M', '1Y', 'ALL'],
      builder: (range, data) {
        // 'data' here is filtered BMI readings
        if (data.isEmpty) {
          return const Padding(padding: EdgeInsets.all(20), child: Center(child: Text("No BMI data for correlation.")));
        }

        // Filter HbA1c based on the same time range
        final minTime = data.first.measuredAt;
        final maxTime = data.last.measuredAt;
        
        // Widen window slightly to catch HbA1c near the edges
        final displayHba1c = hba1cReadings.where((r) => 
          r.measuredAt.isAfter(minTime.subtract(const Duration(days: 30))) && 
          r.measuredAt.isBefore(maxTime.add(const Duration(days: 30)))
        ).toList();

        double minX = minTime.millisecondsSinceEpoch.toDouble();
        double maxX = maxTime.millisecondsSinceEpoch.toDouble();
        if (minX == maxX) {
          minX -= 2629743000; 
          maxX += 2629743000;
        }

        // Normalize Y-Axis: Map HbA1c (4-12) to fit visually within BMI range (15-40)
        // y_chart = ((hba1c - 4) / 8) * 25 + 15
        
        return Column(
          children: [
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  clipData: const FlClipData.all(),
                  minX: minX, maxX: maxX,
                  minY: 15, maxY: 40, // BMI Scale
                  
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false, reservedSize: 0)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false, reservedSize: 0)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, getTitlesWidget: (val, _) {
                         if (val <= minX || val >= maxX) return const SizedBox();
                         final date = DateTime.fromMillisecondsSinceEpoch(val.toInt());
                         return Padding(
                           padding: const EdgeInsets.only(top: 8.0),
                           child: Text(DateFormat('MM/yy').format(date), style: const TextStyle(fontSize: 9, color: Colors.grey)),
                         );
                      }),
                    ),
                  ),
                  gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: AppTheme.getBorderColor(context).withOpacity(0.2), strokeWidth: 1)),
                  borderData: FlBorderData(show: true, border: Border.all(color: AppTheme.getBorderColor(context).withOpacity(0.5))),
                  lineBarsData: [
                    // BMI Line (Blue)
                    LineChartBarData(
                      spots: data.map((r) => FlSpot(r.measuredAt.millisecondsSinceEpoch.toDouble(), r.value)).toList(),
                      color: AppTheme.primaryBlue,
                      barWidth: 3,
                      isCurved: true,
                      dotData: FlDotData(show: false),
                    ),
                    // HbA1c Line (Purple - Scaled)
                    LineChartBarData(
                      spots: displayHba1c.map((r) {
                        final scaledY = ((r.value - 4) / 8) * 25 + 15;
                        return FlSpot(r.measuredAt.millisecondsSinceEpoch.toDouble(), scaledY);
                      }).toList(),
                      color: Colors.purple,
                      barWidth: 0, 
                      isCurved: false,
                      dotData: FlDotData(
                        show: true, 
                        getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(radius: 4, color: Colors.purple, strokeWidth: 1, strokeColor: Colors.white)
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => Colors.black.withOpacity(0.8),
                      getTooltipItems: (spots) {
                        return spots.map((spot) {
                          if (spot.barIndex == 0) {
                            return LineTooltipItem("BMI: ${spot.y.toStringAsFixed(1)}", const TextStyle(color: Colors.white));
                          } else {
                            final realVal = ((spot.y - 15)/25)*8 + 4;
                            return LineTooltipItem("HbA1c: ${realVal.toStringAsFixed(1)}%", const TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold));
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
                _LegendItem('BMI Trend', AppTheme.primaryBlue, isCircle: true),
                const SizedBox(width: 16),
                _LegendItem('HbA1c %', Colors.purple, isCircle: true),
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

class _BmiHistorySection extends StatefulWidget {
  final List<MonitorData> readings;

  const _BmiHistorySection({required this.readings});

  @override
  State<_BmiHistorySection> createState() => _BmiHistorySectionState();
}

class _BmiHistorySectionState extends State<_BmiHistorySection> {
  int _currentPage = 0;
  static const int _itemsPerPage = 5;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerColor = isDark ? AppTheme.midnightSurface : Colors.white;
    final borderColor = AppTheme.getBorderColor(context);

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
              if (totalPages > 0)
                Row(
                  children: [
                    IconButton(
                      onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
                      icon: const Icon(Icons.chevron_left),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '${_currentPage + 1}/$totalPages',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      onPressed: _currentPage < totalPages - 1 ? () => setState(() => _currentPage++) : null,
                      icon: const Icon(Icons.chevron_right),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 20),

          if (currentItems.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: Text("No history available")),
            )
          else
            ...currentItems.map((r) {
              String label;
              Color color;
              if (r.value < 18.5) { label = "Underweight"; color = AppTheme.primaryBlue; }
              else if (r.value < 25) { label = "Normal"; color = AppTheme.primaryGreen; }
              else if (r.value < 30) { label = "Overweight"; color = AppTheme.warningColor; }
              else { label = "Obese"; color = AppTheme.errorColor; }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: containerColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.3)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))],
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
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                          child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
                        ),
                        const SizedBox(height: 4),
                        Text(DateFormat('dd/MM/yy HH:mm').format(r.measuredAt), style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor)),
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

  const _LegendItem(this.label, this.color, {super.key, this.isBox = false, this.isCircle = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isBox)
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)))
        else if (isCircle)
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle))
        else
          Container(width: 12, height: 2, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}
