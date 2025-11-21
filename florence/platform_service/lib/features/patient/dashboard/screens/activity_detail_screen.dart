import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../../../../config/theme.dart';
import '../../core/models/health_data_models.dart';
import '../../dashboard/providers/dashboard_providers.dart';

class ActivityDetailScreen extends ConsumerWidget {
  const ActivityDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(activityLogsProvider);
    final monitorAsync = ref.watch(monitorDataProvider);

    // Data Color: Orange/Amber (Specific to Activity Data)
    const Color dataColor = Color(0xFFF59E0B);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Analytics'),
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
      body: activityAsync.when(
        data: (logs) {
          return monitorAsync.when(
            data: (monitorData) {
              // Sort logs: Newest first
              final sortedLogs = List<ActivityLog>.from(logs)
                ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

              // Filter glucose for impact analysis
              final glucoseReadings = monitorData
                  .where((d) => d.dataType == MonitorDataType.GLUCOSE)
                  .toList();

              return RefreshIndicator(
                onRefresh: () async {
                  await Future.wait([
                    ref.refresh(activityLogsProvider.future),
                    ref.refresh(monitorDataProvider.future),
                  ]);
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // 1. Daily Volume
                      _DailyVolumeCard(
                        logs: sortedLogs, 
                        dataColor: dataColor
                      ),
                      const SizedBox(height: 20),

                      // 2. Weekly Consistency
                      _WeeklyConsistencyChart(
                        logs: sortedLogs, 
                        dataColor: dataColor
                      ),
                      const SizedBox(height: 20),

                      // 3. Activity Timing
                      _ActivityTimingChart(
                        logs: sortedLogs, 
                        dataColor: dataColor
                      ),
                      const SizedBox(height: 20),

                      // 4. History List
                      _ActivityHistoryList(
                        logs: sortedLogs,
                        glucoseReadings: glucoseReadings,
                        dataColor: dataColor,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error loading health data: $err')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading activity: $err')),
      ),
    );
  }
}

// ============================================================================
// 1. DAILY VOLUME (Big Number)
// ============================================================================

class _DailyVolumeCard extends StatelessWidget {
  final List<ActivityLog> logs;
  final Color dataColor;

  const _DailyVolumeCard({required this.logs, required this.dataColor});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayLogs = logs.where((log) => 
      log.timestamp.year == now.year && 
      log.timestamp.month == now.month && 
      log.timestamp.day == now.day
    ).toList();
    
    final totalMinutes = todayLogs.fold(0, (sum, log) => sum + log.duration);
    final sessionCount = todayLogs.length;

    return _ActivityCard(
      title: 'Today\'s Movement',
      icon: Icons.timer,
      infoText: 'Total duration of physical activity recorded today.\n\n'
                'Consistent daily movement helps regulate blood pressure and glucose levels.',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            '$totalMinutes',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: dataColor,
              fontSize: 64,
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'minutes',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textSecondaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'across $sessionCount sessions',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondaryColor,
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
// 2. WEEKLY CONSISTENCY CHART
// ============================================================================

class _WeeklyConsistencyChart extends StatelessWidget {
  final List<ActivityLog> logs;
  final Color dataColor;

  const _WeeklyConsistencyChart({required this.logs, required this.dataColor});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final Map<int, int> dailyTotals = {};
    
    for (int i = 6; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      final dayKey = d.year * 10000 + d.month * 100 + d.day;
      dailyTotals[dayKey] = 0;
    }

    for (var log in logs) {
      final d = log.timestamp;
      final dayKey = d.year * 10000 + d.month * 100 + d.day;
      if (dailyTotals.containsKey(dayKey)) {
        dailyTotals[dayKey] = (dailyTotals[dayKey] ?? 0) + log.duration;
      }
    }

    final sortedKeys = dailyTotals.keys.toList()..sort();
    final maxMinutes = dailyTotals.values.isNotEmpty 
        ? dailyTotals.values.reduce(math.max).toDouble() 
        : 60.0;
    
    final maxY = maxMinutes > 0 ? (maxMinutes / 10).ceil() * 10.0 + 10 : 60.0;

    final barGroups = sortedKeys.asMap().entries.map((entry) {
      final index = entry.key;
      final minutes = dailyTotals[entry.value]!;
      
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: minutes.toDouble(),
            color: dataColor,
            width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: maxY,
              color: AppTheme.getBorderColor(context).withOpacity(0.2),
            ),
          ),
        ],
        showingTooltipIndicators: minutes > 0 ? [0] : [],
      );
    }).toList();

