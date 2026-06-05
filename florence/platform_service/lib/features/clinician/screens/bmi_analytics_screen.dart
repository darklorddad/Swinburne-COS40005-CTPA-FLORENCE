import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:florence/features/clinician/models/health_data.dart';
import 'package:florence/features/clinician/models/patient.dart';
import 'package:florence/features/clinician/theme/app_theme.dart';
import 'package:florence/features/clinician/widgets/bmi_chart.dart';
import 'package:intl/intl.dart';

class BmiAnalyticsScreen extends ConsumerStatefulWidget {
  final Patient patient;
  final List<BmiReading> readings;
  final double currentWeight;
  final double currentHeight;

  const BmiAnalyticsScreen({
    super.key,
    required this.patient,
    required this.readings,
    required this.currentWeight,
    required this.currentHeight,
  });

  @override
  ConsumerState<BmiAnalyticsScreen> createState() => _BmiAnalyticsScreenState();
}

class _BmiAnalyticsScreenState extends ConsumerState<BmiAnalyticsScreen> {
  int _currentPage = 0;
  final int _itemsPerPage = 5;
  String _selectedFilter = 'Daily';
  DateTime _focusedDate = DateTime.now();

  List<BmiReading> get _filteredReadings {
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

  List<BmiReading> get _filteredReadingsAsc {
    final list = List<BmiReading>.from(_filteredReadings);
    list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return list;
  }

  List<BmiReading> get _filteredReadingsDesc {
    final list = List<BmiReading>.from(_filteredReadings);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BMI Analytics'),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: AppTheme.dividerColor,
            height: 1.0,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              _buildFilterHeader(
                selectedFilter: _selectedFilter,
                focusedDate: _focusedDate,
                onFilterChanged: (filter) => setState(() => _selectedFilter = filter),
                onDateChanged: (date) => setState(() => _focusedDate = date),
              ),
              _buildTrendsSection(),
              const SizedBox(height: 16),
              _buildHistorySection(),
            ],
          ),
        ),
      ),
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
                    'BMI Trends',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 250,
                child: BmiChart(
                  readings: _filteredReadingsAsc,
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.circle, color: AppTheme.primaryColor, size: 10),
                  SizedBox(width: 4),
                  Text('BMI', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.history, color: AppTheme.textSecondary, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'History',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                    ],
                  ),
                  if (totalPages > 1)
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left, size: 20),
                          onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_currentPage + 1}/$totalPages',
                          style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.chevron_right, size: 20),
                          onPressed: _currentPage < totalPages - 1 ? () => setState(() => _currentPage++) : null,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          color: AppTheme.textSecondary,
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (pageItems.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('No historical data available.', style: TextStyle(color: AppTheme.textSecondary)),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: pageItems.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final r = pageItems[index];
                    final isHigh = r.value >= 25.0;
                    final isLow = r.value < 18.5;
                    final status = isHigh ? 'ABOVE TARGET' : (isLow ? 'BELOW TARGET' : 'NORMAL');
                    final color = isHigh ? AppTheme.mediumRiskColor : (isLow ? AppTheme.secondaryColor : AppTheme.lowRiskColor);

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
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                r.value.toStringAsFixed(1),
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'kg/m²',
                                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('dd/MM/yy HH:mm').format(r.timestamp),
                                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
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
