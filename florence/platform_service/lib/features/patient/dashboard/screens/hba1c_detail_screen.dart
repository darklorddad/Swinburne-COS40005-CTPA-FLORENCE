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

          final targetMax = userThreshold?.maxValue;

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
                  _GaugeSection(
                    latestReading: readings.isNotEmpty ? readings.last : null,
                    threshold: userThreshold,
                  ),
                  const SizedBox(height: 20),
                  
                  _TrendsSection(
                    readings: readings,
                    targetMax: targetMax,
                  ),
                  const SizedBox(height: 20),

                  _GoalComparisonSection(
                    latestReading: readings.isNotEmpty ? readings.last : null,
                    targetMax: targetMax,
                  ),
                  const SizedBox(height: 20),
                  
                  _HistorySection(
                    readings: readings, 
                    targetMax: targetMax,
                    threshold: userThreshold,
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
}

// ============================================================================
// 1. GAUGE CHART (Speedometer) - REFINED DESIGN
// ============================================================================

class _GaugeSection extends StatelessWidget {
  final MonitorData? latestReading;
  final HealthThreshold? threshold;

  const _GaugeSection({this.latestReading, this.threshold});

  Widget _buildMiniTargetRow(String label, String val, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: color.withOpacity(0.8))),
        Text(val, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final val = latestReading?.value ?? 0.0;
    
    const double minScale = 4.0;
    const double maxScale = 12.0;
    
    final double normalized = ((val.clamp(minScale, maxScale)) - minScale) / (maxScale - minScale);
    // -90 deg (left) to +90 deg (right)
    final double rotationAngle = -math.pi / 2 + (normalized * math.pi);

    Color statusColor;
    String statusText;
    
    // Use threshold if available, otherwise neutral
    if (val == 0) {
      statusText = "No Data";
      statusColor = AppTheme.textSecondaryColor;
    } else if (threshold != null) {
      if (val <= threshold!.maxValue) {
        statusColor = AppTheme.primaryGreen;
        statusText = "Normal";
      } else {
        statusColor = AppTheme.errorColor;
        statusText = "High";
      }
    } else {
      statusColor = AppTheme.primaryBlue;
      statusText = "Recorded";
    }

    // Chart Dimensions
    const double chartRadius = 110.0; 
    const double sectionWidth = 20.0;
    const double centerRadius = chartRadius - sectionWidth; 
    // Needle length: reach almost to the end of the bar
    const double needleLength = centerRadius + sectionWidth - 2;

    String infoText;
    if (threshold != null) {
      infoText = 'HbA1c reflects your average blood sugar over the past 3 months.\n\n'
                 '• Your Target: Below ${threshold!.maxValue.toStringAsFixed(1)}%\n'
                 '• Above Target: ${threshold!.maxValue.toStringAsFixed(1)}% or higher';
    } else {
      infoText = 'HbA1c reflects your average blood sugar over the past 3 months.\n\n'
                 '• Set a target in your profile to see status.';
    }

    return _HbA1cCard(
      title: 'Current Status',
      icon: Icons.speed,
      infoText: infoText,
      child: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            // Target Range Display
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
                    _buildMiniTargetRow(
                      'HbA1c',
                      threshold != null 
                          ? '${threshold!.minValue.toStringAsFixed(1)} - ${threshold!.maxValue.toStringAsFixed(1)}%' 
                          : 'Not Set',
                      threshold != null ? AppTheme.primaryGreen : AppTheme.textSecondaryColor,
                    ),
                  ],
                ),
              ),
            ),

            // 1. The Gauge (Half Circle)
            SizedBox(
              height: chartRadius + 10,
              width: chartRadius * 2,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  // Background Arc
                  Positioned(
                    top: 0,
                    width: chartRadius * 2,
                    height: chartRadius * 2,
                    child: PieChart(
                      PieChartData(
                        startDegreeOffset: 180,
                        sectionsSpace: 0,
                        centerSpaceRadius: centerRadius,
                        sections: threshold != null 
                        ? [
                          // Clinical Ranges (Only show if threshold exists, implying user cares about status)
                          // Note: Mapping exact user thresholds to a fixed gauge is complex, 
                          // so we stick to clinical backgrounds BUT only if a threshold is set.
                          PieChartSectionData(value: 1.7, color: AppTheme.primaryGreen.withOpacity(0.8), radius: sectionWidth, showTitle: false),
                          PieChartSectionData(value: 0.8, color: AppTheme.warningColor.withOpacity(0.8), radius: sectionWidth, showTitle: false),
                          PieChartSectionData(value: 5.5, color: AppTheme.errorColor.withOpacity(0.8), radius: sectionWidth, showTitle: false),
                          PieChartSectionData(value: 8.0, color: Colors.transparent, radius: sectionWidth, showTitle: false),
                        ]
                        : [
                          // Neutral Blue Arc (4.0 to 12.0 range = 8 units)
                          PieChartSectionData(value: 8.0, color: AppTheme.primaryBlue.withOpacity(0.2), radius: sectionWidth, showTitle: false),
                          PieChartSectionData(value: 8.0, color: Colors.transparent, radius: sectionWidth, showTitle: false),
                        ],
                      ),
                    ),
                  ),
                  
                  // Needle
                  if (val > 0) ...[
                    Positioned(
                      top: chartRadius - needleLength,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Transform.rotate(
                          angle: rotationAngle,
                          alignment: Alignment.bottomCenter,
                          child: SizedBox(
                            height: needleLength,
                            width: 6,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppTheme.textPrimaryColor,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Pivot Point (Knob) - Centered
                    Positioned(
                      top: chartRadius - 8, // Center pivot at y=chartRadius (8 is half height)
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: AppTheme.textPrimaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // 2. Scale Labels
            const SizedBox(
              width: 230,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('4.0%', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  Text('12.0%', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            
            const SizedBox(height: 16),

            // 3. Value & Status
            Column(
              children: [
                Text(
                  val > 0 ? '${val.toStringAsFixed(1)}%' : '--',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                    height: 1.0,
                  ),
                ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withOpacity(0.2)),
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
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 2. TRENDS - FIXED OVERLAPPING / OUT OF BOUNDS
// ============================================================================

class _TrendsSection extends StatefulWidget {
  final List<MonitorData> readings;
  final double? targetMax;

  const _TrendsSection({required this.readings, this.targetMax});

  @override
  State<_TrendsSection> createState() => _TrendsSectionState();
}

class _TrendsSectionState extends State<_TrendsSection> {
  String _selectedRange = '6M';
  final List<String> _ranges = ['6M', '1Y', 'ALL'];

  String _getRangeLabel(String range) {
    switch (range) {
      case '6M':
        return 'Half Year';
      case '1Y':
        return 'Yearly';
      case 'ALL':
        return 'All Time';
      default:
        return range;
    }
  }

  List<MonitorData> _filterData() {
    if (widget.readings.isEmpty || _selectedRange == 'ALL') return widget.readings;
    final now = DateTime.now();
    final duration = _selectedRange == '6M' ? const Duration(days: 180) : const Duration(days: 365);
    final cutoff = now.subtract(duration);
    return widget.readings.where((r) => r.measuredAt.isAfter(cutoff)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filterData();
    
    double minX = 0, maxX = 1;
    if (filtered.isNotEmpty) {
      minX = filtered.first.measuredAt.millisecondsSinceEpoch.toDouble();
      maxX = filtered.last.measuredAt.millisecondsSinceEpoch.toDouble();
      if (minX == maxX) {
        minX -= 2629743000;
        maxX += 2629743000; 
      }
    } else {
       final now = DateTime.now();
       minX = now.subtract(const Duration(days: 90)).millisecondsSinceEpoch.toDouble();
       maxX = now.millisecondsSinceEpoch.toDouble();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _HbA1cCard(
      title: 'HbA1c Trends',
      icon: Icons.show_chart,
      infoText: 'Visualizes your HbA1c levels over time.\n\n'
                '• Green Band: Normal Range\n'
                '• Dotted Line: Your personal target',
      child: Column(
        children: [
          // Timeline Selector
          Container(
            height: 36,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: _ranges.map((range) {
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
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected 
                            ? Colors.white 
                            : Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          SizedBox(
            height: 220,
            // FIX: ClipRect prevents the RangeAnnotations from drawing outside the container
            child: ClipRect(
              child: LineChart(
                LineChartData(
                  // FIX: Ensure FLChart knows to clip content to the border
                  clipData: const FlClipData.all(), 
                  minX: minX, maxX: maxX, minY: 4, maxY: 10,
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
                          // Padding to prevent first/last label clipping
                          if (val <= minX + ((maxX - minX)*0.05) || val >= maxX - ((maxX - minX)*0.05)) return const SizedBox();
                          final date = DateTime.fromMillisecondsSinceEpoch(val.toInt());
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(DateFormat('MMM y').format(date), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(
                    show: true, 
                    border: Border.all(color: AppTheme.getBorderColor(context).withOpacity(0.5))
                  ),
                  rangeAnnotations: widget.targetMax != null ? RangeAnnotations(
                    horizontalRangeAnnotations: [
                      HorizontalRangeAnnotation(y1: 4, y2: 5.7, color: AppTheme.primaryGreen.withOpacity(0.08)),
                      HorizontalRangeAnnotation(y1: 5.7, y2: 6.5, color: AppTheme.warningColor.withOpacity(0.08)),
                      HorizontalRangeAnnotation(y1: 6.5, y2: 14, color: AppTheme.errorColor.withOpacity(0.08)),
                    ],
                  ) : null,
                  extraLinesData: widget.targetMax != null ? ExtraLinesData(
                    horizontalLines: [
                       HorizontalLine(
                         y: widget.targetMax!, 
                         color: AppTheme.primaryBlue.withOpacity(0.8), 
                         strokeWidth: 1, 
                         dashArray: [5,5], 
                         label: HorizontalLineLabel(
                           show: true, 
                           alignment: Alignment.topRight, 
                           padding: const EdgeInsets.only(right: 5, bottom: 2), 
                           style: TextStyle(color: AppTheme.primaryBlue, fontSize: 10, fontWeight: FontWeight.bold), 
                           labelResolver: (line) => 'Target'
                         )
                       )
                    ]
                  ) : null,
                  lineBarsData: [
                    LineChartBarData(
                      spots: filtered.map((r) => FlSpot(r.measuredAt.millisecondsSinceEpoch.toDouble(), r.value)).toList(),
                      isCurved: true,
                      color: AppTheme.primaryBlue,
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true, 
                        getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(radius: 4, color: AppTheme.primaryBlue, strokeColor: Colors.white, strokeWidth: 2)
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
                      tooltipBgColor: Colors.black.withOpacity(0.8),
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          return LineTooltipItem(
                            '${spot.y.toStringAsFixed(1)}%',
                            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (widget.targetMax != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendItem('Normal', AppTheme.primaryGreen.withOpacity(0.5)),
                const SizedBox(width: 16),
                _LegendItem('Pre-diabetes', AppTheme.warningColor.withOpacity(0.5)),
                const SizedBox(width: 16),
                _LegendItem('Diabetes', AppTheme.errorColor.withOpacity(0.5)),
              ],
            )
          ]
        ],
      ),
    );
  }
}

// ============================================================================
// 3. ACTUAL VS GOAL - FIXED TEXT CLIPPING
// ============================================================================

class _GoalComparisonSection extends StatelessWidget {
  final MonitorData? latestReading;
  final double? targetMax;

  const _GoalComparisonSection({this.latestReading, this.targetMax});

  @override
  Widget build(BuildContext context) {
    if (targetMax == null) {
      return _HbA1cCard(
        title: 'Actual vs. Goal',
        icon: Icons.flag_outlined,
        infoText: 'Set a target to see comparison.',
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: Text('No target set. Please configure your profile.')),
        ),
      );
    }

    final current = latestReading?.value ?? 0.0;
    final isGood = current <= targetMax! && current > 0;
    final barColor = isGood ? AppTheme.primaryGreen : AppTheme.errorColor;
    final maxY = math.max(current, targetMax!) * 1.4;

    return _HbA1cCard(
      title: 'Actual vs. Goal',
      icon: Icons.flag_outlined,
      infoText: 'Compares your latest reading against your set target.\n\n'
                'Left Bar: Your latest HbA1c\n'
                'Right Bar: Your Goal',
      child: Column(
        children: [
          if (latestReading == null)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('No HbA1c data recorded yet.'),
            )
          else
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  maxY: maxY,
                  minY: 0,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 2,
                    getDrawingHorizontalLine: (_) => FlLine(color: AppTheme.getBorderColor(context).withOpacity(0.2), strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40, // Increased reserved size to prevent clipping
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
                  borderData: FlBorderData(show: true, border: Border.all(color: AppTheme.getBorderColor(context).withOpacity(0.5))),
                  barGroups: [
                    // Actual Bar
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY: current,
                          color: barColor,
                          width: 30,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        ),
                      ],
                      showingTooltipIndicators: [0],
                    ),
                    // Goal Bar
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          toY: targetMax!,
                          color: AppTheme.primaryBlue.withOpacity(0.3),
                          width: 30,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        ),
                      ],
                      showingTooltipIndicators: [0],
                    ),
                  ],
                  barTouchData: BarTouchData(
                    enabled: false, // Disable touch interaction, just show tooltip
                    touchTooltipData: BarTouchTooltipData(
                      tooltipBgColor: Colors.transparent,
                      tooltipPadding: EdgeInsets.zero,
                      tooltipMargin: 4,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${rod.toY.toStringAsFixed(1)}%',
                          TextStyle(
                            color: group.x == 0 ? barColor : AppTheme.textSecondaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          if (latestReading != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isGood ? AppTheme.primaryGreen : AppTheme.errorColor).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: (isGood ? AppTheme.primaryGreen : AppTheme.errorColor).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    isGood ? Icons.check_circle : Icons.warning,
                    color: isGood ? AppTheme.primaryGreen : AppTheme.errorColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isGood 
                        ? "You are within your target of <${targetMax!.toStringAsFixed(1)}%"
                        : "You are ${(current - targetMax!).toStringAsFixed(1)}% above your target",
                      style: TextStyle(
                        color: isGood ? AppTheme.primaryGreen : AppTheme.errorColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// 4. HISTORY LIST - WITH PAGINATION
// ============================================================================

class _HistorySection extends StatefulWidget {
  final List<MonitorData> readings;
  final double? targetMax;
  final HealthThreshold? threshold;

  const _HistorySection({required this.readings, this.targetMax, this.threshold});

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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'No records found',
                style: TextStyle(color: AppTheme.textSecondaryColor),
              ),
            ),
          
          ...currentItems.map((r) {
             // Determine status color
             String statusText;
             Color statusColor;
             
             if (widget.threshold != null) {
               if (r.value <= widget.threshold!.maxValue) {
                 statusText = 'NORMAL';
                 statusColor = AppTheme.primaryGreen;
               } else {
                 statusText = 'HIGH';
                 statusColor = AppTheme.errorColor;
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
                     offset: const Offset(0, 2),
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
                         r.value.toStringAsFixed(1),
                         style: TextStyle(
                           fontWeight: FontWeight.normal,
                           fontSize: 20,
                           color: AppTheme.textPrimaryColor,
                         ),
                       ),
                       const SizedBox(width: 4),
                       Text(
                         '%',
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
                           statusText,
                           style: TextStyle(
                             color: statusColor,
                             fontSize: 10,
                             fontWeight: FontWeight.bold,
                           ),
                         ),
                       ),
                       const SizedBox(height: 6),
                       Text(
                         DateFormat('dd/MM/yy HH:mm').format(r.measuredAt),
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

// ============================================================================
// HELPERS
// ============================================================================

class _HbA1cCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String infoText;
  final Widget child;

  const _HbA1cCard({
    required this.title,
    required this.icon,
    required this.infoText,
    required this.child,
  });

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(icon, color: AppTheme.primaryBlue),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title, 
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(infoText, style: Theme.of(context).textTheme.bodyMedium),
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
          // Header Row matching GlucoseDetailScreen
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.primaryBlue, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.info_outline, color: AppTheme.textSecondaryColor, size: 20),
                onPressed: () => _showInfoDialog(context),
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
  const _LegendItem(this.label, this.color);
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12, 
          height: 12, 
          decoration: BoxDecoration(
            color: color, 
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11)),
      ],
    );
  }
}
