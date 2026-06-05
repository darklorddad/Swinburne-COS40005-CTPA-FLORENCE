import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:florence/features/clinician/models/health_data.dart';
import 'package:florence/features/clinician/models/patient.dart';
import 'package:florence/features/clinician/theme/app_theme.dart';
import 'package:intl/intl.dart';

class HbA1cAnalyticsScreen extends StatefulWidget {
  final Patient patient;
  final List<HbA1cReading> readings;
  final double lowThreshold;
  final double highThreshold;

  const HbA1cAnalyticsScreen({
    super.key,
    required this.patient,
    required this.readings,
    required this.lowThreshold,
    required this.highThreshold,
  });

  @override
  State<HbA1cAnalyticsScreen> createState() => _HbA1cAnalyticsScreenState();
}

class _HbA1cAnalyticsScreenState extends State<HbA1cAnalyticsScreen> {
  int _currentPage = 0;
  final int _itemsPerPage = 5;
  String _selectedFilter = 'Daily';
  DateTime _focusedDate = DateTime.now();

  List<HbA1cReading> get _filteredReadings {
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

  List<HbA1cReading> get _filteredReadingsAsc {
    final list = List<HbA1cReading>.from(_filteredReadings);
    list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return list;
  }

  List<HbA1cReading> get _filteredReadingsDesc {
    final list = List<HbA1cReading>.from(_filteredReadings);
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

  Widget _buildHbA1cChart(List<HbA1cReading> sortedReadings) {
    if (sortedReadings.isEmpty) {
      return const Center(child: Text('No HbA1c data available'));
    }

    double minY = 3.0;
    double maxY = 15.0;
    if (sortedReadings.isNotEmpty) {
      double minVal = sortedReadings.map((r) => r.value).reduce((a, b) => a < b ? a : b);
      double maxVal = sortedReadings.map((r) => r.value).reduce((a, b) => a > b ? a : b);
      if (widget.lowThreshold < minVal) minVal = widget.lowThreshold;
      if (widget.highThreshold > maxVal) maxVal = widget.highThreshold;
      minY = (minVal - 1.0).clamp(0.0, 20.0).floorToDouble();
      maxY = (maxVal + 1.0).clamp(0.0, 30.0).ceilToDouble();
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            if (value == widget.highThreshold || value == widget.lowThreshold) {
              return FlLine(
                color: value == widget.highThreshold
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
                if (index >= 0 && index < sortedReadings.length) {
                  final date = sortedReadings[index].timestamp;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(
                      DateFormat('MM/dd').format(date),
                      style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 35,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toStringAsFixed(1)}%',
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
        maxX: sortedReadings.length - 1 > 0 ? (sortedReadings.length - 1).toDouble() : 1.0,
        minY: minY,
        maxY: maxY,
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: widget.highThreshold,
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
                labelResolver: (_) => 'High',
              ),
            ),
            HorizontalLine(
              y: widget.lowThreshold,
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
                labelResolver: (_) => 'Low',
              ),
            ),
          ],
        ),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(sortedReadings.length, (index) => FlSpot(index.toDouble(), sortedReadings[index].value)),
            isCurved: true,
            color: AppTheme.primaryColor,
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
        title: const Text('HbA1c Analytics'),
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
            _buildTrendsSection(),
            _buildHistorySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewSection() {
    final readings = _filteredReadingsDesc;
    final latest = readings.isNotEmpty ? readings.first.value : 0.0;
    final target = widget.highThreshold;
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.dividerColor, width: 1),
        ),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.track_changes_outlined, color: AppTheme.textSecondary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Actual vs. Goal',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildBar('You', latest, latest <= target ? AppTheme.lowRiskColor : AppTheme.highRiskColor),
                  _buildBar('Target', target, AppTheme.secondaryColor.withValues(alpha: 0.5)),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (latest <= target ? AppTheme.lowRiskColor : AppTheme.highRiskColor).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: (latest <= target ? AppTheme.lowRiskColor : AppTheme.highRiskColor).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      latest <= target ? Icons.check_circle : Icons.warning,
                      color: latest <= target ? AppTheme.lowRiskColor : AppTheme.highRiskColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        latest <= target 
                            ? 'You are within your target of <$target%'
                            : 'You are above your target of <$target%',
                        style: TextStyle(
                          color: latest <= target ? AppTheme.lowRiskColor : AppTheme.highRiskColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBar(String label, double value, Color color) {
    return Column(
      children: [
        Text('${value.toStringAsFixed(1)}%', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          width: 40,
          height: value * 20, // Scale factor
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildTrendsSection() {
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
                  Icon(Icons.trending_up, color: AppTheme.textSecondary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'HbA1c Trends',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 250,
                child: _buildHbA1cChart(_filteredReadingsAsc),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Pagination
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
                final isHigh = r.value > widget.highThreshold;
                final isLow = r.value < widget.lowThreshold;
                final status = isHigh ? 'ABOVE TARGET' : (isLow ? 'BELOW TARGET' : 'NORMAL');
                final color = isHigh ? AppTheme.highRiskColor : (isLow ? AppTheme.secondaryColor : AppTheme.lowRiskColor);

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            r.value.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 24, 
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textPrimary
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Padding(
                            padding: EdgeInsets.only(bottom: 4),
                            child: Text(
                              '%',
                              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                color: color,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            DateFormat('dd/MM/yy HH:mm').format(r.timestamp),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
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
}
