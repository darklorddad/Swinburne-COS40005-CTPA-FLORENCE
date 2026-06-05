import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:florence/features/clinician/models/health_data.dart';
import 'package:florence/features/clinician/models/patient.dart';
import 'package:florence/features/clinician/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'dart:math';

class CholesterolAnalyticsScreen extends StatefulWidget {
  final Patient patient;
  final List<CholesterolReading> readings;
  final double totalLow;
  final double totalHigh;
  final double ldlLow;
  final double ldlHigh;
  final double hdlLow;
  final double hdlHigh;
  final double trigLow;
  final double trigHigh;
  final String cholesterolUnit;

  const CholesterolAnalyticsScreen({
    super.key,
    required this.patient,
    required this.readings,
    required this.totalLow,
    required this.totalHigh,
    required this.ldlLow,
    required this.ldlHigh,
    required this.hdlLow,
    required this.hdlHigh,
    required this.trigLow,
    required this.trigHigh,
    required this.cholesterolUnit,
  });

  @override
  State<CholesterolAnalyticsScreen> createState() => _CholesterolAnalyticsScreenState();
}

class _CholesterolAnalyticsScreenState extends State<CholesterolAnalyticsScreen> {
  int _currentPage = 0;
  final int _itemsPerPage = 5;
  String _selectedFilter = 'Daily';
  DateTime _focusedDate = DateTime.now();
  String _selectedMetric = 'Total';

  List<CholesterolReading> get _filteredReadings {
    final filtered = widget.readings.where((r) {
      if (_selectedFilter == 'Hourly') {
        final start = DateTime(_focusedDate.year, _focusedDate.month, _focusedDate.day);
        final end = start.add(const Duration(days: 1));
        return r.timestamp.isAfter(start) && r.timestamp.isBefore(end);
      } else if (_selectedFilter == 'Daily') {
        final start = DateTime(_focusedDate.year, _focusedDate.month, _focusedDate.day).subtract(Duration(days: _focusedDate.weekday - 1));
        final end = start.add(const Duration(days: 7));
        return r.timestamp.isAfter(start) && r.timestamp.isBefore(end);
      } else {
        final start = DateTime(_focusedDate.year, 1, 1);
        final end = DateTime(_focusedDate.year + 1, 1, 1);
        return r.timestamp.isAfter(start) && r.timestamp.isBefore(end);
      }
    }).toList();
    return filtered;
  }

  List<CholesterolReading> get _filteredReadingsAsc {
    final list = List<CholesterolReading>.from(_filteredReadings);
    list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return list;
  }