    return _ActivityCard(
      title: 'Weekly Consistency',
      icon: Icons.bar_chart,
      infoText: 'Total active minutes per day for the last 7 days.',
      child: SizedBox(
        height: 220,
        child: BarChart(
          BarChartData(
            maxY: maxY,
            gridData: FlGridData(show: false),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (val, meta) {
                    if (val < 0 || val >= 7) return const SizedBox();
                    final date = DateTime.now().subtract(Duration(days: 6 - val.toInt()));
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        DateFormat('E').format(date)[0],
                        style: TextStyle(
                          color: AppTheme.textSecondaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: barGroups,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => Colors.black87,
                tooltipMargin: 4,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    '${rod.toY.toInt()}m',
                    const TextStyle(
                      color: Colors.white,
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
    );
  }
}

// ============================================================================
// 3. ACTIVITY TIMING (Time of Day Analysis)
// ============================================================================

class _ActivityTimingChart extends StatelessWidget {
  final List<ActivityLog> logs;
  final Color dataColor;

  const _ActivityTimingChart({required this.logs, required this.dataColor});

  @override
  Widget build(BuildContext context) {
    // Filter last 30 days
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    final recentLogs = logs.where((l) => l.timestamp.isAfter(cutoff)).toList();

    double morning = 0; // 5-11
    double midday = 0;  // 11-17
    double evening = 0; // 17-22
    double night = 0;   // 22-5

    for (var log in recentLogs) {
      final h = log.timestamp.hour;
      if (h >= 5 && h < 11) morning += log.duration;
      else if (h >= 11 && h < 17) midday += log.duration;
      else if (h >= 17 && h < 22) evening += log.duration;
      else night += log.duration;
    }

    final total = morning + midday + evening + night;
    if (total == 0) {
      return _ActivityCard(
        title: 'Activity Timing',
        icon: Icons.schedule,
        infoText: 'When you are most active.',
        child: const Padding(
          padding: EdgeInsets.all(20), 
          child: Center(child: Text('No activity in the last 30 days'))
        ),
      );
    }

    final maxVal = [morning, midday, evening, night].reduce(math.max);
    final maxY = maxVal > 0 ? (maxVal / 10).ceil() * 10.0 + 10 : 60.0;

    final dataPoints = [
      _TimingPoint('Morning', morning, 0),
      _TimingPoint('Midday', midday, 1),
      _TimingPoint('Evening', evening, 2),
      _TimingPoint('Night', night, 3),
    ];

    return _ActivityCard(
      title: 'Activity Timing',
      icon: Icons.schedule,
      infoText: 'Distribution of your activity by time of day (Last 30 Days).\n\n'
                '• Morning: Great for setting daily glucose trend.\n'
                '• Evening: Helps lower post-dinner spikes.',
      child: SizedBox(
        height: 220,
        child: BarChart(
          BarChartData(
            maxY: maxY,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: maxY / 4,
              getDrawingHorizontalLine: (_) => FlLine(color: AppTheme.getBorderColor(context).withOpacity(0.1), strokeWidth: 1),
            ),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (val, meta) {
                    if (val < 0 || val >= 4) return const SizedBox();
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        dataPoints[val.toInt()].label,
                        style: TextStyle(
                          color: AppTheme.textSecondaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: dataPoints.map((point) {
              return BarChartGroupData(
                x: point.index,
                barRods: [
                  BarChartRodData(
                    toY: point.value,
                    color: dataColor,
                    width: 24,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: maxY,
                      color: AppTheme.getBorderColor(context).withOpacity(0.1),
                    ),
                  ),
                ],
              );
            }).toList(),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => Colors.black87,
                tooltipMargin: 4,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    '${rod.toY.toInt()}m',
                    const TextStyle(
                      color: Colors.white,
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
    );
  }
}

class _TimingPoint {
  final String label;
  final double value;
  final int index;
  _TimingPoint(this.label, this.value, this.index);
}

// ============================================================================
// 4. HISTORY & GLUCOSE IMPACT
// ============================================================================

class _ActivityHistoryList extends StatefulWidget {
  final List<ActivityLog> logs;
  final List<MonitorData> glucoseReadings;
  final Color dataColor;

  const _ActivityHistoryList({
    required this.logs,
    required this.glucoseReadings,
    required this.dataColor,
  });

  @override
  State<_ActivityHistoryList> createState() => _ActivityHistoryListState();
}

class _ActivityHistoryListState extends State<_ActivityHistoryList> {
  int _currentPage = 0;
  static const int _itemsPerPage = 5;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerColor = isDark ? AppTheme.midnightSurface : Colors.white;
    final borderColor = AppTheme.getBorderColor(context);

    final totalItems = widget.logs.length;
    final totalPages = (totalItems / _itemsPerPage).ceil();
    
    if (_currentPage >= totalPages && totalPages > 0) _currentPage = totalPages - 1;
    if (totalPages == 0) _currentPage = 0;
    
    final start = _currentPage * _itemsPerPage;
    final end = math.min(start + _itemsPerPage, totalItems);
    final currentItems = totalItems > 0 ? widget.logs.sublist(start, end) : <ActivityLog>[];

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.1), 
                      borderRadius: BorderRadius.circular(12)
                    ),
                    child: const Icon(Icons.history, color: AppTheme.primaryBlue, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text('History', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              if (totalPages > 1)
                Row(
                  children: [
                    IconButton(onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null, icon: const Icon(Icons.chevron_left)),
                    Text('${_currentPage + 1}/$totalPages', style: const TextStyle(fontWeight: FontWeight.bold)),
                    IconButton(onPressed: _currentPage < totalPages - 1 ? () => setState(() => _currentPage++) : null, icon: const Icon(Icons.chevron_right)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (currentItems.isEmpty)
            const Padding(padding: EdgeInsets.all(16), child: Text('No activity logs found'))
          else
            ...currentItems.map((log) => _buildLogItem(context, log)),
        ],
      ),
    );
  }

  Widget _buildLogItem(BuildContext context, ActivityLog log) {
    // CALCULATE GLUCOSE IMPACT
    double? startGlucose;
    double? endGlucose;
    final activityTime = log.timestamp;
    
    // 1. Start Reading: [Time - 60min] to [Time + 10min]
    final beforeReadings = widget.glucoseReadings.where((r) => 
      r.measuredAt.isBefore(activityTime.add(const Duration(minutes: 10))) && 
      r.measuredAt.isAfter(activityTime.subtract(const Duration(minutes: 60)))
    ).toList();
    
    if (beforeReadings.isNotEmpty) {
      beforeReadings.sort((a, b) => 
        (a.measuredAt.difference(activityTime).abs()).compareTo(b.measuredAt.difference(activityTime).abs())
      );
      startGlucose = beforeReadings.first.value;
    }

    // 2. End Reading: [Time + 30min] to [Time + 150min]
    final afterReadings = widget.glucoseReadings.where((r) => 
      r.measuredAt.isAfter(activityTime.add(const Duration(minutes: 30))) && 
      r.measuredAt.isBefore(activityTime.add(const Duration(minutes: 150)))
    ).toList();
    
    if (afterReadings.isNotEmpty) {
      afterReadings.sort((a, b) => a.measuredAt.compareTo(b.measuredAt)); 
      endGlucose = afterReadings.last.value;
    }

    double? impact;
    if (startGlucose != null && endGlucose != null) {
      impact = endGlucose - startGlucose; 
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.dataColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.dataColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.directions_run, color: widget.dataColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.type, // Raw Description
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  DateFormat('MMM d, h:mm a').format(log.timestamp),
                  style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${log.duration} min',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
              ),
              // Conditional Glucose Impact Badge
              if (impact != null)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (impact < 0 ? AppTheme.primaryGreen : AppTheme.errorColor).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        impact < 0 ? Icons.arrow_downward : Icons.arrow_upward,
                        size: 12,
                        color: impact < 0 ? AppTheme.primaryGreen : AppTheme.errorColor,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${impact.abs().toStringAsFixed(0)}',
                        style: TextStyle(
                          color: impact < 0 ? AppTheme.primaryGreen : AppTheme.errorColor,
                          fontSize: 11, 
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ],
                  ),
                )
              else if (startGlucose != null)
                 Padding(
                   padding: const EdgeInsets.only(top: 4),
                   child: Text(
                    'Start: ${startGlucose.toInt()}',
                    style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 10),
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
// HELPER WRAPPER
// ============================================================================

class _ActivityCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String infoText;
  final Widget child;

  // We ignore passing themeColor here to enforce Blue Headers (Consistency)
  // But we can use a default if needed.
  
  const _ActivityCard({
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
            // Info dialog also uses Primary Blue for consistency
            Icon(icon, color: AppTheme.primaryBlue),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))),
          ],
        ),
        content: Text(infoText, style: Theme.of(context).textTheme.bodyMedium),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Got it'))],
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
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                // Always use Primary Blue for the Header Icon to match other screens
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
