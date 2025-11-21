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
          final hdlThreshold = _getThreshold(thresholds, MonitorDataType.CHOLESTEROL_HDL) ?? 
              const HealthThreshold(dataType: MonitorDataType.CHOLESTEROL_HDL, minValue: 40, maxValue: 60);
          final totalThreshold = _getThreshold(thresholds, MonitorDataType.CHOLESTEROL_TOTAL) ?? 
              const HealthThreshold(dataType: MonitorDataType.CHOLESTEROL_TOTAL, minValue: 0, maxValue: 200);
          final triThreshold = _getThreshold(thresholds, MonitorDataType.CHOLESTEROL_TRIGLYCERIDES) ?? 
              const HealthThreshold(dataType: MonitorDataType.CHOLESTEROL_TRIGLYCERIDES, minValue: 0, maxValue: 150);
          
          // Construct composite latest reading from most recent available data points
          _CholesterolReading? latest;
          if (readings.isNotEmpty) {
            double? lastTotal, lastLdl, lastHdl, lastTri;
            DateTime lastDate = readings.last.timestamp;
            
            for (var r in readings.reversed) {
              if (lastTotal == null && r.total != null) lastTotal = r.total;
              if (lastLdl == null && r.ldl != null) lastLdl = r.ldl;
              if (lastHdl == null && r.hdl != null) lastHdl = r.hdl;
              if (lastTri == null && r.triglycerides != null) lastTri = r.triglycerides;
            }
            latest = _CholesterolReading(
              timestamp: lastDate,
              total: lastTotal,
              ldl: lastLdl,
              hdl: lastHdl,
              triglycerides: lastTri,
            );
          }

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
                  // 1. Ratio Donut & Targets (Overview)
                  _RatioSection(
                    reading: latest,
                    total: totalThreshold,
                    ldl: ldlThreshold,
                    hdl: hdlThreshold,
                    tri: triThreshold,
                  ),
                  const SizedBox(height: 20),
                  
                  // 3. Bullet Graph (LDL Target)
                  _LdlTargetSection(reading: latest, target: ldlThreshold.maxValue),
                  const SizedBox(height: 20),

                  // 4. Stacked Bar (Composition)
                  _CompositionSection(readings: readings),
                  const SizedBox(height: 20),
                  
                  // 5. History
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
// 1. RATIO DONUT & TARGETS (OVERVIEW)
// ============================================================================

class _RatioSection extends StatelessWidget {
  final _CholesterolReading? reading;
  final HealthThreshold total;
  final HealthThreshold ldl;
  final HealthThreshold hdl;
  final HealthThreshold tri;

