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
  String _selectedRange = '1D'; // 1D, 1W, 1M
  int _currentPage = 0;
  static const int _itemsPerPage = 5;

  @override
  Widget build(BuildContext context) {
    final glucoseAsync = ref.watch(monitorDataProvider);
    final thresholdsAsync = ref.watch(patientThresholdsProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Glucose Analytics'),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppTheme.textPrimaryColor),
        titleTextStyle: AppTheme.lightTheme.textTheme.titleLarge,
      ),
      body: glucoseAsync.when(
        data: (dataList) {
          // Filter for Glucose data
          final allReadings = dataList
              .where((d) => d.dataType == MonitorDataType.GLUCOSE)
              .toList();

          if (allReadings.isEmpty) {
            return const Center(child: Text('No glucose data available'));
          }

          // Sort by date descending
          allReadings.sort((a, b) => b.measuredAt.compareTo(a.measuredAt));

          final thresholds = thresholdsAsync.value ?? [];
          final glucoseThreshold = thresholds.firstWhere(
            (t) => t.dataType == MonitorDataType.GLUCOSE,
            orElse: () => const HealthThreshold(
                dataType: MonitorDataType.GLUCOSE, minValue: 70, maxValue: 180),
          );

          // Calculate Analytics
          final analytics = _calculateAnalytics(allReadings, glucoseThreshold);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Summary Cards (Avg, GMI, Var)
                _buildSummaryRow(analytics),
                const SizedBox(height: 20),

                // 2. Time in Range Gauge
                _buildTIRCard(analytics),
                const SizedBox(height: 20),

                // 3. Chart Section
                _buildChartSection(allReadings, glucoseThreshold),
                const SizedBox(height: 20),

                // 4. Insights Section
                _buildInsightsCard(analytics),
                const SizedBox(height: 20),

                // 5. Paginated History
                _buildPaginatedHistory(allReadings, thresholds),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  // --- Analytics Logic ---

  Map<String, dynamic> _calculateAnalytics(
      List<MonitorData> readings, HealthThreshold threshold) {
    if (readings.isEmpty) return {};

    // Filter based on selected range for stats
    final now = DateTime.now();
    final Duration duration;
    switch (_selectedRange) {
      case '1W':
        duration = const Duration(days: 7);
        break;
      case '1M':
        duration = const Duration(days: 30);
        break;
      case '1D':
      default:
        duration = const Duration(hours: 24);
        break;
    }
    final cutoff = now.subtract(duration);
    final filtered = readings.where((r) => r.measuredAt.isAfter(cutoff)).toList();

    if (filtered.isEmpty) {
      return {
        'avg': 0.0,
        'gmi': 0.0,
        'cv': 0.0,
        'tir': 0.0,
        'count': 0,
        'lows': 0,
        'highs': 0,
      };
    }

    final values = filtered.map((e) => e.value).toList();
    final avg = values.reduce((a, b) => a + b) / values.length;
    
    // StdDev
    final variance = values.map((v) => math.pow(v - avg, 2)).reduce((a, b) => a + b) / values.length;
    final stdDev = math.sqrt(variance);
    final cv = (stdDev / avg) * 100; // Coefficient of Variation

    // GMI = 3.31 + (0.02392 * mean_glucose_mg/dL)
    final gmi = 3.31 + (0.02392 * avg);

    // Time in Range
    final inRangeCount = filtered.where((r) => r.value >= threshold.minValue && r.value <= threshold.maxValue).length;
    final tir = (inRangeCount / filtered.length) * 100;

    return {
      'avg': avg,
      'gmi': gmi,
      'cv': cv,
      'tir': tir,
      'count': filtered.length,
      'lows': filtered.where((r) => r.value < threshold.minValue).length,
      'highs': filtered.where((r) => r.value > threshold.maxValue).length,
    };
  }

  // --- UI Components ---

  Widget _buildSummaryRow(Map<String, dynamic> analytics) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Average',
            '${(analytics['avg'] as double).toStringAsFixed(0)}',
            'mg/dL',
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'GMI (Est. A1c)',
            '${(analytics['gmi'] as double).toStringAsFixed(1)}',
            '%',
            Colors.purple,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Variability',
            '${(analytics['cv'] as double).toStringAsFixed(1)}',
            '%',
            (analytics['cv'] as double) < 36 ? Colors.green : Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, String unit, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondaryColor,
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                unit,
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTIRCard(Map<String, dynamic> analytics) {
    final tir = analytics['tir'] as double;
    final color = tir >= 70 ? AppTheme.successColor : (tir >= 50 ? AppTheme.warningColor : AppTheme.errorColor);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Time In Range',
                style: AppTheme.lightTheme.textTheme.titleMedium,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Target: >70%',
                  style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Row(
                children: [
                  Expanded(
                    flex: tir.toInt(),
                    child: Container(color: AppTheme.successColor),
                  ),
                  Expanded(
                    flex: 100 - tir.toInt(),
                    child: Container(color: AppTheme.surfaceColor.withOpacity(0.5)), // Placeholder for non-range
                  ),
                ],
              ),
            ),
          ),
          // Custom Progress Bar Background
          Stack(
            children: [
              Container(
                height: 12,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.borderColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              FractionallySizedBox(
                widthFactor: (tir / 100).clamp(0.0, 1.0),
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${tir.toStringAsFixed(0)}% of readings in target',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection(List<MonitorData> allReadings, HealthThreshold threshold) {
    return Column(
      children: [
        _buildTimeRangeSelector(),
        const SizedBox(height: 16),
        _buildChartCard(allReadings, threshold),
      ],
    );
  }

  Widget _buildTimeRangeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: ['1D', '1W', '1M'].map((range) {
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
                    color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
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

  Widget _buildChartCard(List<MonitorData> allReadings, HealthThreshold threshold) {
    // Filter data based on selected range
    final now = DateTime.now();
    final Duration duration;
    switch (_selectedRange) {
      case '1W':
        duration = const Duration(days: 7);
        break;
      case '1M':
        duration = const Duration(days: 30);
        break;
      case '1D':
      default:
        duration = const Duration(hours: 24);
        break;
    }

    final cutoff = now.subtract(duration);
    final filteredReadings = allReadings
        .where((d) => d.measuredAt.isAfter(cutoff))
        .toList();
    
    // Sort for chart (ascending)
    filteredReadings.sort((a, b) => a.measuredAt.compareTo(b.measuredAt));

    if (filteredReadings.isEmpty) {
      return Container(
        height: 300,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: const Text('No data for selected period'),
      );
    }

    // Calculate Min/Max for Y-Axis with Buffer
    double dataMin = filteredReadings.map((e) => e.value).reduce(math.min);
    double dataMax = filteredReadings.map((e) => e.value).reduce(math.max);
    
    // Ensure we encompass the threshold
    double effectiveMin = math.min(dataMin, threshold.minValue);
    double effectiveMax = math.max(dataMax, threshold.maxValue);

    // Add buffer (20 units)
    double minY = (effectiveMin - 20).clamp(0, double.infinity);
    double maxY = effectiveMax + 20;

    return Container(
      height: 350,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRect( // Fix: Clip content to prevent overflow
        child: LineChart(
          LineChartData(
            minX: cutoff.millisecondsSinceEpoch.toDouble(),
            maxX: now.millisecondsSinceEpoch.toDouble(),
            minY: minY,
            maxY: maxY,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false, // Fix: Remove vertical grid lines
              horizontalInterval: 40,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: AppTheme.borderColor.withOpacity(0.3), // Fix: Lighter lines
                  strokeWidth: 1,
                  dashArray: [5, 5],
                );
              },
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: duration.inMilliseconds / 4,
                  getTitlesWidget: (value, meta) {
                    final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                    String text;
                    if (_selectedRange == '1D') {
                      text = DateFormat('HH:mm').format(date);
                    } else {
                      text = DateFormat('MM/dd').format(date);
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        text,
                        style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(fontSize: 10),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 35,
                  interval: 40,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toInt().toString(),
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(fontSize: 10),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: filteredReadings.map((d) {
                  return FlSpot(
                    d.measuredAt.millisecondsSinceEpoch.toDouble(),
                    d.value,
                  );
                }).toList(),
                isCurved: true,
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryBlue, Colors.lightBlueAccent],
                ),
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryBlue.withOpacity(0.2),
                      AppTheme.primaryBlue.withOpacity(0.0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
            rangeAnnotations: RangeAnnotations(
              horizontalRangeAnnotations: [
                HorizontalRangeAnnotation(
                  y1: threshold.minValue,
                  y2: threshold.maxValue,
                  color: AppTheme.successColor.withOpacity(0.1),
                ),
              ],
            ),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    return LineTooltipItem(
                      '${spot.y.toInt()} mg/dL',
                      const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    );
                  }).toList();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInsightsCard(Map<String, dynamic> analytics) {
    final cv = analytics['cv'] as double;
    final lows = analytics['lows'] as int;
    final highs = analytics['highs'] as int;

    String title = 'Stable';
    String message = 'Your glucose levels are relatively stable.';
    IconData icon = Icons.check_circle;
    Color color = AppTheme.successColor;

    if (lows > 2) {
      title = 'Frequent Lows';
      message = 'You had $lows low readings recently. Check your basal rates or meal boluses.';
      icon = Icons.warning_amber_rounded;
      color = AppTheme.errorColor;
    } else if (highs > 5) {
      title = 'Persistent Highs';
      message = 'You had $highs high readings. Consider reviewing your carb ratios.';
      icon = Icons.arrow_upward;
      color = AppTheme.warningColor;
    } else if (cv > 36) {
      title = 'High Variability';
      message = 'Your glucose is fluctuating significantly. Try to identify patterns.';
      icon = Icons.waves;
      color = AppTheme.warningColor;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
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
            Text(
              'History',
              style: AppTheme.lightTheme.textTheme.titleLarge,
            ),
            Text(
              'Page ${_currentPage + 1} of ${totalPages == 0 ? 1 : totalPages}',
              style: AppTheme.lightTheme.textTheme.bodySmall,
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
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderColor),
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
                          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          DateFormat('h:mm a').format(item.measuredAt),
                          style: AppTheme.lightTheme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${item.value.toInt()} mg/dL',
                        style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.getStatusColor(status.name).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          status.name.toUpperCase(),
                          style: TextStyle(
                            color: AppTheme.getStatusColor(status.name),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        // Pagination Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: _currentPage > 0
                  ? () => setState(() => _currentPage--)
                  : null,
              icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
            ),
            const SizedBox(width: 16),
            Text(
              '${_currentPage + 1} / ${totalPages == 0 ? 1 : totalPages}',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 16),
            IconButton(
              onPressed: _currentPage < totalPages - 1
                  ? () => setState(() => _currentPage++)
                  : null,
              icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
            ),
          ],
        ),
      ],
    );
  }
}