  List<CholesterolReading> get _filteredReadingsDesc {
    final list = List<CholesterolReading>.from(_filteredReadings);
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  Widget _buildFilterHeader({
    required String selectedFilter,
    required DateTime focusedDate,
    required Function(String) onFilterChanged,
    required Function(DateTime) onDateChanged,
  }) {
    String dateLabel = '';
    if (selectedFilter == 'Hourly') {
      dateLabel = DateFormat('EEEE, d MMMM yyyy').format(focusedDate);
    } else if (selectedFilter == 'Daily') {
      final startOfWeek = focusedDate.subtract(Duration(days: focusedDate.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      dateLabel = '${DateFormat('d MMM').format(startOfWeek)} - ${DateFormat('d MMM yyyy').format(endOfWeek)}';
    } else {
      dateLabel = DateFormat('yyyy').format(focusedDate);
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.dividerColor, width: 1),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'Hourly', label: Text('24 Hours', style: TextStyle(fontSize: 12))),
                      ButtonSegment(value: 'Daily', label: Text('7 Days', style: TextStyle(fontSize: 12))),
                      ButtonSegment(value: 'Yearly', label: Text('12 Months', style: TextStyle(fontSize: 12))),
                    ],
                    selected: {selectedFilter},
                    onSelectionChanged: (newSelection) {
                      onFilterChanged(newSelection.first);
                    },
                    style: SegmentedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      selectedBackgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                      selectedForegroundColor: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: AppTheme.primaryColor),
                  onPressed: () {
                    if (selectedFilter == 'Hourly') {
                      onDateChanged(focusedDate.subtract(const Duration(days: 1)));
                    } else if (selectedFilter == 'Daily') {
                      onDateChanged(focusedDate.subtract(const Duration(days: 7)));
                    } else {
                      onDateChanged(DateTime(focusedDate.year - 1, focusedDate.month, focusedDate.day));
                    }
                  },
                ),
                Text(
                  dateLabel,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: AppTheme.primaryColor),
                  onPressed: () {
                    if (selectedFilter == 'Hourly') {
                      onDateChanged(focusedDate.add(const Duration(days: 1)));
                    } else if (selectedFilter == 'Daily') {
                      onDateChanged(focusedDate.add(const Duration(days: 7)));
                    } else {
                      onDateChanged(DateTime(focusedDate.year + 1, focusedDate.month, focusedDate.day));
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<CholesterolReading> _getAggregatedReadings(List<CholesterolReading> rawReadings) {
    if (rawReadings.isEmpty) return [];

    if (_selectedFilter == 'Hourly') {
      final Map<int, List<double>> totalGrouped = {};
      final Map<int, List<double>> ldlGrouped = {};
      final Map<int, List<double>> hdlGrouped = {};
      final Map<int, List<double>> trigGrouped = {};
      for (var r in rawReadings) {
        totalGrouped.putIfAbsent(r.timestamp.hour, () => []).add(r.total);
        ldlGrouped.putIfAbsent(r.timestamp.hour, () => []).add(r.ldl);
        hdlGrouped.putIfAbsent(r.timestamp.hour, () => []).add(r.hdl);
        trigGrouped.putIfAbsent(r.timestamp.hour, () => []).add(r.triglycerides);
      }
      final List<CholesterolReading> result = [];
      final start = DateTime(_focusedDate.year, _focusedDate.month, _focusedDate.day);
      for (int hour = 0; hour < 24; hour++) {
        if (totalGrouped.containsKey(hour)) {
          final avgTotal = totalGrouped[hour]!.reduce((a, b) => a + b) / totalGrouped[hour]!.length;
          final avgLdl = ldlGrouped[hour]!.reduce((a, b) => a + b) / ldlGrouped[hour]!.length;
          final avgHdl = hdlGrouped[hour]!.reduce((a, b) => a + b) / hdlGrouped[hour]!.length;
          final avgTrig = trigGrouped[hour]!.reduce((a, b) => a + b) / trigGrouped[hour]!.length;
          result.add(CholesterolReading(
            timestamp: DateTime(start.year, start.month, start.day, hour),
            total: avgTotal,
            ldl: avgLdl,
            hdl: avgHdl,
            triglycerides: avgTrig,
          ));
        }
      }
      return result;
    } else if (_selectedFilter == 'Daily') {
      final Map<int, List<double>> totalGrouped = {};
      final Map<int, List<double>> ldlGrouped = {};
      final Map<int, List<double>> hdlGrouped = {};
      final Map<int, List<double>> trigGrouped = {};
      for (var r in rawReadings) {
        totalGrouped.putIfAbsent(r.timestamp.weekday, () => []).add(r.total);
        ldlGrouped.putIfAbsent(r.timestamp.weekday, () => []).add(r.ldl);
        hdlGrouped.putIfAbsent(r.timestamp.weekday, () => []).add(r.hdl);
        trigGrouped.putIfAbsent(r.timestamp.weekday, () => []).add(r.triglycerides);
      }
      final List<CholesterolReading> result = [];
      final startOfWeek = DateTime(_focusedDate.year, _focusedDate.month, _focusedDate.day).subtract(Duration(days: _focusedDate.weekday - 1));
      for (int day = 1; day <= 7; day++) {
        if (totalGrouped.containsKey(day)) {
          final avgTotal = totalGrouped[day]!.reduce((a, b) => a + b) / totalGrouped[day]!.length;
          final avgLdl = ldlGrouped[day]!.reduce((a, b) => a + b) / ldlGrouped[day]!.length;
          final avgHdl = hdlGrouped[day]!.reduce((a, b) => a + b) / hdlGrouped[day]!.length;
          final avgTrig = trigGrouped[day]!.reduce((a, b) => a + b) / trigGrouped[day]!.length;
          result.add(CholesterolReading(
            timestamp: startOfWeek.add(Duration(days: day - 1)),
            total: avgTotal,
            ldl: avgLdl,
            hdl: avgHdl,
            triglycerides: avgTrig,
          ));
        }
      }
      return result;
    } else {
      final Map<int, List<double>> totalGrouped = {};
      final Map<int, List<double>> ldlGrouped = {};
      final Map<int, List<double>> hdlGrouped = {};
      final Map<int, List<double>> trigGrouped = {};
      for (var r in rawReadings) {
        totalGrouped.putIfAbsent(r.timestamp.month, () => []).add(r.total);
        ldlGrouped.putIfAbsent(r.timestamp.month, () => []).add(r.ldl);
        hdlGrouped.putIfAbsent(r.timestamp.month, () => []).add(r.hdl);
        trigGrouped.putIfAbsent(r.timestamp.month, () => []).add(r.triglycerides);
      }
      final List<CholesterolReading> result = [];
      for (int month = 1; month <= 12; month++) {
        if (totalGrouped.containsKey(month)) {
          final avgTotal = totalGrouped[month]!.reduce((a, b) => a + b) / totalGrouped[month]!.length;
          final avgLdl = ldlGrouped[month]!.reduce((a, b) => a + b) / ldlGrouped[month]!.length;
          final avgHdl = hdlGrouped[month]!.reduce((a, b) => a + b) / hdlGrouped[month]!.length;
          final avgTrig = trigGrouped[month]!.reduce((a, b) => a + b) / trigGrouped[month]!.length;
          result.add(CholesterolReading(
            timestamp: DateTime(_focusedDate.year, month, 1),
            total: avgTotal,
            ldl: avgLdl,
            hdl: avgHdl,
            triglycerides: avgTrig,
          ));
        }
      }
      return result;
    }
  }

  Widget _buildCholesterolChart(List<CholesterolReading> rawReadings) {
    final sortedReadings = _getAggregatedReadings(rawReadings);
    if (sortedReadings.isEmpty) {
      return const Center(child: Text('No cholesterol data available'));
    }

    double lowThresh = widget.totalLow;
    double highThresh = widget.totalHigh;
    Color metricColor = AppTheme.primaryColor;
    String label = 'Total';

    if (_selectedMetric == 'LDL') {
      lowThresh = widget.ldlLow;
      highThresh = widget.ldlHigh;
      metricColor = AppTheme.highRiskColor;
      label = 'LDL';
    } else if (_selectedMetric == 'HDL') {
      lowThresh = widget.hdlLow;
      highThresh = widget.hdlHigh;
      metricColor = AppTheme.lowRiskColor;
      label = 'HDL';
    } else if (_selectedMetric == 'Triglycerides') {
      lowThresh = widget.trigLow;
      highThresh = widget.trigHigh;
      metricColor = Colors.orange;
      label = 'Triglycerides';
    }

    // Calculate min/max based on selected metric
    List<double> values = sortedReadings.map((r) {
      if (_selectedMetric == 'LDL') return r.ldl;
      if (_selectedMetric == 'HDL') return r.hdl;
      if (_selectedMetric == 'Triglycerides') return r.triglycerides;
      return r.total;
    }).toList();

    double minVal = values.reduce(min);
    double maxVal = values.reduce(max);

    if (lowThresh < minVal) minVal = lowThresh;
    if (highThresh > maxVal) maxVal = highThresh;

    final double minY = (minVal - 1.0).clamp(0.0, double.infinity).floorToDouble();
    final double maxY = (maxVal + 1.0).ceilToDouble();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            if (value == highThresh || value == lowThresh) {
              return FlLine(
                color: value == highThresh
                    ? AppTheme.highRiskColor.withValues(alpha: 0.4)
                    : AppTheme.lowRiskColor.withValues(alpha: 0.4),
                strokeWidth: 1,
                dashArray: [4, 4],
              );
            }
            return FlLine(
              color: Colors.grey[200]!,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0) return const Text('');
                
                String label = '';
                if (_selectedFilter == 'Hourly') {
                  if (index % 4 == 0 && index < 24) {
                    label = '${index.toString().padLeft(2, '0')}:00';
                  }
                } else if (_selectedFilter == 'Daily') {
                  if (index >= 0 && index < 7) {
                    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                    label = weekdays[index];
                  }
                } else {
                  if (index >= 0 && index < 12) {
                    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                    label = months[index];
                  }
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Text(
                    label,
                    style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 35,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(1),
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(color: Colors.grey[300]!),
            left: BorderSide(color: Colors.grey[300]!),
          ),
        ),
        minX: 0,
        maxX: _selectedFilter == 'Hourly' ? 23 : (_selectedFilter == 'Daily' ? 6 : 11),
        minY: minY,
        maxY: maxY,
        rangeAnnotations: RangeAnnotations(
          horizontalRangeAnnotations: [
            HorizontalRangeAnnotation(
              y1: lowThresh,
              y2: highThresh,
              color: AppTheme.lowRiskColor.withValues(alpha: 0.06),
            ),
          ],
        ),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: highThresh,
              color: AppTheme.highRiskColor.withValues(alpha: 0.6),
              strokeWidth: 1,
              dashArray: [5, 5],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                padding: const EdgeInsets.only(right: 5, bottom: 2),
                style: TextStyle(
                  color: AppTheme.highRiskColor.withValues(alpha: 0.8),
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
                labelResolver: (_) => '$label High',
              ),
            ),
            HorizontalLine(
              y: lowThresh,
              color: AppTheme.lowRiskColor.withValues(alpha: 0.6),
              strokeWidth: 1,
              dashArray: [5, 5],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.bottomRight,
                padding: const EdgeInsets.only(right: 5, top: 2),
                style: TextStyle(
                  color: AppTheme.lowRiskColor.withValues(alpha: 0.8),
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
                labelResolver: (_) => '$label Low',
              ),
            ),
          ],
        ),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(sortedReadings.length, (index) {
              final r = sortedReadings[index];
              double x = 0;
              if (_selectedFilter == 'Hourly') {
                x = r.timestamp.hour.toDouble();
              } else if (_selectedFilter == 'Daily') {
                x = (r.timestamp.weekday - 1).toDouble();
              } else {
                x = (r.timestamp.month - 1).toDouble();
              }
              return FlSpot(x, values[index]);
            }),
            isCurved: true,
            color: metricColor,
            barWidth: 3,
            dotData: FlDotData(show: true),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cholesterol Analytics'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildFilterHeader(
              selectedFilter: _selectedFilter,
              focusedDate: _focusedDate,
              onFilterChanged: (filter) => setState(() => _selectedFilter = filter),
              onDateChanged: (date) => setState(() => _focusedDate = date),
            ),
            _buildOverviewSection(),
            _buildBreakdownSection(),
            _buildHistorySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewSection() {
    final readings = _filteredReadingsDesc;
    final latest = readings.isNotEmpty ? readings.first : null;
    double ratio = 0;
    if (latest != null && latest.hdl > 0) {
      ratio = latest.total / latest.hdl;
    }

    final decimals = widget.cholesterolUnit == 'mmol/L' ? 1 : 0;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.dividerColor, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.monitor_heart_outlined, color: AppTheme.textSecondary, size: 20),
                      SizedBox(width: 8),
                      Text('Cholesterol Ratio', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    ],
                  ),
                  Icon(Icons.info_outline, size: 20, color: AppTheme.textSecondary),
                ],
              ),
              const SizedBox(height: 20),
              // Target Ranges Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.lowRiskColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.lowRiskColor.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Target Ranges', style: TextStyle(color: AppTheme.lowRiskColor, fontWeight: FontWeight.bold)),
                        Icon(Icons.check_circle_outline, color: AppTheme.lowRiskColor, size: 16),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTargetRow('Total', '${widget.totalLow.toStringAsFixed(decimals)} - ${widget.totalHigh.toStringAsFixed(decimals)} ${widget.cholesterolUnit}'),
                    _buildTargetRow('LDL', '${widget.ldlLow.toStringAsFixed(decimals)} - ${widget.ldlHigh.toStringAsFixed(decimals)} ${widget.cholesterolUnit}'),
                    _buildTargetRow('HDL', '${widget.hdlLow.toStringAsFixed(decimals)} - ${widget.hdlHigh.toStringAsFixed(decimals)} ${widget.cholesterolUnit}'),
                    _buildTargetRow('Triglycerides', '${widget.trigLow.toStringAsFixed(decimals)} - ${widget.trigHigh.toStringAsFixed(decimals)} ${widget.cholesterolUnit}'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Ratio Chart
              Center(
                child: SizedBox(
                  height: 150,
                  width: 150,
                  child: CustomPaint(
                    painter: _RatioPainter(ratio: ratio),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Ratio', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(
                            ratio.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.lowRiskColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              ratio < 5 ? 'Excellent' : 'High',
                              style: TextStyle(
                                fontSize: 10,
                                color: ratio < 5 ? AppTheme.lowRiskColor : AppTheme.highRiskColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem('HDL (Good)', AppTheme.lowRiskColor),
                  const SizedBox(width: 16),
                  _buildLegendItem('Non-HDL', AppTheme.highRiskColor),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTargetRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppTheme.lowRiskColor.withValues(alpha: 0.8), fontSize: 13)),
          Text(value, style: const TextStyle(color: AppTheme.lowRiskColor, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildBreakdownSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.dividerColor, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.bar_chart, color: AppTheme.textSecondary, size: 20),
                  SizedBox(width: 8),
                  Text('Cholesterol Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'Total', label: Text('Total', style: TextStyle(fontSize: 11))),
                        ButtonSegment(value: 'LDL', label: Text('LDL', style: TextStyle(fontSize: 11))),
                        ButtonSegment(value: 'HDL', label: Text('HDL', style: TextStyle(fontSize: 11))),
                        ButtonSegment(value: 'Triglycerides', label: Text('Trig', style: TextStyle(fontSize: 11))),
                      ],
                      selected: {_selectedMetric},
                      onSelectionChanged: (newSelection) {
                        setState(() {
                          _selectedMetric = newSelection.first;
                        });
                      },
                      style: SegmentedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        selectedBackgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                        selectedForegroundColor: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 250,
                child: _buildCholesterolChart(widget.readings),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_selectedMetric == 'Total') _buildLegendItem('Total', AppTheme.primaryColor),
                  if (_selectedMetric == 'LDL') _buildLegendItem('LDL', AppTheme.highRiskColor),
                  if (_selectedMetric == 'HDL') _buildLegendItem('HDL', AppTheme.lowRiskColor),
                  if (_selectedMetric == 'Triglycerides') _buildLegendItem('Triglycerides', Colors.orange),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistorySection() {
    final sortedReadings = _filteredReadingsDesc;
    
    final totalPages = (sortedReadings.length / _itemsPerPage).ceil();
    if (_currentPage >= totalPages) _currentPage = totalPages > 0 ? totalPages - 1 : 0;

    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage < sortedReadings.length) ? startIndex + _itemsPerPage : sortedReadings.length;
    final pageItems = sortedReadings.sublist(startIndex, endIndex);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.dividerColor, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Header
              Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.history, color: AppTheme.primaryColor),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'History',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              if (totalPages > 1)
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text('${_currentPage + 1}/$totalPages'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: _currentPage < totalPages - 1 ? () => setState(() => _currentPage++) : null,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (pageItems.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(16), child: Text("No history available")))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: pageItems.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final r = pageItems[index];
                final isHigh = r.total >= widget.totalHigh;
                final status = isHigh ? 'HIGH' : (r.total >= widget.totalLow ? 'NORMAL' : 'LOW');
                final color = isHigh ? AppTheme.highRiskColor : (r.total >= widget.totalLow ? AppTheme.lowRiskColor : AppTheme.primaryColor);

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                widget.cholesterolUnit == 'mmol/L'
                                    ? r.total.toStringAsFixed(1)
                                    : r.total.toInt().toString(),
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 4),
                              Text('Total ${widget.cholesterolUnit}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('dd/MM/yy HH:mm').format(r.timestamp),
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildDetailColumn(
                            'LDL',
                            widget.cholesterolUnit == 'mmol/L'
                                ? r.ldl.toStringAsFixed(1)
                                : r.ldl.toInt().toString(),
                            widget.cholesterolUnit,
                            AppTheme.highRiskColor,
                          ),
                          _buildDetailColumn(
                            'HDL',
                            widget.cholesterolUnit == 'mmol/L'
                                ? r.hdl.toStringAsFixed(1)
                                : r.hdl.toInt().toString(),
                            widget.cholesterolUnit,
                            AppTheme.lowRiskColor,
                          ),
                          _buildDetailColumn(
                            'Triglycerides',
                            widget.cholesterolUnit == 'mmol/L'
                                ? r.triglycerides.toStringAsFixed(1)
                                : r.triglycerides.toInt().toString(),
                            widget.cholesterolUnit,
                            Colors.orange,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
        ),
      ),
    );
  }

  Widget _buildDetailColumn(String label, String value, String unit, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(width: 2),
            Text(unit, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ],
    );
  }
}