  const _RatioSection({
    this.reading,
    required this.total,
    required this.ldl,
    required this.hdl,
    required this.tri,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = reading?.ratio ?? 0.0;
    // Use non-HDL cholesterol as the "bad" portion for the chart representation
    // Total = HDL + Non-HDL. So Non-HDL = Total - HDL.
    final valTotal = reading?.total ?? 0.0;
    final valHdl = reading?.hdl ?? 0.0;
    final valNonHdl = (valTotal > valHdl) ? valTotal - valHdl : 0.0;
    
    final hasData = ratio > 0;

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
      infoText: 'Your cholesterol balance.\n\n'
                '• Total Target: ${total.minValue.toInt()}-${total.maxValue.toInt()}\n'
                '• LDL Target: ${ldl.minValue.toInt()}-${ldl.maxValue.toInt()}\n'
                '• HDL Target: ${hdl.minValue.toInt()}-${hdl.maxValue.toInt()}\n'
                '• Triglycerides: ${tri.minValue.toInt()}-${tri.maxValue.toInt()}',
      child: Column(
        children: [
          // TARGET RANGES (Consistent with Glucose/BP style)
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
              child: Column(
                children: [
                  // Header Row
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
                            'Target Ranges',
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
                  // Targets List
                  _buildMiniTargetRow('Total', '${total.minValue.toInt()} - ${total.maxValue.toInt()} mg/dL', AppTheme.primaryGreen),
                  const SizedBox(height: 4),
                  _buildMiniTargetRow('LDL', '${ldl.minValue.toInt()} - ${ldl.maxValue.toInt()} mg/dL', AppTheme.primaryGreen),
                  const SizedBox(height: 4),
                  _buildMiniTargetRow('HDL', '${hdl.minValue.toInt()} - ${hdl.maxValue.toInt()} mg/dL', AppTheme.primaryGreen),
                  const SizedBox(height: 4),
                  _buildMiniTargetRow('Triglycerides', '${tri.minValue.toInt()} - ${tri.maxValue.toInt()} mg/dL', AppTheme.primaryGreen),
                ],
              ),
            ),
          ),

          // Ratio Chart
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
                          value: valHdl,
                          color: AppTheme.primaryGreen,
                          radius: 25,
                          showTitle: false,
                        ),
                        // Non-HDL (Bad)
                        PieChartSectionData(
                          value: valNonHdl > 0 ? valNonHdl : 1,
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
          if (hasData)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _LegendItem('HDL (Good)', AppTheme.primaryGreen),
                  const SizedBox(width: 16),
                  _LegendItem('Non-HDL', AppTheme.errorColor),
                ],
              ),
            ),
        ],
      ),
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
    final double maxScale = math.max(200.0, target * 1.5);
    
    return _CholesterolCard(
      title: 'LDL Performance',
      icon: Icons.track_changes,
      infoText: 'Your "Bad" Cholesterol (LDL) compared to the target limit.\n\n'
                '• Indicator: Your Level\n'
                '• Vertical Line: Target Limit (< ${target.toInt()})\n'
                '• Goal: Keep the indicator in the green zone.',
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Custom Gauge
          SizedBox(
            height: 80,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final targetPos = (target / maxScale) * width;
                final actualPos = (ldl / maxScale) * width;
                
                return Stack(
                  alignment: Alignment.centerLeft,
                  clipBehavior: Clip.none,
                  children: [
                    // 1. Background Track (Ranges)
                    Positioned(
                      top: 20,
                      left: 0,
                      right: 0,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          height: 16,
                          child: Row(
                            children: [
                              // Green Zone
                              Container(
                                width: targetPos,
                                color: AppTheme.primaryGreen.withOpacity(0.2),
                              ),
                              // Yellow Zone (Next 30mg/dL)
                              Container(
                                width: (30 / maxScale) * width,
                                color: AppTheme.warningColor.withOpacity(0.2),
                              ),
                              // Red Zone
                              Expanded(
                                child: Container(
                                  color: AppTheme.errorColor.withOpacity(0.2),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    // 2. Target Line
                    Positioned(
                      left: targetPos - 1, 
                      top: 12, 
                      child: Column(
                        children: [
                          Container(
                            width: 2,
                            height: 32,
                            color: AppTheme.textSecondaryColor,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Max\n${target.toInt()}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.textSecondaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 3. User Value Marker
                    if (ldl > 0)
                      Positioned(
                        left: (actualPos - 20).clamp(0, width - 40),
                        top: -10,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: (ldl > target) ? AppTheme.errorColor : AppTheme.primaryGreen,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              ),
                              child: Text(
                                '${ldl.toInt()}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.arrow_drop_down,
                              color: (ldl > target) ? AppTheme.errorColor : AppTheme.primaryGreen,
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 3. STACKED BAR CHART (COMPOSITION)
// ============================================================================

class _CompositionSection extends StatefulWidget {
  final List<_CholesterolReading> readings;

  const _CompositionSection({required this.readings});

  @override
  State<_CompositionSection> createState() => _CompositionSectionState();
}

class _CompositionSectionState extends State<_CompositionSection> {
  String _selectedRange = '1Y';
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

  List<_CholesterolReading> _filterData() {
    final validData = widget.readings.where((r) => (r.hdl ?? 0) + (r.ldl ?? 0) + (r.triglycerides ?? 0) > 0).toList();
    if (validData.isEmpty || _selectedRange == 'ALL') return validData;
    
    final now = DateTime.now();
    final duration = _selectedRange == '6M' ? const Duration(days: 180) : const Duration(days: 365);
    final cutoff = now.subtract(duration);
    return validData.where((r) => r.timestamp.isAfter(cutoff)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final displayData = _filterData();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _CholesterolCard(
      title: 'Cholesterol Breakdown',
      icon: Icons.bar_chart,
      infoText: 'Composition of your cholesterol levels over time.\n\n'
                '• Green (Bottom): HDL (Good)\n'
                '• Red (Middle): LDL (Bad)\n'
                '• Orange (Top): Triglycerides',
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
                  borderData: FlBorderData(show: true, border: Border.all(color: AppTheme.getBorderColor(context).withOpacity(0.5))),
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
              _LegendItem('HDL', AppTheme.primaryGreen),
              const SizedBox(width: 16),
              _LegendItem('LDL', AppTheme.errorColor),
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
// 5. HISTORY LIST
// ============================================================================

class _HistorySection extends StatefulWidget {
  final List<_CholesterolReading> readings;
  final List<HealthThreshold> thresholds;

  const _HistorySection({required this.readings, required this.thresholds});

  @override
  State<_HistorySection> createState() => _HistorySectionState();
}

class _HistorySectionState extends State<_HistorySection> {
  int _currentPage = 0;
  static const int _itemsPerPage = 5;

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
      final t = widget.thresholds.firstWhere((t) => t.dataType == type);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerColor = isDark ? AppTheme.midnightSurface : Colors.white;
    final borderColor = AppTheme.getBorderColor(context);

    // Reverse data to show latest first
    final reversed = widget.readings.reversed.toList();
    
    final totalItems = reversed.length;
    final totalPages = (totalItems / _itemsPerPage).ceil();
    if (_currentPage >= totalPages && totalPages > 0) _currentPage = totalPages - 1;
    if (totalPages == 0) _currentPage = 0;
    
    final start = _currentPage * _itemsPerPage;
    final end = math.min(start + _itemsPerPage, totalItems);
    final currentItems = totalItems > 0 ? reversed.sublist(start, end) : <_CholesterolReading>[];

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
              // Pagination Controls
              if (totalPages > 1)
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
              padding: EdgeInsets.all(20),
              child: Text('No records found'),
            )
          else
            ...currentItems.map((r) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.midnightSurface : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('MMM d, yyyy').format(r.timestamp),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          DateFormat('h:mm a').format(r.timestamp),
                          style: TextStyle(
                            color: AppTheme.textSecondaryColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Divider(color: AppTheme.borderColor.withOpacity(0.5), height: 1),
                    const SizedBox(height: 12),
                    // 2x2 Grid for values
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _MiniValue('Total', r.total, _getStatusColor(r.total, MonitorDataType.CHOLESTEROL_TOTAL))),
                        const SizedBox(width: 8),
                        Expanded(child: _MiniValue('Triglycerides', r.triglycerides, _getStatusColor(r.triglycerides, MonitorDataType.CHOLESTEROL_TRIGLYCERIDES))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _MiniValue('LDL (Bad)', r.ldl, _getStatusColor(r.ldl, MonitorDataType.CHOLESTEROL_LDL))),
                        const SizedBox(width: 8),
                        Expanded(child: _MiniValue('HDL (Good)', r.hdl, _getStatusColor(r.hdl, MonitorDataType.CHOLESTEROL_HDL))),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor)),
        const SizedBox(height: 2),
        Text(
          value != null ? '${value!.toInt()} mg/dL' : '--',
          style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14),
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
