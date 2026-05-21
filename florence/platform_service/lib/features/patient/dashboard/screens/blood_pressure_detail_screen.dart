import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:florence/config/routes.dart';
import 'package:florence/config/theme.dart';
import 'package:florence/core/layout/responsive_layout_system.dart';
import 'package:florence/features/patient/core/models/health_data_models.dart';
import 'package:florence/features/patient/core/providers/monitor_data_providers.dart' as core_data;
import 'package:florence/features/patient/core/providers/threshold_providers.dart';
import 'package:florence/features/patient/dashboard/providers/dashboard_providers.dart';

class BloodPressureDetailScreen extends ConsumerWidget {
  final VoidCallback? onSwitchToLog;
  const BloodPressureDetailScreen({super.key, this.onSwitchToLog});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monitorAsync = ref.watch(monitorDataProvider);
    final thresholdsAsync = ref.watch(patientThresholdsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Blood Pressure Analytics'),
        elevation: 0,
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: IconButton(
              icon: const Icon(Icons.add),
              onPressed: onSwitchToLog ?? () => AppRoutes.pushReplacement(context, AppRoutes.logBloodPressure),
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
      body: monitorAsync.when(
        data: (dataList) {
          // 1. Pair Systolic and Diastolic readings based on timestamp
          final readings = _pairReadings(dataList);

          // Sort by date ascending for charts
          readings.sort((a, b) => a.timestamp.compareTo(b.timestamp));

          // Get Thresholds
          final thresholds = thresholdsAsync.value ?? [];
          
          // Check for user-defined thresholds
          PatientThreshold? userSys;
          PatientThreshold? userDia;
          try { userSys = thresholds.firstWhere((t) => t.dataType == 'BLOOD_PRESSURE_SYSTOLIC'); } catch (_) {}
          try { userDia = thresholds.firstWhere((t) => t.dataType == 'BLOOD_PRESSURE_DIASTOLIC'); } catch (_) {}

          final isDefault = userSys == null || userDia == null;

          // Ensure we only pass thresholds if they exist, no defaults
          final sysThreshold = userSys;
          final diaThreshold = userDia;

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
                                Expanded(
                                  child: Column(
                                    children: [
                                      _StatisticsSection(
                                        readings: readings,
                                        sysThreshold: sysThreshold,
                                        diaThreshold: diaThreshold,
                                        isDefault: isDefault,
                                      ),
                                      const SizedBox(height: 20),
                                      _DualTrendSection(
                                        readings: readings,
                                        sysThreshold: sysThreshold,
                                        diaThreshold: diaThreshold,
                                      ),
                                      const SizedBox(height: 20),
                                      _FloatingBarSection(readings: readings),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    children: [
                                      _ScatterSection(
                                        readings: readings,
                                        sysThreshold: sysThreshold,
                                        diaThreshold: diaThreshold,
                                      ),
                                      const SizedBox(height: 20),
                                      _HistorySection(
                                        readings: readings,
                                        sysThreshold: sysThreshold,
                                        diaThreshold: diaThreshold,
                                      ),
                                      const SizedBox(height: 24),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                _StatisticsSection(
                                  readings: readings,
                                  sysThreshold: sysThreshold,
                                  diaThreshold: diaThreshold,
                                  isDefault: isDefault,
                                ),
                                const SizedBox(height: 20),
                                _DualTrendSection(
                                  readings: readings,
                                  sysThreshold: sysThreshold,
                                  diaThreshold: diaThreshold,
                                ),
                                const SizedBox(height: 20),
                                _FloatingBarSection(readings: readings),
                                const SizedBox(height: 20),
                                _ScatterSection(
                                  readings: readings,
                                  sysThreshold: sysThreshold,
                                  diaThreshold: diaThreshold,
                                ),
                                const SizedBox(height: 20),
                                _HistorySection(
                                  readings: readings,
                                  sysThreshold: sysThreshold,
                                  diaThreshold: diaThreshold,
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
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  List<_BpReading> _pairReadings(List<MonitorData> data) {
    final Map<String, double> sysMap = {};
    final Map<String, double> diaMap = {};
    final Map<String, DateTime> timeMap = {};

    for (var d in data) {
      // Key by timestamp ISO string to pair readings logged together
      final key = d.measuredAt.toIso8601String(); 
      
      if (d.dataType == MonitorDataType.BLOOD_PRESSURE_SYSTOLIC) {
        sysMap[key] = d.value;
        timeMap[key] = d.measuredAt;
      } else if (d.dataType == MonitorDataType.BLOOD_PRESSURE_DIASTOLIC) {
        diaMap[key] = d.value;
        timeMap[key] = d.measuredAt;
      }
    }

    final List<_BpReading> paired = [];
    sysMap.forEach((key, sys) {
      if (diaMap.containsKey(key)) {
        paired.add(_BpReading(timeMap[key]!, sys, diaMap[key]!));
      }
    });

    return paired;
  }
}

class _BpReading {
  final DateTime timestamp;
  final double systolic;
  final double diastolic;
  _BpReading(this.timestamp, this.systolic, this.diastolic);
  
  double get pulsePressure => systolic - diastolic;
}

// ============================================================================
// REUSABLE WRAPPER
// ============================================================================

class _ChartSection extends StatefulWidget {
  final String title;
  final IconData icon;
  final String infoText;
  final Widget Function(String range, List<_BpReading> filteredData) builder;
  final List<_BpReading> allData;
  final List<String> ranges;

  const _ChartSection({
    required this.title,
    required this.icon,
    required this.infoText,
    required this.builder,
    required this.allData,
    this.ranges = const ['1D', '7D', '14D', '30D'],
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

  List<_BpReading> _filterData() {
    if (widget.allData.isEmpty) return [];
    final now = DateTime.now();
    DateTime cutoff;
    switch (_selectedRange) {
      case '7D':
        cutoff = now.subtract(const Duration(days: 7));
        break;
      case '14D':
        cutoff = now.subtract(const Duration(days: 14));
        break;
      case '30D':
        cutoff = now.subtract(const Duration(days: 30));
        break;
      case '1D':
      default:
        cutoff = DateTime(now.year, now.month, now.day);
        break;
    }
    return widget.allData.where((d) => d.timestamp.isAfter(cutoff)).toList();
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
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppTheme.primaryBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
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
            decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
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
      case '1D': return 'Daily';
      case '7D': return 'Weekly';
      case '14D': return 'Bi-Weekly';
      case '30D': return 'Monthly';
      default: return key;
    }
  }
}

// ============================================================================
// SECTIONS
// ============================================================================

class _StatisticsSection extends StatelessWidget {
  final List<_BpReading> readings;
  final PatientThreshold? sysThreshold;
  final PatientThreshold? diaThreshold;
  final bool isDefault;

  const _StatisticsSection({
    required this.readings, 
    this.sysThreshold, 
    this.diaThreshold,
    this.isDefault = false,
  });

  @override
  Widget build(BuildContext context) {
    return _ChartSection(
      title: 'Overview',
      icon: Icons.analytics_outlined,
      infoText: 'Key statistics for blood pressure.\n\n'
                '• Average: Mean systolic/diastolic levels.\n'
                '• Pulse Pressure: Difference between systolic and diastolic (Sys - Dia).\n'
                '• Target: Your configured safe range.',
      allData: readings,
      builder: (range, data) {
        double avgSys = 0, avgDia = 0, avgPulse = 0;
        if (data.isNotEmpty) {
          avgSys = data.map((e) => e.systolic).reduce((a, b) => a + b) / data.length;
          avgDia = data.map((e) => e.diastolic).reduce((a, b) => a + b) / data.length;
          avgPulse = data.map((e) => e.pulsePressure).reduce((a, b) => a + b) / data.length;
        }

        return Column(
          children: [
             // Target Range Display
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
                  border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
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
                              'Target Ranges',
                              style: TextStyle(color: AppTheme.primaryGreen.withValues(alpha: 0.8), fontWeight: FontWeight.w600),
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
                    if (sysThreshold != null && diaThreshold != null) ...[
                      const SizedBox(height: 12),
                      _buildMiniTargetRow('Systolic', '${sysThreshold!.minValue.toInt()} - ${sysThreshold!.maxValue.toInt()} mmHg', AppTheme.primaryGreen),
                      const SizedBox(height: 4),
                      _buildMiniTargetRow('Diastolic', '${diaThreshold!.minValue.toInt()} - ${diaThreshold!.maxValue.toInt()} mmHg', AppTheme.primaryGreen),
                    ] else ...[
                      const SizedBox(height: 12),
                      _buildMiniTargetRow('Systolic', 'Not Set', AppTheme.textSecondaryColor),
                      const SizedBox(height: 4),
                      _buildMiniTargetRow('Diastolic', 'Not Set', AppTheme.textSecondaryColor),
                    ],
                  ],
                ),
              ),
            ),
            // Stats Grid
            Row(
              children: [
                Expanded(child: _buildStatBox(context, 'Avg Systolic', avgSys > 0 ? avgSys.toStringAsFixed(0) : '--', 'mmHg', AppTheme.primaryRed)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatBox(context, 'Avg Diastolic', avgDia > 0 ? avgDia.toStringAsFixed(0) : '--', 'mmHg', AppTheme.primaryBlue)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatBox(context, 'Pulse Pressure', avgPulse > 0 ? avgPulse.toStringAsFixed(0) : '--', 'mmHg', AppTheme.textSecondaryColor)),
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
// SECTION 2: DUAL PRESSURE TRENDS (SCROLLABLE & PAGINATED)
// ============================================================================

class _DualTrendSection extends ConsumerStatefulWidget {
  final List<_BpReading> readings;
  final PatientThreshold? sysThreshold;
  final PatientThreshold? diaThreshold;

  const _DualTrendSection({required this.readings, this.sysThreshold, this.diaThreshold});

  @override
  ConsumerState<_DualTrendSection> createState() => _DualTrendSectionState();
}

class _DualTrendSectionState extends ConsumerState<_DualTrendSection> {
  final ScrollController _scrollController = ScrollController();
  
  bool _isLoadingMore = false;
  bool _hasMoreData = true; 
  int _previousDataCount = 0;
  int _dailyVisualLimit = 14; 
  bool _isPaginating = false; 

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAutoLoad());
  }

  @override
  void didUpdateWidget(covariant _DualTrendSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.readings.length > oldWidget.readings.length) {
      _hasMoreData = true;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAutoLoad());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _checkAutoLoad() {
    if (!mounted || !_scrollController.hasClients) return;
    if (_hasMoreData && _scrollController.position.maxScrollExtent < 50 && !_isLoadingMore) {
      _loadMoreData();
    }
  }

  Future<void> _loadMoreData() async {
    if (_isLoadingMore || !_hasMoreData) return;
    setState(() => _isLoadingMore = true);
    
    _previousDataCount = widget.readings.length;
    
    try {
      await ref.read(core_data.monitorDataProvider.notifier).fetchNextPage();
    } catch (e) {
      debugPrint('Error loading more data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
          if (widget.readings.length <= _previousDataCount) {
            _hasMoreData = false; 
          }
        });
        if (_hasMoreData) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _checkAutoLoad());
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ChartSection(
      title: 'Pressure Trends',
      icon: Icons.show_chart,
      infoText: 'Visualizes your blood pressure trends over time.\n\n'
                '• Y-Axis: Pressure (mmHg)\n'
                '• X-Axis: Time\n'
                '• Shaded Band: Readings within your target safe zone.',
      allData: widget.readings,
      builder: (range, _) { // We ignore the filtered data here to handle it dynamically below
        
        DateTime startOfWindow;
        DateTime endOfWindow;
        double interval;
        DateFormat dateFormat;

        final now = DateTime.now();

        // 1. Set End Padding and X-Axis Interval logic
        switch (range) {
          case '1D':
            endOfWindow = now.add(const Duration(hours: 6));
            interval = 3600000; // 1 hour
            dateFormat = DateFormat("h a");
            break;
          case '7D':
            endOfWindow = DateTime(now.year, now.month, now.day, 23, 59).add(const Duration(days: 1));
            interval = 86400000;
            dateFormat = DateFormat("d/M\nE");
            break;
          case '14D':
            endOfWindow = DateTime(now.year, now.month, now.day, 23, 59).add(const Duration(days: 2));
            interval = 86400000 * 2;
            dateFormat = DateFormat("d/M\nE");
            break;
          case '30D':
            endOfWindow = DateTime(now.year, now.month + 1, 15);
            interval = 86400000 * 7; 
            dateFormat = DateFormat('d/M');
            break;
          default:
            endOfWindow = now.add(const Duration(hours: 1));
            interval = 86400000;
            dateFormat = DateFormat('d/M');
        }

        // 2. Control Visual Canvas Rendering Limits
        int maxDaysToRender;
        switch (range) {
          case '1D': maxDaysToRender = _dailyVisualLimit; break;
          case '7D': maxDaysToRender = 90; break;
          case '14D': maxDaysToRender = 180; break;
          case '30D': maxDaysToRender = 730; break;
          default: maxDaysToRender = 30;
        }

        DateTime absoluteStart = endOfWindow.subtract(Duration(days: maxDaysToRender));

        if (widget.readings.isNotEmpty) {
          final firstDate = widget.readings.first.timestamp.toLocal();
          startOfWindow = DateTime(firstDate.year, firstDate.month, firstDate.day);
          if (startOfWindow.isBefore(absoluteStart)) {
            startOfWindow = absoluteStart;
          }
        } else {
          startOfWindow = endOfWindow.subtract(const Duration(days: 7));
        }

        final double minX = startOfWindow.millisecondsSinceEpoch.toDouble();
        final double maxX = endOfWindow.millisecondsSinceEpoch.toDouble();

        // 3. Filter spots strictly within the rendering limits
        final sysSpots = widget.readings
            .map((r) => FlSpot(r.timestamp.millisecondsSinceEpoch.toDouble(), r.systolic))
            .where((s) => s.x >= minX && s.x <= maxX)
            .toList();
            
        final diaSpots = widget.readings
            .map((r) => FlSpot(r.timestamp.millisecondsSinceEpoch.toDouble(), r.diastolic))
            .where((s) => s.x >= minX && s.x <= maxX)
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0, left: 4.0),
              child: Text(
                range == '1D' ? "Displaying exact readings. Swipe right to see past days." : "Displaying trends over time.",
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor, fontStyle: FontStyle.italic),
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                double chartWidth = constraints.maxWidth;

                if (widget.readings.isNotEmpty) {
                  final totalDays = math.max(1.0, (maxX - minX) / 86400000);

                  if (range == '1D') {
                    final pixelsPerDay = math.max(constraints.maxWidth, 1200.0);
                    chartWidth = math.max(constraints.maxWidth, totalDays * pixelsPerDay);
                  } else if (range == '7D') {
                    final pixelsPerDay = constraints.maxWidth / 7;
                    chartWidth = math.max(constraints.maxWidth, totalDays * pixelsPerDay);
                  } else if (range == '14D') {
                    final pixelsPerDay = constraints.maxWidth / 14;
                    chartWidth = math.max(constraints.maxWidth, totalDays * pixelsPerDay);
                  } else if (range == '30D') {
                    final pixelsPerMonth = constraints.maxWidth / 2;
                    final totalMonths = totalDays / 30.44;
                    chartWidth = math.max(constraints.maxWidth, totalMonths * pixelsPerMonth);
                  }
                }

                return NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification scrollInfo) {
                    if (scrollInfo is ScrollUpdateNotification) {
                      if (!_isPaginating && scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 300) {
                        
                        // Stop expanding if we've rendered the oldest point
                        if (!_hasMoreData && widget.readings.isNotEmpty) {
                          final oldestDataDate = widget.readings.first.timestamp;
                          final currentRenderLimit = DateTime.now().subtract(Duration(days: _dailyVisualLimit));
                          if (currentRenderLimit.isBefore(oldestDataDate)) return false;
                        }

                        setState(() {
                          _isPaginating = true;
                          if (range == '1D') _dailyVisualLimit += 14;
                        });

                        if (_hasMoreData) {
                          _loadMoreData().then((_) {
                            if (mounted) setState(() => _isPaginating = false);
                          });
                        } else {
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
                          minX: minX, maxX: maxX, minY: 40, maxY: 180,
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: true,
                            getDrawingHorizontalLine: (_) => FlLine(color: AppTheme.getBorderColor(context).withValues(alpha: 0.2), strokeWidth: 1),
                            getDrawingVerticalLine: (_) => FlLine(color: AppTheme.getBorderColor(context).withValues(alpha: 0.2), strokeWidth: 1),
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
                                    // Handle midnight format crossover
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
                                      style: TextStyle(fontSize: 10, color: AppTheme.textSecondaryColor, height: 1.3),
                                    ),
                                  );
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: true, border: Border.all(color: AppTheme.getBorderColor(context).withValues(alpha: 0.5))),
                          rangeAnnotations: RangeAnnotations(
                            horizontalRangeAnnotations: [
                              if (widget.sysThreshold != null)
                                HorizontalRangeAnnotation(y1: widget.sysThreshold!.minValue, y2: widget.sysThreshold!.maxValue, color: AppTheme.primaryRed.withValues(alpha: 0.05)),
                              if (widget.diaThreshold != null)
                                HorizontalRangeAnnotation(y1: widget.diaThreshold!.minValue, y2: widget.diaThreshold!.maxValue, color: AppTheme.primaryBlue.withValues(alpha: 0.05)),
                            ]
                          ),
                          extraLinesData: ExtraLinesData(
                            horizontalLines: [
                              if (widget.sysThreshold != null) ...[
                                HorizontalLine(y: widget.sysThreshold!.minValue, color: AppTheme.primaryRed.withValues(alpha: 0.5), strokeWidth: 1, dashArray: [4, 4]),
                                HorizontalLine(y: widget.sysThreshold!.maxValue, color: AppTheme.primaryRed.withValues(alpha: 0.5), strokeWidth: 1, dashArray: [4, 4]),
                              ],
                              if (widget.diaThreshold != null) ...[
                                HorizontalLine(y: widget.diaThreshold!.minValue, color: AppTheme.primaryBlue.withValues(alpha: 0.5), strokeWidth: 1, dashArray: [4, 4]),
                                HorizontalLine(y: widget.diaThreshold!.maxValue, color: AppTheme.primaryBlue.withValues(alpha: 0.5), strokeWidth: 1, dashArray: [4, 4]),
                              ],
                            ],
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: sysSpots,
                              color: AppTheme.primaryRed, barWidth: 2, isCurved: true,
                              dotData: FlDotData(show: true, getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: 3, color: AppTheme.primaryRed, strokeWidth: 1.5, strokeColor: Colors.white)),
                            ),
                            LineChartBarData(
                              spots: diaSpots,
                              color: AppTheme.primaryBlue, barWidth: 2, isCurved: true,
                              dotData: FlDotData(show: true, getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: 3, color: AppTheme.primaryBlue, strokeWidth: 1.5, strokeColor: Colors.white)),
                            ),
                          ],
                          lineTouchData: LineTouchData(
                            touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
                              // Safely swallows interrupted touch events during scrolling
                            },
                            getTouchedSpotIndicator: (barData, spotIndexes) {
                              return spotIndexes.map((index) {
                                return TouchedSpotIndicatorData(
                                  const FlLine(color: AppTheme.textSecondaryColor, strokeWidth: 0.5),
                                  FlDotData(show: true, getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(radius: 4, color: AppTheme.primaryBlue, strokeColor: Colors.white)),
                                );
                              }).toList();
                            },
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipColor: (touchedSpot) => Colors.black.withValues(alpha: 0.8),
                              getTooltipItems: (touchedSpots) {
                                return touchedSpots.map((spot) {
                                   final isSys = spot.barIndex == 0;
                                   // Rebuilt tooltips to safely rely on Spot coordinates rather than array indexing
                                   final date = DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
                                   return LineTooltipItem(
                                     '${DateFormat('MMM d, h:mm a').format(date)}\n',
                                     const TextStyle(color: Colors.white70, fontWeight: FontWeight.w500, fontSize: 10),
                                     children: [
                                       TextSpan(
                                         text: '${isSys ? "Sys" : "Dia"}: ${spot.y.toInt()} mmHg',
                                         style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                       ),
                                     ]
                                   );
                                }).toList();
                              }
                            )
                          )
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              runSpacing: 8,
              children: [
               const _LegendItem('Systolic', AppTheme.primaryRed, isCircle: true),
               const _LegendItem('Diastolic', AppTheme.primaryBlue, isCircle: true),
               const _LegendItem('Sys Limit', AppTheme.primaryRed, isBox: true),
               const _LegendItem('Dia Limit', AppTheme.primaryBlue, isBox: true),
            ]),
          ],
        );
      },
    );
  }
}

class _FloatingBarSection extends StatelessWidget {
  final List<_BpReading> readings;

  const _FloatingBarSection({required this.readings});

  @override
  Widget build(BuildContext context) {
    return _ChartSection(
      title: 'Daily Range (Pulse Pressure)',
      icon: Icons.bar_chart,
      infoText: 'Visualizes the gap between your systolic and diastolic numbers.\n\n'
                '• Y-Axis: Pressure (mmHg)\n'
                '• X-Axis: Time\n'
                '• Bar Height: Difference between Systolic and Diastolic.',
      allData: readings,
      builder: (range, data) {
        
        // 1. Generate appropriate Bar Groups based on the selected range
        List<BarChartGroupData> barGroups;
        
        if (range == '1D') {
          // Group daily readings into 24 fixed hourly buckets
          Map<int, List<_BpReading>> hourlyMap = {};
          for (var r in data) {
            int hr = r.timestamp.toLocal().hour;
            hourlyMap.putIfAbsent(hr, () => []).add(r);
          }
          
          barGroups = List.generate(25, (hour) {
            if (hourlyMap.containsKey(hour)) {
              // Average the readings if there are multiple in the same hour
              var list = hourlyMap[hour]!;
              double sys = list.map((e) => e.systolic).reduce((a, b) => a + b) / list.length;
              double dia = list.map((e) => e.diastolic).reduce((a, b) => a + b) / list.length;
              
              return BarChartGroupData(
                x: hour,
                barRods: [
                  BarChartRodData(
                    toY: sys,
                    fromY: dia,
                    color: AppTheme.primaryBlue.withValues(alpha: 0.6),
                    width: 12,
                    borderRadius: BorderRadius.circular(4),
                  )
                ],
              );
            } else {
              // Create an invisible placeholder bar to maintain the 24-hour spacing
              return BarChartGroupData(
                x: hour,
                barRods: [
                  BarChartRodData(toY: 0, fromY: 0, color: Colors.transparent, width: 12)
                ],
              );
            }
          });
        } else {
          // Default behavior for 7D, 14D, 30D (Show sequentially)
          barGroups = data.asMap().entries.map((entry) {
            final r = entry.value;
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: r.systolic,
                  fromY: r.diastolic,
                  color: AppTheme.primaryBlue.withValues(alpha: 0.6),
                  width: 12,
                  borderRadius: BorderRadius.circular(4),
                )
              ],
            );
          }).toList();
        }

        // 2. Define the Base Chart
        Widget chart = BarChart(
          BarChartData(
            alignment: range == '1D' ? BarChartAlignment.spaceAround : BarChartAlignment.spaceAround,
            maxY: 200, minY: 40,
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: range == '1D' ? 1 : (data.isNotEmpty ? data.length / 6 : 1),
                  reservedSize: 30,
                  getTitlesWidget: (v, meta) {
                    // Hourly Labels for Daily View
                    if (range == '1D') {
                      if (v <= 0 || v >= 24) return const SizedBox(); 
                      int hour = v.toInt();
                      String ampm = hour >= 12 ? 'PM' : 'AM';
                      int displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
                      
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          '$displayHour $ampm', 
                          style: TextStyle(fontSize: 10, color: AppTheme.textSecondaryColor)
                        )
                      );
                    }

                    // Standard Date Labels for >1D Views
                    if (v.toInt() >= data.length || v.toInt() < 0) return const SizedBox();
                    final int index = v.toInt();
                    final int total = data.length;
                    bool shouldSkip = false;

                    switch (range) {
                      case '30D':
                        if (total > 15) shouldSkip = index % 5 != 0;
                        else if (total > 8) shouldSkip = index % 3 != 0;
                        break;
                      default: // 7D, 14D
                        if (total > 10) shouldSkip = index % 2 != 0;
                        break;
                    }

                    if (index == 0 || index == total - 1) shouldSkip = false;
                    if (shouldSkip) return const SizedBox();

                    final date = data[index].timestamp.toLocal();
                    return Padding(
                      padding: const EdgeInsets.only(top: 8), 
                      child: Text(DateFormat('d/M').format(date), style: const TextStyle(fontSize: 10))
                    );
                  }
                ),
              ),
            ),
            gridData: FlGridData(
              show: true, 
              drawVerticalLine: false, 
              getDrawingHorizontalLine: (_) => FlLine(color: AppTheme.getBorderColor(context).withValues(alpha: 0.2), strokeWidth: 1)
            ),
            borderData: FlBorderData(
              show: true, 
              border: Border.all(color: AppTheme.getBorderColor(context).withValues(alpha: 0.5))
            ),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (group) => Colors.black.withValues(alpha: 0.8),
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  // Prevent tooltips from showing on the invisible placeholder bars
                  if (rod.toY == 0 && rod.fromY == 0) return null;

                  if (range == '1D') {
                    final pulse = (rod.toY - (rod.fromY ?? 0)).toInt();
                    return BarTooltipItem(
                      '${rod.toY.toInt()}/${rod.fromY?.toInt() ?? 0}',
                      const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      children: [TextSpan(text: '\nPulse: $pulse', style: const TextStyle(fontSize: 10, color: Colors.white70))],
                    );
                  } else {
                    final r = data[group.x.toInt()];
                    return BarTooltipItem(
                      '${r.systolic.toInt()}/${r.diastolic.toInt()}',
                      const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      children: [TextSpan(text: '\nPulse: ${r.pulsePressure.toInt()}', style: const TextStyle(fontSize: 10, color: Colors.white70))],
                    );
                  }
                }
              )
            ),
            barGroups: barGroups,
          ),
        );

        // 3. Render Chart (Wrapped in ScrollView if Daily)
        return Column(
          children: [
            if (range == '1D')
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Text(
                  "Scroll horizontally to view all 24 hours.",
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor, fontStyle: FontStyle.italic),
                ),
              ),
            LayoutBuilder(
              builder: (context, constraints) {
                if (range == '1D') {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    reverse: true, // Auto-aligns the scroll view to the right (most recent part of the day)
                    physics: const BouncingScrollPhysics(),
                    child: SizedBox(
                      width: math.max(constraints.maxWidth, 1200), // 50px per hour minimum
                      height: 250,
                      child: chart,
                    ),
                  );
                }
                return SizedBox(height: 250, child: chart);
              }
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const _LegendItem('Systolic (Top Bound)', AppTheme.primaryBlue, isBox: true),
                const SizedBox(width: 16),
                const _LegendItem('Diastolic (Bottom Bound)', AppTheme.primaryBlue, isBox: true),
              ],
            )
          ],
        );
      },
    );
  }
}

