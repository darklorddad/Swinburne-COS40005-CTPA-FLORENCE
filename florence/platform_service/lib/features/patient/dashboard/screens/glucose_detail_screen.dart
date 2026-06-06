import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:florence/config/routes.dart';
import 'package:florence/config/theme.dart';
import 'package:florence/core/layout/responsive_layout_system.dart';
import 'package:florence/features/patient/core/models/health_data_models.dart';
import 'package:florence/features/patient/core/providers/monitor_data_providers.dart' as core_data;
import 'package:florence/features/patient/core/providers/settings_providers.dart';
import 'package:florence/features/patient/core/providers/threshold_providers.dart';
import 'package:florence/features/patient/dashboard/providers/dashboard_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class GlucoseDetailScreen extends ConsumerWidget {
  final VoidCallback? onSwitchToLog;
  const GlucoseDetailScreen({super.key, this.onSwitchToLog});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glucoseAsync = ref.watch(monitorDataProvider);
    final thresholdsAsync = ref.watch(patientThresholdsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Glucose Analytics'),
        elevation: 0,
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: IconButton(
              icon: const Icon(Icons.add),
              onPressed: onSwitchToLog ?? () => AppRoutes.pushReplacement(context, AppRoutes.logGlucose),
              tooltip: 'Add Log',
            ),
          ),
        ],
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
          // 1. Global Data Prep
          final allReadings = dataList
              .where((d) => d.dataType == MonitorDataType.GLUCOSE)
              .toList();

          // Sort ascending for charts logic
          allReadings.sort((a, b) => a.measuredAt.compareTo(b.measuredAt));

          final glucoseReadingsWithContext = ref.watch(core_data.glucoseReadingsProvider);

          final thresholds = thresholdsAsync.value ?? [];
          
          PatientThreshold? userThreshold;
          try {
            userThreshold = thresholds.firstWhere((t) => t.dataType == 'GLUCOSE');
          } catch (_) {}

          final isDefault = userThreshold == null;
          final effectiveThreshold = userThreshold;

          return RefreshIndicator(
            onRefresh: () async {
              return ref.refresh(core_data.monitorDataProvider.future);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: context.isDesktop
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left Column
                                Expanded(
                                  child: Column(
                                    children: [
                                      _StatisticsSection(
                                        readings: allReadings,
                                        threshold: effectiveThreshold,
                                        isDefault: isDefault,
                                      ),
                                      const SizedBox(height: 20),
                                      _GlucoseTrendsSection(
                                        allReadings: allReadings,
                                        threshold: effectiveThreshold,
                                        isDefault: isDefault,
                                      ),
                                      const SizedBox(height: 20),
                                      _TimeInRangeSection(
                                        readings: allReadings,
                                        threshold: effectiveThreshold,
                                        isDefault: isDefault,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 20),
                                // Right Column
                                Expanded(
                                  child: Column(
                                    children: [
                                      _ModalDaySection(
                                        allReadings: allReadings,
                                        threshold: effectiveThreshold,
                                        isDefault: isDefault,
                                      ),
                                      const SizedBox(height: 20),
                                      _HistorySection(
                                        readings: glucoseReadingsWithContext,
                                        threshold: effectiveThreshold,
                                      ),
                                      const SizedBox(height: 24),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _StatisticsSection(
                                  readings: allReadings,
                                  threshold: effectiveThreshold,
                                  isDefault: isDefault,
                                ),
                                const SizedBox(height: 20),
                                _GlucoseTrendsSection(
                                  allReadings: allReadings,
                                  threshold: effectiveThreshold,
                                  isDefault: isDefault,
                                ),
                                const SizedBox(height: 20),
                                _TimeInRangeSection(
                                  readings: allReadings,
                                  threshold: effectiveThreshold,
                                  isDefault: isDefault,
                                ),
                                const SizedBox(height: 20),
                                _ModalDaySection(
                                  allReadings: allReadings,
                                  threshold: effectiveThreshold,
                                  isDefault: isDefault,
                                ),
                                const SizedBox(height: 20),
                                _HistorySection(
                                  readings: glucoseReadingsWithContext,
                                  threshold: effectiveThreshold,
                                ),
                                const SizedBox(height: 24),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading glucose: $err')),
      ),
    );
  }
}

/// Reusable Wrapper with Styled Info
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
    this.ranges = const ['1D', '7D', '14D', '1Y'],
  });

  @override
  State<_ChartSection> createState() => _ChartSectionState();
}

class _ChartSectionState extends State<_ChartSection> {
  late String _selectedRange;

  @override
  void initState() {
    super.initState();
    _selectedRange = widget.ranges.contains('7D') ? '7D' : widget.ranges.first;
    if (widget.ranges.contains('1D')) _selectedRange = '1D';
  }

  List<MonitorData> _filterData() {
    if (widget.allData.isEmpty) return [];
    final now = DateTime.now();
    
    if (_selectedRange == '1D') {
      final startOfDay = DateTime(now.year, now.month, now.day);
      return widget.allData.where((d) => d.measuredAt.isAfter(startOfDay)).toList();
    }

    Duration duration;
    switch (_selectedRange) {
      case '7D': duration = const Duration(days: 7); break;
      case '14D': duration = const Duration(days: 14); break;
      case '1Y': duration = const Duration(days: 365); break;
      default: duration = const Duration(days: 7); break;
    }
    final cutoff = now.subtract(duration);
    return widget.allData.where((d) => d.measuredAt.isAfter(cutoff)).toList();
  }

  String _getRangeLabel(String key) {
    switch (key) {
      case '1D': return 'Daily';
      case '7D': return 'Weekly';
      case '14D': return 'Bi-Weekly';
      case '1Y': return 'Yearly';
      default: return key;
    }
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
    final filteredData = _filterData();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.icon, color: AppTheme.primaryBlue, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: Icon(Icons.info_outline, color: AppTheme.textSecondaryColor, size: 20),
                onPressed: () => _showInfoDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 36,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: widget.ranges.map((range) {
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
                          fontSize: 11, 
                          fontWeight: FontWeight.w600,
                          color: isSelected 
                            ? Colors.white 
                            : Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
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
}

// ============================================================================
// SECTION 1: STATISTICS SUMMARY
// ============================================================================

class _StatisticsSection extends ConsumerWidget {
  final List<MonitorData> readings;
  final PatientThreshold? threshold;
  final bool isDefault;

  const _StatisticsSection({
    required this.readings,
    this.threshold,
    this.isDefault = false,
  });

  Map<String, dynamic> _calculateStats(List<MonitorData> data) {
    if (data.isEmpty) return {'avg': 0.0, 'gmi': 0.0, 'cv': 0.0};
    final values = data.map((e) => e.value).toList();
    final avg = values.reduce((a, b) => a + b) / values.length;
    final variance = values.map((v) => math.pow(v - avg, 2)).reduce((a, b) => a + b) / values.length;
    final stdDev = math.sqrt(variance);
    final cv = (stdDev / avg) * 100;
    final gmi = 3.31 + (0.02392 * avg);
    return {'avg': avg, 'gmi': gmi, 'cv': cv};
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _ChartSection(
      title: 'Overview',
      icon: Icons.analytics_outlined,
      infoText: 'Key statistics derived from your glucose readings.\n\n'
                '• Average: Mean glucose level.\n'
                '• GMI: Glucose Management Indicator (Estimated A1c).\n'
                '• CV: Coefficient of Variation. Target < 36% for stable control.\n'
                '• Target: Your configured safe range.',
      allData: readings,
      builder: (range, data) {
        final stats = _calculateStats(data);
        final settings = ref.watch(patientSettingsProvider);
        return Column(
          children: [
            InkWell(
              onTap: () => Navigator.of(context).pushNamed('/profile'),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.3),
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
                                color: AppTheme.primaryGreen.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: AppTheme.primaryGreen.withValues(alpha: 0.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (threshold != null)
                      _buildMiniTargetRow(
                        'Glucose',
                        '${threshold!.minValue.toDouble()} - ${threshold!.maxValue.toDouble()} ${settings.glucoseUnit}',
                        AppTheme.primaryGreen,
                      )
                    else
                      _buildMiniTargetRow(
                        'Glucose',
                        'Not Set',
                        AppTheme.textSecondaryColor,
                      ),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                Expanded(child: _buildStatBox(context, 'Average', (stats['avg'] as double) > 0 ? (stats['avg'] as double).toStringAsFixed(0) : '--', settings.glucoseUnit, Colors.blue)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatBox(context, 'GMI', (stats['gmi'] as double) > 0 ? (stats['gmi'] as double).toStringAsFixed(1) : '--', '%', Colors.purple)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatBox(context, 'Variability', (stats['cv'] as double) > 0 ? (stats['cv'] as double).toStringAsFixed(1) : '--', '%', threshold != null ? ((stats['cv'] as double) < 36 ? AppTheme.successColor : AppTheme.warningColor) : AppTheme.textSecondaryColor)),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildMiniTargetRow(String label, String val, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.8))),
        Text(val, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildStatBox(BuildContext context, String title, String value, String unit, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(width: 2),
              Text(unit, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SECTION 2: ANNOTATED GLUCOSE TRENDS (SCROLLABLE & PAGINATED)
// ============================================================================

class _GlucoseTrendsSection extends ConsumerStatefulWidget {
  final List<MonitorData> allReadings;
  final PatientThreshold? threshold;
  final bool isDefault;

  const _GlucoseTrendsSection({
    required this.allReadings,
    this.threshold,
    this.isDefault = false,
  });

  @override
  ConsumerState<_GlucoseTrendsSection> createState() => _GlucoseTrendsSectionState();
}

class _GlucoseTrendsSectionState extends ConsumerState<_GlucoseTrendsSection> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  bool _hasMoreData = true; // Track if we hit the end of the database
  int _previousDataCount = 0;

  // NEW: Controls how wide the canvas is allowed to be
  int _dailyVisualLimit = 14;
  // NEW: Prevents rapid-fire canvas expansion while scrolling
  bool _isPaginating = false;

  @override
  void initState() {
    super.initState();
    // Check if we need to auto-load immediately after the widget builds
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAutoLoad());
  }

  @override
  void didUpdateWidget(covariant _GlucoseTrendsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the data array grew, we successfully loaded more.
    if (widget.allReadings.length > oldWidget.allReadings.length) {
      _hasMoreData = true;
    }
    // If the user switches tabs (Daily -> Yearly), check again if we need to auto-load
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAutoLoad());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _checkAutoLoad() {
    if (!mounted || !_scrollController.hasClients) return;
    
    // Only auto-load if we aren't loading AND we haven't hit the end of the data
    if (_hasMoreData && _scrollController.position.maxScrollExtent < 50 && !_isLoadingMore) {
      _loadMoreData();
    }
  }

  Future<void> _loadMoreData() async {
    if (_isLoadingMore || !_hasMoreData) return;
    setState(() => _isLoadingMore = true);
    
    _previousDataCount = widget.allReadings.length;
    
    try {
      await ref.read(core_data.monitorDataProvider.notifier).fetchNextPage();
    } catch (e) {
      debugPrint('Error loading more data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
          // If the length didn't change after the fetch, we reached the end of the DB
          if (widget.allReadings.length <= _previousDataCount) {
            _hasMoreData = false; 
          }
        });
        
        // Check if we need to load again only if we actually got new data
        if (_hasMoreData) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _checkAutoLoad());
        }
      }
    }
  }

  List<FlSpot> _getAggregatedSpots(List<MonitorData> data, String range) {
    if (data.isEmpty) return [];

    if (range == '1D') {
      return data.map((d) => FlSpot(d.measuredAt.millisecondsSinceEpoch.toDouble(), d.value)).toList();
    }

    final Map<DateTime, List<double>> groupedData = {};

    for (var d in data) {
      final local = d.measuredAt.toLocal();
      DateTime groupKey;

      if (range == '1Y') {
        groupKey = DateTime(local.year, local.month, 15, 12);
      } else {
        groupKey = DateTime(local.year, local.month, local.day, 12);
      }

      groupedData.putIfAbsent(groupKey, () => []).add(d.value);
    }

    final List<FlSpot> spots = [];
    groupedData.forEach((date, values) {
      final average = values.reduce((a, b) => a + b) / values.length;
      spots.add(FlSpot(date.millisecondsSinceEpoch.toDouble(), average));
    });

    spots.sort((a, b) => a.x.compareTo(b.x));
    return spots;
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(patientSettingsProvider);
    return _ChartSection(
      title: 'Glucose Trends',
      icon: Icons.show_chart,
      infoText: 'Visualizes your glucose readings over time.\n\n'
          '• Y-Axis: Glucose (${settings.glucoseUnit})\n'
          '• X-Axis: Time\n'
          '• Green Band: Readings within your target safe zone.',
      allData: widget.allReadings,
      builder: (range, data) {
        DateTime startOfWindow;
        DateTime endOfWindow;
        double interval;
        DateFormat dateFormat;

        final now = DateTime.now();

        // 1. Adjust endOfWindow to create a proportional gap ahead of the current time
        switch (range) {
          case '1D':
            // Exact readings: Add a 6-hour gap ahead
            endOfWindow = now.add(const Duration(hours: 6));
            break;
          case '7D':
            // Aggregated points sit at 12 PM. Pushing to tomorrow night gives ~1.5 days gap
            endOfWindow = DateTime(now.year, now.month, now.day, 23, 59).add(const Duration(days: 1));
            break;
          case '14D':
            // Pushing 2.5 days ahead for Bi-Weekly
            endOfWindow = DateTime(now.year, now.month, now.day, 23, 59).add(const Duration(days: 2));
            break;
          case '1Y':
            // Aggregated points sit on the 15th. Pushing to the 15th of next month gives a 1-month gap
            endOfWindow = DateTime(now.year, now.month + 1, 15);
            break;
          default:
            endOfWindow = now.add(const Duration(hours: 1));
        }

        // 2. Define a maximum number of days we render in the scroll view to prevent GPU lag
        int maxDaysToRender;
        switch (range) {
          case '1D': maxDaysToRender = _dailyVisualLimit; break;  // Dynamic expansion
          case '7D': maxDaysToRender = 90; break;  // Max ~13 screens wide
          case '14D': maxDaysToRender = 180; break; // Max ~13 screens wide
          case '1Y': maxDaysToRender = 730; break; // Max 2 years
          default: maxDaysToRender = 30;
        }

        DateTime absoluteStart = endOfWindow.subtract(Duration(days: maxDaysToRender));

        if (widget.allReadings.isNotEmpty) {
          final firstDate = widget.allReadings.first.measuredAt.toLocal();
          startOfWindow = DateTime(firstDate.year, firstDate.month, firstDate.day);
          
          // 2. Clamp the start date to our maximum lookback limit
          if (startOfWindow.isBefore(absoluteStart)) {
            startOfWindow = absoluteStart;
          }
        } else {
          startOfWindow = endOfWindow.subtract(const Duration(days: 7));
        }

        switch (range) {
          case '1D':
            interval = 3600000; // 1 hour
            dateFormat = DateFormat("h a"); 
            break;
          case '7D':
            interval = 86400000; // 1 day
            dateFormat = DateFormat("d/M\nE"); // e.g. 15/5 \n Fri
            break;
          case '14D':
            interval = 86400000 * 2; // 2 days
            dateFormat = DateFormat("d/M\nE");
            break;
          case '1Y':
            interval = 86400000 * 30.44; // ~1 month
            dateFormat = DateFormat('MMM yy'); // e.g. Jan 26
            break;
          default:
            interval = 86400000;
            dateFormat = DateFormat('d/M');
        }

        final double minX = startOfWindow.millisecondsSinceEpoch.toDouble();
        final double maxX = endOfWindow.millisecondsSinceEpoch.toDouble();

        final bool isMmol = settings.glucoseUnit == 'mmol/L';
        final double padBottom = isMmol ? 1.0 : 20.0;
        final double padTop = isMmol ? 3.0 : 40.0;
        final double defaultMin = isMmol ? 2.0 : 60.0;
        final double defaultMax = isMmol ? 15.0 : 200.0;
        final double dataPad = isMmol ? 1.0 : 10.0;
        final double snapInterval = isMmol ? 2.0 : 50.0;

        // 3. Filter spots to strictly those within our calculated minX and maxX
        final chartSpots = _getAggregatedSpots(widget.allReadings, range)
            .where((spot) => spot.x >= minX && spot.x <= maxX)
            .toList();

        double minY = widget.threshold != null
            ? (widget.threshold!.minValue - padBottom).clamp(0, double.infinity)
            : defaultMin;
        double maxY = widget.threshold != null ? widget.threshold!.maxValue + padTop : defaultMax;

        if (chartSpots.isNotEmpty) {
          double dataMin = chartSpots.map((e) => e.y).reduce(math.min);
          double dataMax = chartSpots.map((e) => e.y).reduce(math.max);

          minY = math.min(minY, (dataMin - dataPad).clamp(0, double.infinity));
          maxY = math.max(maxY, dataMax + dataPad);
        }

        minY = (minY / snapInterval).floor() * snapInterval;
        maxY = (maxY / snapInterval).ceil() * snapInterval;
        if (maxY == minY) maxY += snapInterval;

        String viewDescription = "";
        if (range == '1D') {
          viewDescription = "Displaying exact readings. Swipe right to see past days.";
        } else if (range == '7D') {
          viewDescription = "Displaying daily averages. One screen equals 7 days.";
        } else if (range == '14D') {
          viewDescription = "Displaying daily averages. One screen equals 14 days.";
        } else if (range == '1Y') {
          viewDescription = "Displaying monthly averages. One screen equals 6 months.";
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0, left: 4.0),
              child: Text(
                viewDescription,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondaryColor,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                double chartWidth = constraints.maxWidth;

                if (widget.allReadings.isNotEmpty) {
                  final totalDays = math.max(1.0, (maxX - minX) / 86400000);

                  if (range == '1D') {
                    // Give it 1200 pixels per day to fit 24 hourly labels perfectly
                    final pixelsPerDay = math.max(constraints.maxWidth, 1200.0);
                    chartWidth = math.max(constraints.maxWidth, totalDays * pixelsPerDay);
                  } else if (range == '7D') {
                    final pixelsPerDay = constraints.maxWidth / 7;
                    chartWidth = math.max(constraints.maxWidth, totalDays * pixelsPerDay);
                  } else if (range == '14D') {
                    final pixelsPerDay = constraints.maxWidth / 14;
                    chartWidth = math.max(constraints.maxWidth, totalDays * pixelsPerDay);
                  } else if (range == '1Y') {
                    final pixelsPerMonth = constraints.maxWidth / 6;
                    final totalMonths = totalDays / 30.44;
                    chartWidth = math.max(constraints.maxWidth, totalMonths * pixelsPerMonth);
                  }
                }

                // THE FIX FOR 'DAILY': Using NotificationListener is much more reliable 
                // for catching swipes before they hit the absolute edge.
                return NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification scrollInfo) {
                    if (scrollInfo is ScrollUpdateNotification) {
                      if (!_isPaginating && scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 300) {
                        
                        // 1. If we have fetched ALL data from the DB, check if the visual 
                        // canvas already covers the oldest reading. If it does, stop expanding.
                        if (!_hasMoreData && widget.allReadings.isNotEmpty) {
                          final oldestDataDate = widget.allReadings.first.measuredAt;
                          final currentRenderLimit = DateTime.now().subtract(Duration(days: _dailyVisualLimit));
                          
                          if (currentRenderLimit.isBefore(oldestDataDate)) {
                            return false; // Stop paginating, we've shown everything
                          }
                        }

                        // 2. Lock the pagination and expand the canvas by 14 days
                        setState(() {
                          _isPaginating = true;
                          if (range == '1D') _dailyVisualLimit += 14;
                        });

                        // 3. Fetch more data from the database if there is more to get
                        if (_hasMoreData) {
                          _loadMoreData().then((_) {
                            if (mounted) setState(() => _isPaginating = false);
                          });
                        } else {
                          // If no DB fetch is needed, just wait for the canvas to resize, then unlock
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) setState(() => _isPaginating = false);
                          });
                        }
                      }
                    }
                    return false; 
                  },
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    physics: const BouncingScrollPhysics(),
                    child: SizedBox(
                      width: chartWidth,
                      height: 250,
                      child: LineChart(
                        LineChartData(
                          clipData: const FlClipData.all(),
                          minX: minX,
                          maxX: maxX,
                          minY: minY,
                          maxY: maxY,
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: true,
                            getDrawingHorizontalLine: (_) => FlLine(
                                color: AppTheme.getBorderColor(context).withValues(alpha: 0.2),
                                strokeWidth: 1),
                            getDrawingVerticalLine: (_) => FlLine(
                                color: AppTheme.getBorderColor(context).withValues(alpha: 0.2),
                                strokeWidth: 1),
                          ),
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: range == '1D' ? 60 : 42,
                                interval: interval,
                                getTitlesWidget: (val, meta) {
                                  if (val <= meta.min || val >= meta.max) {
                                    return const SizedBox.shrink();
                                  }
                                  final date = DateTime.fromMillisecondsSinceEpoch(val.toInt());
                                  
                                  String labelText;
                                  if (range == '1D') {
                                    // If it's midnight, show the Date & Day. Otherwise, just the Hour.
                                    if (date.hour == 0) {
                                      labelText = DateFormat("12 AM\nd/M\nEEE").format(date);
                                    } else {
                                      labelText = DateFormat("h a").format(date);
                                    }
                                  } else {
                                    labelText = dateFormat.format(date);
                                  }

                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      labelText,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppTheme.textSecondaryColor,
                                        height: 1.3,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(
                              show: true,
                              border: Border.all(
                                  color: AppTheme.getBorderColor(context).withValues(alpha: 0.5))),
                          rangeAnnotations: widget.threshold != null
                              ? RangeAnnotations(
                                  horizontalRangeAnnotations: [
                                    HorizontalRangeAnnotation(
                                        y1: widget.threshold!.minValue,
                                        y2: widget.threshold!.maxValue,
                                        color: AppTheme.primaryGreen.withValues(alpha: 0.1))
                                  ],
                                )
                              : null,
                          extraLinesData: widget.threshold != null
                              ? ExtraLinesData(
                                  horizontalLines: [
                                    HorizontalLine(
                                        y: widget.threshold!.minValue,
                                        color: AppTheme.primaryGreen.withValues(alpha: 0.8),
                                        strokeWidth: 1,
                                        dashArray: [4, 4]),
                                    HorizontalLine(
                                        y: widget.threshold!.maxValue,
                                        color: AppTheme.primaryGreen.withValues(alpha: 0.8),
                                        strokeWidth: 1,
                                        dashArray: [4, 4]),
                                  ],
                                )
                              : null,
                          lineBarsData: [
                            LineChartBarData(
                              spots: chartSpots,
                              isCurved: true, 
                              color: AppTheme.primaryBlue,
                              barWidth: range == '1D' ? 1.5 : 2,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (spot, percent, barData, index) =>
                                    FlDotCirclePainter(
                                  radius: 3,
                                  color: AppTheme.primaryBlue,
                                  strokeWidth: 1.5,
                                  strokeColor: Colors.white,
                                ),
                              ),
                              belowBarData: BarAreaData(
                                  show: true,
                                  gradient: LinearGradient(
                                      colors: [
                                        AppTheme.primaryBlue.withValues(alpha: 0.1),
                                        AppTheme.primaryBlue.withValues(alpha: 0)
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter)),
                            ),
                          ],
                          lineTouchData: LineTouchData(
                            touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
                              // Safely swallows interrupted touch events during scrolling
                            },
                            getTouchedSpotIndicator: (barData, spotIndexes) {
                              return spotIndexes.map((index) {
                                return TouchedSpotIndicatorData(
                                  const FlLine(color: AppTheme.textSecondaryColor, strokeWidth: 1),
                                  FlDotData(
                                      show: true,
                                      getDotPainter: (spot, percent, bar, index) =>
                                          FlDotCirclePainter(
                                              radius: 4,
                                              color: AppTheme.primaryBlue,
                                              strokeColor: Colors.white)),
                                );
                              }).toList();
                            },
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipColor: (touchedSpot) =>
                                  Colors.black.withValues(alpha: 0.8),
                              fitInsideHorizontally: true,
                              fitInsideVertically: true,
                              getTooltipItems: (touchedSpots) {
                                return touchedSpots.map((spot) {
                                  final date = DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
                                  final isAggregated = range != '1D';

                                  return LineTooltipItem(
                                    '${DateFormat('MMM d, y').format(date)}\n',
                                    const TextStyle(
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 10,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: isAggregated
                                            ? 'Daily Average\n'
                                            : '${DateFormat('h:mm a').format(date)}\n',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 10,
                                        ),
                                      ),
                                      TextSpan(
                                        text: isMmol
                                            ? '${spot.y.toStringAsFixed(1)} ${settings.glucoseUnit}'
                                            : '${spot.y.toInt()} ${settings.glucoseUnit}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          height: 1.5,
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList();
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            if (widget.threshold != null) ...[
              const SizedBox(height: 16),
              Center(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    const _LegendItem('Target Range', AppTheme.primaryGreen, isBox: true),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

// ============================================================================
// SECTION 3: TIME IN RANGE
// ============================================================================

class _TimeInRangeSection extends StatelessWidget {
  final List<MonitorData> readings;
  final PatientThreshold? threshold;
  final bool isDefault;

  const _TimeInRangeSection({
    required this.readings,
    this.threshold,
    this.isDefault = false,
  });

  @override
  Widget build(BuildContext context) {
    return _ChartSection(
      title: 'Time in Range',
      icon: Icons.track_changes_outlined,
      infoText: 'Percentage of time your glucose is within target.\n\n'
                'Goal: Keep "In Range" (Green) above 70%.',
      allData: readings,
      builder: (range, data) {
        if (threshold == null) {
          return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('Set target to view time in range.')));
        }

        final total = data.length;
        final lows = data.where((r) => r.value < threshold!.minValue).length;
        final highs = data.where((r) => r.value > threshold!.maxValue).length;
        final inRange = total - lows - highs;
        
        final lowPct = total > 0 ? (lows / total) * 100 : 0.0;
        final highPct = total > 0 ? (highs / total) * 100 : 0.0;
        final inPct = total > 0 ? (inRange / total) * 100 : 0.0;

        return Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 36,
                child: total == 0 
                  ? Container(color: Colors.grey.shade200) 
                  : Row(
                      children: [
                        if (lowPct > 0) Expanded(flex: (lowPct * 10).toInt(), child: Container(color: AppTheme.errorColor)),
                        if (inPct > 0) Expanded(flex: (inPct * 10).toInt(), child: Container(color: AppTheme.primaryGreen)),
                        if (highPct > 0) Expanded(flex: (highPct * 10).toInt(), child: Container(color: AppTheme.errorColor)),
                      ],
                    ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTIRLegend(context, 'Low', lowPct, AppTheme.errorColor),
                _buildTIRLegend(context, 'In Range', inPct, AppTheme.primaryGreen, isBig: true),
                _buildTIRLegend(context, 'High', highPct, AppTheme.errorColor),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildTIRLegend(BuildContext context, String label, double val, Color color, {bool isBig = false}) {
    return Column(
      children: [
        Text(
          '${val.toStringAsFixed(0)}%',
          style: TextStyle(fontSize: isBig ? 20 : 16, fontWeight: FontWeight.bold, color: color),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

// ============================================================================
// SECTION 4: MODAL DAY (SCROLLABLE & 1-HOUR INTERVALS)
// ============================================================================

class _ModalDaySection extends StatefulWidget {
  final List<MonitorData> allReadings;
  final PatientThreshold? threshold;
  final bool isDefault;

  const _ModalDaySection({
    required this.allReadings, 
    this.threshold,
    this.isDefault = false,
  });

  @override
  State<_ModalDaySection> createState() => _ModalDaySectionState();
}

class _ModalDaySectionState extends State<_ModalDaySection> {
  final ScrollController _scrollController = ScrollController();
  final double _chartWidth = 1200.0; // 1200px total / 24 hours = 50px per hour

  @override
  void initState() {
    super.initState();
    // Automatically scroll to 8 AM after the widget builds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        // 50 pixels per hour * 8 hours = 400 pixels
        // This places 8:00 AM near the left edge of the screen
        _scrollController.jumpTo(400.0);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ChartSection(
      title: 'Daily Patterns',
      icon: Icons.auto_graph_outlined,
      infoText: 'Overlays multiple days onto a single 24h axis to spot recurring patterns.\n\n'
                '• Y-Axis: Glucose\n'
                '• X-Axis: Hour of day (0-24)\n'
                '• Green Band: Readings within your target safe zone.',
      allData: widget.allReadings,
      builder: (range, data) {
        // 1. Gather Scatter Spots
        final List<FlSpot> scatterSpots = data.map((r) {
          final localDate = r.measuredAt.toLocal();
          final x = localDate.hour + (localDate.minute / 60.0);
          return FlSpot(x, r.value);
        }).toList();

        // THE FIX: LineChart strictly requires X values to be sorted ascending!
        scatterSpots.sort((a, b) => a.x.compareTo(b.x));

        // THE FIX: Dynamic Y-bounds so low/high values are never pushed off screen
        double calcMinY = widget.threshold?.minValue ?? 40.0;
        double calcMaxY = widget.threshold?.maxValue ?? 250.0;

        if (data.isNotEmpty) {
          final dataMin = data.map((e) => e.value).reduce(math.min);
          final dataMax = data.map((e) => e.value).reduce(math.max);
          calcMinY = math.min(calcMinY, dataMin);
          calcMaxY = math.max(calcMaxY, dataMax);
        }

        // Add 10 points of padding so dots don't touch the top/bottom borders
        final double finalMinY = math.max(0.0, calcMinY - 10.0);
        final double finalMaxY = calcMaxY + 10.0;

        // 2. Adjust Opacity based on data density
        double dotOpacity;
        switch (range) {
          case '1Y': dotOpacity = 0.15; break;
          case '14D': dotOpacity = 0.4; break;
          case '7D': dotOpacity = 0.6; break;
          default: dotOpacity = 0.8;
        }

        List<LineChartBarData> chartLines = [
          LineChartBarData(
            spots: scatterSpots,
            isCurved: false,
            color: Colors.transparent, // Keeps the lines invisible
            barWidth: 0,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                radius: 3.5, 
                color: AppTheme.textSecondaryColor.withValues(alpha: dotOpacity),
                strokeWidth: 0,
              ),
            ),
          )
        ];

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Text(
                "Scroll horizontally to view all 24 hours.",
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondaryColor,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            // 3. Wrap in a horizontal scroll view with a LayoutBuilder
            LayoutBuilder(
              builder: (context, constraints) {
                // Use the larger of the screen width or 1200 pixels
                final double finalWidth = math.max(constraints.maxWidth, _chartWidth);

                return SingleChildScrollView(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: SizedBox(
                    width: finalWidth,
                    height: 250,
                    child: LineChart(
                      LineChartData(
                        minX: 0,
                        maxX: 24,
                        minY: finalMinY,
                        maxY: finalMaxY,
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: true,
                          horizontalInterval: 50,
                          verticalInterval: 1, // Draw a grid line for every hour
                          getDrawingHorizontalLine: (_) => FlLine(color: AppTheme.getBorderColor(context).withValues(alpha: 0.2), strokeWidth: 1),
                          getDrawingVerticalLine: (_) => FlLine(color: AppTheme.getBorderColor(context).withValues(alpha: 0.2), strokeWidth: 1),
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true, 
                              interval: 1, // Label every 1 hour
                              reservedSize: 30,
                              getTitlesWidget: (v, _) {
                                if (v <= 0 || v >= 24) return const SizedBox(); // Hide 0 and 24 to prevent edge clipping
                                
                                int hour = v.toInt();
                                String ampm = hour >= 12 ? 'PM' : 'AM';
                                int displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    '$displayHour $ampm', 
                                    style: TextStyle(
                                      fontSize: 10, 
                                      color: AppTheme.textSecondaryColor,
                                      fontWeight: FontWeight.w500
                                    )
                                  ),
                                );
                              }
                            ),
                          ),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: true, border: Border.all(color: AppTheme.getBorderColor(context).withValues(alpha: 0.5))),
                        rangeAnnotations: widget.threshold != null ? RangeAnnotations(
                          horizontalRangeAnnotations: [HorizontalRangeAnnotation(y1: widget.threshold!.minValue, y2: widget.threshold!.maxValue, color: AppTheme.primaryGreen.withValues(alpha: 0.1))],
                        ) : null,
                        extraLinesData: widget.threshold != null ? ExtraLinesData(
                          horizontalLines: [
                            HorizontalLine(y: widget.threshold!.minValue, color: AppTheme.primaryGreen.withValues(alpha: 0.8), strokeWidth: 1, dashArray: [4, 4]),
                            HorizontalLine(y: widget.threshold!.maxValue, color: AppTheme.primaryGreen.withValues(alpha: 0.8), strokeWidth: 1, dashArray: [4, 4]),
                          ],
                        ) : null,
                        lineBarsData: chartLines,
                        lineTouchData: const LineTouchData(enabled: false), 
                      ),
                    ),
                  ),
                );
              }
            ),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (widget.threshold != null) ...[
                const _LegendItem('Target Range', AppTheme.primaryGreen, isBox: true),
                const SizedBox(width: 12),
              ],
              const _LegendItem('Reading Density', AppTheme.textSecondaryColor, isCircle: true),
            ]),
          ],
        );
      },
    );
  }
}

// ============================================================================
// SECTION 5: HISTORY
// ============================================================================

class _HistorySection extends ConsumerStatefulWidget {
  final List<GlucoseReading> readings;
  final PatientThreshold? threshold;

  const _HistorySection({required this.readings, this.threshold});

  @override
  ConsumerState<_HistorySection> createState() => _HistorySectionState();
}

class _HistorySectionState extends ConsumerState<_HistorySection> {
  int _currentPage = 0;
  static const int _itemsPerPage = 5;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerColor = isDark ? AppTheme.midnightSurface : Colors.white;
    final borderColor = AppTheme.getBorderColor(context);

    final sortedReadings = widget.readings.reversed.toList();

    final totalItems = sortedReadings.length;
    final totalPages = (totalItems / _itemsPerPage).ceil();
    if (_currentPage >= totalPages && totalPages > 0) _currentPage = totalPages - 1;
    
    final start = _currentPage * _itemsPerPage;
    final end = math.min(start + _itemsPerPage, totalItems);
    final currentItems = sortedReadings.sublist(start, end);

    final t = widget.threshold;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppTheme.primaryBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.history, color: AppTheme.primaryBlue, size: 24)),
                  const SizedBox(width: 12),
                  Text('History', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '${_currentPage + 1}/${totalPages > 0 ? totalPages : 1}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    onPressed: _currentPage < totalPages - 1 ? () => setState(() => _currentPage++) : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (currentItems.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No history available',
                  style: TextStyle(color: AppTheme.textSecondaryColor),
                ),
              ),
            )
          else
            ...currentItems.map((item) {
            String statusText;
            Color statusColor;
            
            if (t != null) {
              if (item.value < t.minValue) {
                statusText = 'LOW';
                statusColor = AppTheme.errorColor;
              } else if (item.value > t.maxValue) {
                statusText = 'HIGH';
                statusColor = AppTheme.errorColor;
              } else {
                statusText = 'NORMAL';
                statusColor = AppTheme.primaryGreen;
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
                    color: Colors.black.withValues(alpha: 0.03), 
                    blurRadius: 8, 
                    offset: const Offset(0, 2)
                  )
                ],
                border: Border.all(
                  color: statusColor.withValues(alpha: 0.3), 
                  width: 1
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            item.value.toStringAsFixed(ref.watch(patientSettingsProvider).glucoseUnit == 'mmol/L' ? 1 : 0),
                            style: TextStyle(
                              fontWeight: FontWeight.bold, 
                              fontSize: 22,
                              color: AppTheme.textPrimaryColor
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            ref.watch(patientSettingsProvider).glucoseUnit, 
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondaryColor,
                              fontSize: 12
                            )
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.context,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryBlue,
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
                          color: statusColor.withValues(alpha: 0.1), 
                          borderRadius: BorderRadius.circular(8)
                        ),
                        child: Text(
                          statusText, 
                          style: TextStyle(
                            color: statusColor, 
                            fontSize: 10, 
                            fontWeight: FontWeight.bold
                          )
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        DateFormat('dd/MM/yy HH:mm').format(item.timestamp.toLocal()), 
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: AppTheme.textSecondaryColor
                        )
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

// --- GLOBAL HELPERS ---

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;
  final bool isBox;
  final bool isCircle;
  final bool isDashed;

  const _LegendItem(this.label, this.color, {this.isBox = false, this.isCircle = false, this.isDashed = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isBox)
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)))
        else if (isCircle)
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle))
        else if (isDashed)
          SizedBox(width: 16, height: 2, child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Container(width: 4, height: 2, color: color), Container(width: 4, height: 2, color: color), Container(width: 4, height: 2, color: color)]))
        else
          Container(width: 12, height: 2, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}
