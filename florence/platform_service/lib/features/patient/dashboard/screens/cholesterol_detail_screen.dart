import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../../../../config/theme.dart';
import '../../core/models/health_data_models.dart';
import '../../dashboard/providers/dashboard_providers.dart';

class CholesterolDetailScreen extends ConsumerWidget {
  const CholesterolDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monitorAsync = ref.watch(monitorDataProvider);
    final thresholdsAsync = ref.watch(patientThresholdsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cholesterol Analytics'),
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
          final readings = _processReadings(dataList);
          
          // Sort by date ascending
          readings.sort((a, b) => a.timestamp.compareTo(b.timestamp));

          final thresholds = thresholdsAsync.value ?? [];
          
          // Get thresholds (Defaulting to standard mg/dL values if not set)
          final ldlThreshold = _getThreshold(thresholds, MonitorDataType.CHOLESTEROL_LDL) ?? 
              const HealthThreshold(dataType: MonitorDataType.CHOLESTEROL_LDL, minValue: 0, maxValue: 100);
          
          final latest = readings.isNotEmpty ? readings.last : null;

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
                  // 1. Ratio Donut (Good vs Bad Balance)
                  _RatioSection(reading: latest),
                  const SizedBox(height: 20),
                  
                  // 2. Bullet Graph (LDL Target)
                  _LdlTargetSection(reading: latest, target: ldlThreshold.maxValue),
                  const SizedBox(height: 20),

                  // 3. Stacked Bar (Composition)
                  _CompositionSection(readings: readings),
                  const SizedBox(height: 20),
                  
                  // 4. History
                  _HistorySection(readings: readings, thresholds: thresholds),
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

  HealthThreshold? _getThreshold(List<HealthThreshold> thresholds, MonitorDataType type) {
    try {
      return thresholds.firstWhere((t) => t.dataType == type);
    } catch (_) {
      return null;
    }
  }

  List<_CholesterolReading> _processReadings(List<MonitorData> data) {
    final Map<String, _CholesterolReading> grouped = {};

    for (var d in data) {
      // Group by day
      final key = DateFormat('yyyy-MM-dd').format(d.measuredAt);
      
      if (!grouped.containsKey(key)) {
        grouped[key] = _CholesterolReading(timestamp: d.measuredAt);
      }
      
      final current = grouped[key]!;
      
      switch (d.dataType) {
        case MonitorDataType.CHOLESTEROL_TOTAL:
          grouped[key] = current.copyWith(total: d.value);
          break;
        case MonitorDataType.CHOLESTEROL_LDL:
          grouped[key] = current.copyWith(ldl: d.value);
          break;
        case MonitorDataType.CHOLESTEROL_HDL:
          grouped[key] = current.copyWith(hdl: d.value);
          break;
        case MonitorDataType.CHOLESTEROL_TRIGLYCERIDES:
          grouped[key] = current.copyWith(triglycerides: d.value);
          break;
        default:
          break;
      }
    }
    
    return grouped.values.toList();
  }
}

class _CholesterolReading {
  final DateTime timestamp;
  final double? total;
  final double? ldl;
  final double? hdl;
  final double? triglycerides;

  _CholesterolReading({
    required this.timestamp,
    this.total,
    this.ldl,
    this.hdl,
    this.triglycerides,
  });

  _CholesterolReading copyWith({
    DateTime? timestamp,
    double? total,
    double? ldl,
    double? hdl,
    double? triglycerides,
  }) {
    return _CholesterolReading(
      timestamp: timestamp ?? this.timestamp,
      total: total ?? this.total,
      ldl: ldl ?? this.ldl,
      hdl: hdl ?? this.hdl,
      triglycerides: triglycerides ?? this.triglycerides,
    );
  }

  double get ratio {
    if (total != null && hdl != null && hdl! > 0) {
      return total! / hdl!;
    }
    return 0.0;
  }
}

// ============================================================================
// 1. RATIO DONUT CHART
// ============================================================================

class _RatioSection extends StatelessWidget {
  final _CholesterolReading? reading;

  const _RatioSection({this.reading});