class _ScatterSection extends StatelessWidget {
  final List<_BpReading> readings;
  final PatientThreshold? sysThreshold;
  final PatientThreshold? diaThreshold;

  const _ScatterSection({required this.readings, this.sysThreshold, this.diaThreshold});

  @override
  Widget build(BuildContext context) {
    return _ChartSection(
      title: 'Systolic vs. Diastolic',
      icon: Icons.bubble_chart_outlined,
      infoText: 'Correlates your Systolic vs Diastolic pressure.\n\n'
                '• Y-Axis: Systolic (mmHg)\n'
                '• X-Axis: Diastolic (mmHg)\n'
                '• Color: Green (In Range), Red (Out of Range).',
      allData: readings,
      builder: (range, data) {
        return Column(
          children: [
            SizedBox(
              height: 250,
              child: ScatterChart(
                ScatterChartData(
                  scatterSpots: data.map((r) {
                    Color dotColor;
                    if (sysThreshold != null && diaThreshold != null) {
                      if (r.systolic > sysThreshold!.maxValue || r.diastolic > diaThreshold!.maxValue) {
                        dotColor = AppTheme.errorColor;
                      } else if (r.systolic < sysThreshold!.minValue || r.diastolic < diaThreshold!.minValue) {
                        dotColor = AppTheme.warningColor;
                      } else {
                        dotColor = AppTheme.primaryGreen;
                      }
                    } else {
                      dotColor = AppTheme.primaryBlue;
                    }
                    
                    return ScatterSpot(
                      r.diastolic, 
                      r.systolic,
                      dotPainter: FlDotCirclePainter(
                        color: dotColor,
                        radius: 4,
                        strokeWidth: 0,
                      ),
                    );
                  }).toList(),
                  minX: 40, maxX: 130,
                  minY: 80, maxY: 200,
                  gridData: FlGridData(show: true, getDrawingHorizontalLine: (_) => FlLine(color: AppTheme.getBorderColor(context).withValues(alpha: 0.2), strokeWidth: 1), getDrawingVerticalLine: (_) => FlLine(color: AppTheme.getBorderColor(context).withValues(alpha: 0.2), strokeWidth: 1)),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 20, getTitlesWidget: (value, meta) {
                      if (value <= meta.min || value >= meta.max) return const SizedBox();
                      return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10));
                    })),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true, border: Border.all(color: AppTheme.getBorderColor(context).withValues(alpha: 0.5))),
                  scatterTouchData: ScatterTouchData(
                    touchTooltipData: ScatterTouchTooltipData(
                      getTooltipColor: (spot) => Colors.black.withValues(alpha: 0.8),
                      getTooltipItems: (spot) {
                        return ScatterTooltipItem(
                          'Sys: ${spot.y.toInt()}\nDia: ${spot.x.toInt()}',
                          textStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        );
                      }
                    )
                  )
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
               if (sysThreshold != null && diaThreshold != null) ...[
                 const _LegendItem('Low', AppTheme.warningColor, isCircle: true),
                 const SizedBox(width: 16),
                 const _LegendItem('Normal', AppTheme.primaryGreen, isCircle: true),
                 const SizedBox(width: 16),
                 const _LegendItem('Elevated', AppTheme.errorColor, isCircle: true),
               ] else
                 const _LegendItem('Recorded', AppTheme.primaryBlue, isCircle: true),
            ]),
          ],
        );
      },
    );
  }
}

