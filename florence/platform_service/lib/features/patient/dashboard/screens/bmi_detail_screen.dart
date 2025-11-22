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
    String advice;

    if (bmi == 0) {
      category = "No Data";
      color = AppTheme.textSecondaryColor;
      advice = "Log your weight to calculate BMI.";
    } else if (bmi < 18.5) {
      category = "Underweight";
      color = AppTheme.primaryBlue;
      advice = "Focus on nutrient-rich foods to reach a healthy weight.";
    } else if (bmi < 25) {
      category = "Normal";
      color = AppTheme.primaryGreen;
      advice = "Great job! Maintain your current lifestyle.";
    } else if (bmi < 30) {
      category = "Overweight";
      color = AppTheme.warningColor;
      advice = "Aim for gradual weight loss through diet and activity.";
    } else {
      category = "Obese";
      color = AppTheme.errorColor;
      advice = "Consult your doctor for a personalized plan.";
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
          // 1. Target Range Display (Consistent with other screens)
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
                      Text('Normal BMI', style: TextStyle(fontSize: 12, color: AppTheme.primaryGreen.withOpacity(0.8))),
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
            // 2. Big Value Text
            Text(
              bmi.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            
            // 3. Status Badge
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
            
            const SizedBox(height: 24),
            
            // 4. Linear Gauge
            SizedBox(
              height: 40,
              child: LayoutBuilder(builder: (context, constraints) {
                final width = constraints.maxWidth;
                // Scale: 15 to 35 (Range of 20 units)
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
                          // Underweight (15 - 18.5) -> 3.5 units
                          Container(width: (3.5 / totalRange) * width, color: AppTheme.primaryBlue.withOpacity(0.3)),
                          // Normal (18.5 - 25) -> 6.5 units
                          Container(width: (6.5 / totalRange) * width, color: AppTheme.primaryGreen.withOpacity(0.3)),
                          // Overweight (25 - 30) -> 5 units
                          Container(width: (5.0 / totalRange) * width, color: AppTheme.warningColor.withOpacity(0.3)),
                          // Obese (30 - 35) -> 5 units
                          Expanded(child: Container(color: AppTheme.errorColor.withOpacity(0.3))),
                        ],
                      ),
                    ),
                    // Marker
                    Positioned(
                      left: getPos(bmi) - 12, // Center the 24px icon
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
            const SizedBox(height: 16),
            
            // 5. Advice Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, size: 20, color: AppTheme.textSecondaryColor),
                  const SizedBox(width: 12),
                  Expanded(child: Text(advice, style: const TextStyle(fontSize: 12))),
                ],
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
    // Filter last 6 months for relevance
    final cutoff = DateTime.now().subtract(const Duration(days: 180));
    final recentReadings = readings.where((r) => r.measuredAt.isAfter(cutoff)).toList();

    if (recentReadings.isEmpty) {
      return _BmiCard(
        title: 'BMI Trend',
        icon: Icons.show_chart,
        infoText: 'Your BMI progress over time.',
        child: const Padding(padding: EdgeInsets.all(20), child: Center(child: Text("No recent data."))),
      );
    }

    double minX = recentReadings.first.measuredAt.millisecondsSinceEpoch.toDouble();
    double maxX = recentReadings.last.measuredAt.millisecondsSinceEpoch.toDouble();
    if (minX == maxX) {
      minX -= 2629743000; // -1 Month
      maxX += 2629743000; // +1 Month
    }

    double minY = 15;
    double maxY = 35;
    
    // Adjust Y based on actual data
    final vals = recentReadings.map((e) => e.value);
    if (vals.isNotEmpty) {
      minY = math.min(minY, vals.reduce(math.min) - 2);
      maxY = math.max(maxY, vals.reduce(math.max) + 2);
    }

    return _BmiCard(
      title: 'Progress',
      icon: Icons.show_chart,
      infoText: 'Your BMI trend over the last 6 months.\n\n'
          '• Consistent monitoring helps track long-term weight management effectiveness.',
      child: SizedBox(
        height: 250,
        child: LineChart(
          LineChartData(
            minX: minX, maxX: maxX, minY: minY, maxY: maxY,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => FlLine(color: AppTheme.borderColor.withOpacity(0.5), strokeWidth: 1),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (val, _) => Text(val.toInt().toString(), style: const TextStyle(fontSize: 10))),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: (maxX - minX) / 4,
                  getTitlesWidget: (val, _) {
                    if (val == minX || val == maxX) return const SizedBox();
                    final date = DateTime.fromMillisecondsSinceEpoch(val.toInt());
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(DateFormat('MMM').format(date), style: const TextStyle(fontSize: 10)),
                    );
                  },
                ),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: true, border: Border.all(color: AppTheme.borderColor)),
            // Background Zones
            rangeAnnotations: RangeAnnotations(
              horizontalRangeAnnotations: [
                HorizontalRangeAnnotation(y1: 18.5, y2: 25, color: AppTheme.primaryGreen.withOpacity(0.05)),
              ],
            ),
            lineBarsData: [
              LineChartBarData(
                spots: recentReadings.map((r) => FlSpot(r.measuredAt.millisecondsSinceEpoch.toDouble(), r.value)).toList(),
                isCurved: true, 
                color: AppTheme.primaryBlue,
                barWidth: 3,
                dotData: FlDotData(show: true),
                belowBarData: BarAreaData(show: true, color: AppTheme.primaryBlue.withOpacity(0.1)),
              ),
            ],
          ),
        ),
      ),
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
    if (bmiReadings.isEmpty || hba1cReadings.isEmpty) {
      return _BmiCard(
        title: 'Health Correlation',
        icon: Icons.insights,
        infoText: 'Compare your BMI against other metrics like HbA1c.',
        child: const Padding(padding: EdgeInsets.all(20), child: Center(child: Text("Insufficient data for correlation."))),
      );
    }

    // Normalize time range
    final minTime = math.min(
      bmiReadings.first.measuredAt.millisecondsSinceEpoch,
      hba1cReadings.first.measuredAt.millisecondsSinceEpoch,
    ).toDouble();
    
    final maxTime = math.max(
      bmiReadings.last.measuredAt.millisecondsSinceEpoch,
      hba1cReadings.last.measuredAt.millisecondsSinceEpoch,
    ).toDouble();

    final span = maxTime - minTime;
    final adjMin = minTime - (span * 0.05);
    final adjMax = maxTime + (span * 0.05);

    return _BmiCard(
      title: 'BMI vs. HbA1c',
      icon: Icons.insights,
      infoText: 'Clinical Insight: Is weight management improving your blood sugar?\n\n'
          '• Blue Line (Left Axis): BMI\n'
          '• Purple Dots (Right Axis): HbA1c\n'
          '• Goal: See if both trend downwards together.',
      child: SizedBox(
        height: 250,
        child: LineChart(
          LineChartData(
            minX: adjMin, maxX: adjMax,
            minY: 15, maxY: 40, // BMI Scale
            
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                axisNameWidget: const Text("BMI", style: TextStyle(fontSize: 10)),
                sideTitles: SideTitles(showTitles: true, reservedSize: 30, interval: 5, getTitlesWidget: (v, _) => Text(v.toInt().toString(), style: const TextStyle(fontSize: 10))),
              ),
              rightTitles: AxisTitles(
                axisNameWidget: const Text("HbA1c %", style: TextStyle(fontSize: 10)),
                sideTitles: SideTitles(
                  showTitles: true, 
                  reservedSize: 30, 
                  interval: 5, 
                  getTitlesWidget: (v, _) {
                    // Reverse map visual 5 units to HbA1c
                    final hba1cVal = ((v - 15)/25)*8 + 4;
                    if (hba1cVal < 4 || hba1cVal > 12) return const SizedBox();
                    return Text(hba1cVal.toStringAsFixed(1), style: const TextStyle(fontSize: 10, color: Colors.purple));
                  }
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: true, getTitlesWidget: (val, _) {
                   if (val == adjMin || val == adjMax) return const SizedBox();
                   final date = DateTime.fromMillisecondsSinceEpoch(val.toInt());
                   return Text(DateFormat('MM/yy').format(date), style: const TextStyle(fontSize: 9));
                }),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(show: true, drawVerticalLine: false),
            borderData: FlBorderData(show: true, border: Border.all(color: AppTheme.borderColor)),
            lineBarsData: [
              // BMI Line (Blue)
              LineChartBarData(
                spots: bmiReadings.map((r) => FlSpot(r.measuredAt.millisecondsSinceEpoch.toDouble(), r.value)).toList(),
                color: AppTheme.primaryBlue,
                barWidth: 3,
                isCurved: true,
                dotData: FlDotData(show: false),
              ),
              // HbA1c Line (Purple - Scaled)
              LineChartBarData(
                spots: hba1cReadings.map((r) {
                  // Scale HbA1c (approx 4-12) to fit BMI chart (15-40)
                  // We map 4 -> 15 and 12 -> 40. Range 8 -> Range 25.
                  final scaledY = ((r.value - 4) / 8) * 25 + 15;
                  return FlSpot(r.measuredAt.millisecondsSinceEpoch.toDouble(), scaledY);
                }).toList(),
                color: Colors.purple,
                barWidth: 0, // Hide line, show dots
                isCurved: false,
                dotData: FlDotData(
                  show: true, 
                  getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(radius: 4, color: Colors.purple)
                ),
              ),
            ],
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => Colors.black.withOpacity(0.8),
                getTooltipItems: (spots) {
                  return spots.map((spot) {
                    if (spot.barIndex == 0) {
                      return LineTooltipItem("BMI: ${spot.y.toStringAsFixed(1)}", const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12));
                    } else {
                      // Reverse math to show real HbA1c
                      final realVal = ((spot.y - 15)/25)*8 + 4;
                      return LineTooltipItem("HbA1c: ${realVal.toStringAsFixed(1)}%", const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12));
                    }
                  }).toList();
                }
              )
            )
          ),
        ),
      ),
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
                    Text(
                      r.value.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.normal,
                        color: AppTheme.textPrimaryColor,
                      ),
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
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}