class _RatioPainter extends CustomPainter {
  final double ratio;

  _RatioPainter({required this.ratio});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    final strokeWidth = 20.0;

    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = Colors.grey.withValues(alpha: 0.1);

    canvas.drawCircle(center, radius, bgPaint);

    // Draw HDL segment (Good) - Green
    // Ratio implies Total/HDL. The "good" part is HDL.
    // Visualizing ratio isn't direct pie chart.
    // Let's just draw two segments based on an arbitrary "good" vs "bad" proportion for visual effect matching the image.
    // Image shows ~60% Red, 40% Green.
    // Let's assume Green is 1/Ratio portion? No.
    // I'll just draw a static representation or based on (HDL / Total) * 360 degrees.
    
    // HDL %
    double hdlPct = 0.3; // Default fallback
    if (ratio > 0) {
      hdlPct = 1 / ratio; // HDL / Total
    }
    
    final rect = Rect.fromCircle(center: center, radius: radius);
    
    final hdlPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = AppTheme.lowRiskColor
      ..strokeCap = StrokeCap.round;

    final nonHdlPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = AppTheme.highRiskColor
      ..strokeCap = StrokeCap.round;

    // Draw Non-HDL (Red)
    canvas.drawArc(rect, -pi / 2, 2 * pi * (1 - hdlPct), false, nonHdlPaint);
    
    // Draw HDL (Green)
    canvas.drawArc(rect, -pi / 2 + (2 * pi * (1 - hdlPct)), 2 * pi * hdlPct, false, hdlPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