class _HistorySection extends StatefulWidget {
  final List<_BpReading> readings;
  final PatientThreshold? sysThreshold;
  final PatientThreshold? diaThreshold;

  const _HistorySection({
    required this.readings,
    this.sysThreshold,
    this.diaThreshold,
  });

  @override
  State<_HistorySection> createState() => _HistorySectionState();
}

class _HistorySectionState extends State<_HistorySection> {
  int _currentPage = 0;
  static const int _itemsPerPage = 5;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reversed = widget.readings.reversed.toList();

    final totalItems = reversed.length;
    final totalPages = (totalItems / _itemsPerPage).ceil();
    if (_currentPage >= totalPages && totalPages > 0) _currentPage = totalPages - 1;
    
    final start = _currentPage * _itemsPerPage;
    final end = math.min(start + _itemsPerPage, totalItems);
    final currentItems = reversed.sublist(start, end);

    // Manually build container to allow Paginator in header (same layout as GlucoseDetailScreen)
    final containerColor = isDark ? AppTheme.midnightSurface : Colors.white;
    final borderColor = AppTheme.getBorderColor(context);

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
          // Header Row with Paginator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppTheme.primaryBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.history, color: AppTheme.primaryBlue, size: 24)
                  ),
                  const SizedBox(width: 12),
                  Text('History', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              // Pagination Controls (Top Right)
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
            ),
            
          ...currentItems.map((r) {
             // Dynamic Status Logic using Thresholds
             String status;
             Color statusColor;
             
             if (widget.sysThreshold != null && widget.diaThreshold != null) {
               final sysMax = widget.sysThreshold!.maxValue;
               final diaMax = widget.diaThreshold!.maxValue;

               if (r.systolic > sysMax || r.diastolic > diaMax) {
                 status = 'ELEVATED';
                 statusColor = AppTheme.errorColor;
               } else if (r.systolic < widget.sysThreshold!.minValue || r.diastolic < widget.diaThreshold!.minValue) {
                 status = 'LOW';
                 statusColor = AppTheme.warningColor;
               } else {
                 status = 'NORMAL';
                 statusColor = AppTheme.primaryGreen;
               }
             } else {
               status = 'RECORDED';
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
                         '${r.systolic.toInt()}/${r.diastolic.toInt()}',
                         style: TextStyle(
                           fontWeight: FontWeight.normal,
                           fontSize: 20, // Reduced font size
                           color: AppTheme.textPrimaryColor,
                         ),
                       ),
                       const SizedBox(width: 4),
                       Text(
                         'mmHg',
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
                           color: statusColor.withValues(alpha: 0.1),
                           borderRadius: BorderRadius.circular(8),
                         ),
                         child: Text(
                           status,
                           style: TextStyle(
                             color: statusColor,
                             fontSize: 10,
                             fontWeight: FontWeight.bold,
                           ),
                         ),
                       ),
                       const SizedBox(height: 6),
                       Text(
                         DateFormat('dd/MM/yy HH:mm').format(r.timestamp.toLocal()),
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