  @override
  Widget build(BuildContext context) {
    final ratio = reading?.ratio ?? 0.0;
    final ldl = reading?.ldl ?? 0.0;
    final hdl = reading?.hdl ?? 0.0;
    final hasData = ldl > 0 || hdl > 0;

    String statusText;
    Color statusColor;

    if (ratio == 0) {
      statusText = "No Data";
      statusColor = AppTheme.textSecondaryColor;
    } else if (ratio < 3.5) {
      statusText = "Excellent";
      statusColor = AppTheme.primaryGreen;
    } else if (ratio < 5.0) {
      statusText = "Good";
      statusColor = AppTheme.primaryBlue;
    } else {
      statusText = "High Risk";
      statusColor = AppTheme.errorColor;
    }

    return _CholesterolCard(
      title: 'Cholesterol Ratio',
      icon: Icons.pie_chart,
      infoText: 'The ratio of Total Cholesterol to HDL.\n\n'
                '• Formula: Total / HDL\n'
                '• Target: Below 5.0 (Lower is better)\n'
                '• Ideal: Below 3.5',
      child: Column(
        children: [
          // Target Range Display
          InkWell(
            onTap: () => Navigator.of(context).pushNamed('/profile'),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryGreen.withOpacity(0.3),
                ),
              ),
              child: Row(
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
                  Row(
                    children: [
                      Text(
                        '< 5.0',
                        style: TextStyle(
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: AppTheme.primaryGreen.withOpacity(0.5),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (hasData)
                  PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 60,
                      sections: [
                        // HDL (Good)
                        PieChartSectionData(
                          value: hdl,
                          color: AppTheme.primaryGreen,
                          radius: 25,
                          showTitle: false,
                        ),
                        // LDL (Bad) - Using LDL as the main "bad" component for visual balance
                        PieChartSectionData(
                          value: ldl > 0 ? ldl : 1, // Ensure at least small slice if 0 but HDL exists
                          color: AppTheme.errorColor,
                          radius: 25,
                          showTitle: false,
                        ),
                      ],
                    ),
                  )
                else
                  PieChart(
                    PieChartData(
                      sectionsSpace: 0,
                      centerSpaceRadius: 60,
                      sections: [
                        PieChartSectionData(
                          value: 1,
                          color: Colors.grey.shade200,
                          radius: 25,
                          showTitle: false,
                        ),
                      ],
                    ),
                  ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Ratio',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      ratio > 0 ? ratio.toStringAsFixed(1) : '--',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        statusText,
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
        ],
      ),
    );
  }
}

// ============================================================================
// 2. BULLET GRAPH (LDL vs TARGET)
// ============================================================================

class _LdlTargetSection extends StatelessWidget {
  final _CholesterolReading? reading;
  final double target;

  const _LdlTargetSection({this.reading, required this.target});

  @override
  Widget build(BuildContext context) {
    final ldl = reading?.ldl ?? 0.0;
    // Define scale max (e.g., 200 mg/dL or 2x target)
    final double maxScale = math.max(200.0, target * 1.5);
    
    return _CholesterolCard(
      title: 'LDL Performance',
      icon: Icons.track_changes,
      infoText: 'Your "Bad" Cholesterol (LDL) compared to the target limit.\n\n'
                '• Bar: Your Level\n'
                '• Vertical Line: Target Limit (< ${target.toInt()})\n'
                '• Goal: Keep the bar to the left of the line.',
      child: Column(
        children: [
          const SizedBox(height: 10),
          // Bullet Graph Container
          SizedBox(
            height: 60,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final targetPos = (target / maxScale) * width;
                final actualPos = (ldl / maxScale) * width;
                
                return Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    // 1. Background Ranges
                    Row(
                      children: [
                        // Green Zone (0 to Target)
                        Container(
                          width: targetPos,
                          height: 30,
                          color: AppTheme.primaryGreen.withOpacity(0.15),
                        ),
                        // Yellow Zone (Target to Target + 30)
                        Container(
                          width: (30 / maxScale) * width,
                          height: 30,
                          color: AppTheme.warningColor.withOpacity(0.15),
                        ),
                        // Red Zone (Rest)
                        Expanded(
                          child: Container(
                            height: 30,
                            color: AppTheme.errorColor.withOpacity(0.15),
                          ),
                        ),
                      ],
                    ),
                    
                    // 2. Actual Value Bar
                    if (ldl > 0)
                      Container(
                        width: actualPos.clamp(0, width),
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppTheme.textPrimaryColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      
                    // 3. Target Marker
                    Positioned(
                      left: targetPos,
                      child: Container(
                        width: 4,
                        height: 40,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0', style: Theme.of(context).textTheme.bodySmall),
              Text(
                'Target: ${target.toInt()}', 
                style: TextStyle(
                  color: AppTheme.primaryBlue, 
                  fontWeight: FontWeight.bold,
                  fontSize: 12
                )
              ),
              Text('${maxScale.toInt()}+', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 16),
          // Current Value Text
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Current LDL: ',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                ldl > 0 ? '${ldl.toInt()} mg/dL' : '--',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: (ldl > target) ? AppTheme.errorColor : AppTheme.primaryGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 3. STACKED BAR CHART (COMPOSITION)
// ============================================================================

class _CompositionSection extends StatelessWidget {
  final List<_CholesterolReading> readings;

  const _CompositionSection({required this.readings});

  @override
  Widget build(BuildContext context) {
    // Filter out readings with no data
    final data = readings.where((r) => (r.hdl ?? 0) + (r.ldl ?? 0) + (r.triglycerides ?? 0) > 0).toList();
    
    // Limit to last 7 readings for clarity
    final displayData = data.length > 7 ? data.sublist(data.length - 7) : data;

    return _CholesterolCard(
      title: 'Cholesterol Breakdown',
      icon: Icons.bar_chart,
      infoText: 'Composition of your cholesterol levels over time.\n\n'
                '• Green (Bottom): HDL (Good)\n'
                '• Red (Middle): LDL (Bad)\n'
                '• Orange (Top): Triglycerides',
      child: Column(
        children: [
          if (displayData.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Text('No detailed data available'),
            )
          else
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          if (val.toInt() >= displayData.length) return const SizedBox();
                          final date = displayData[val.toInt()].timestamp;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              DateFormat('MMM d').format(date),
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(color: AppTheme.getBorderColor(context).withOpacity(0.2), strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: displayData.asMap().entries.map((entry) {
                    final index = entry.key;
                    final r = entry.value;
                    final hdl = r.hdl ?? 0;
                    final ldl = r.ldl ?? 0;
                    final tri = r.triglycerides ?? 0;
                    
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: hdl + ldl + tri,
                          width: 16,
                          borderRadius: BorderRadius.circular(2),
                          rodStackItems: [
                            BarChartRodStackItem(0, hdl, AppTheme.primaryGreen),
                            BarChartRodStackItem(hdl, hdl + ldl, AppTheme.errorColor),
                            BarChartRodStackItem(hdl + ldl, hdl + ldl + tri, Colors.orange),
                          ],
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendItem('HDL (Good)', AppTheme.primaryGreen),
              const SizedBox(width: 16),
              _LegendItem('LDL (Bad)', AppTheme.errorColor),
              const SizedBox(width: 16),
              _LegendItem('Triglycerides', Colors.orange),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 4. HISTORY LIST
// ============================================================================

class _HistorySection extends StatelessWidget {
  final List<_CholesterolReading> readings;
  final List<HealthThreshold> thresholds;

  const _HistorySection({required this.readings, required this.thresholds});

  Color _getStatusColor(double? value, MonitorDataType type) {
    if (value == null) return AppTheme.textSecondaryColor;
    
    // Default thresholds if not found
    double min = 0;
    double max = 200;
    
    if (type == MonitorDataType.CHOLESTEROL_HDL) {
      min = 40;
      max = 100;
    } else if (type == MonitorDataType.CHOLESTEROL_LDL) {
      max = 100;
    } else if (type == MonitorDataType.CHOLESTEROL_TRIGLYCERIDES) {
      max = 150;
    }

    try {
      final t = thresholds.firstWhere((t) => t.dataType == type);
      min = t.minValue;
      max = t.maxValue;
    } catch (_) {}

    if (type == MonitorDataType.CHOLESTEROL_HDL) {
      // HDL: Higher is better. Low is bad.
      return value < min ? AppTheme.errorColor : AppTheme.primaryGreen;
    } else {
      // LDL/Total/Tri: Lower is better. High is bad.
      return value > max ? AppTheme.errorColor : AppTheme.primaryGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    final reversed = readings.reversed.toList();
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
          const SizedBox(height: 20),
          if (reversed.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('No records found'),
            )
          else
            ...reversed.take(5).map((r) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.midnightSurface : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('MMM d, yyyy').format(r.timestamp),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Total: ${r.total?.toInt() ?? "--"} mg/dL',
                          style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            _MiniValue('LDL', r.ldl, _getStatusColor(r.ldl, MonitorDataType.CHOLESTEROL_LDL)),
                            const SizedBox(width: 12),
                            _MiniValue('HDL', r.hdl, _getStatusColor(r.hdl, MonitorDataType.CHOLESTEROL_HDL)),
                          ],
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

class _MiniValue extends StatelessWidget {
  final String label;
  final double? value;
  final Color color;

  const _MiniValue(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: AppTheme.textSecondaryColor)),
        Text(
          value?.toInt().toString() ?? '--',
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}

// ============================================================================
// HELPERS
// ============================================================================

class _CholesterolCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String infoText;
  final Widget child;

  const _CholesterolCard({
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
          const SizedBox(height: 24),
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
