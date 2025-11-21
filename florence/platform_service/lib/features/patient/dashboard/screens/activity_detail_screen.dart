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
    // We need Activity logs AND Monitor data (for Glucose Impact calculation)
    final activityAsync = ref.watch(activityLogsProvider);
    final monitorAsync = ref.watch(monitorDataProvider);

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
              // Sort logs by date descending
              final sortedLogs = List<ActivityLog>.from(logs)
                ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

              // Filter glucose readings for impact analysis
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
                      // 1. Progress Ring (Active Minutes Today)
                      _ActiveMinutesRing(logs: sortedLogs),
                      const SizedBox(height: 20),

                      // 2. Weekly Bar Chart (Consistency)
                      _WeeklyConsistencyChart(logs: sortedLogs),
                      const SizedBox(height: 20),

                      // 3. Type Breakdown (Cardio vs Resistance inference)
                      _TypeBreakdownChart(logs: sortedLogs),
                      const SizedBox(height: 20),

                      // 4. History List with Glucose Impact
                      _ActivityHistoryList(
                        logs: sortedLogs,
                        glucoseReadings: glucoseReadings,
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
// 1. ACTIVE MINUTES RING
// ============================================================================

class _ActiveMinutesRing extends StatelessWidget {
  final List<ActivityLog> logs;
  static const int dailyGoal = 30; // 30 minutes goal

  const _ActiveMinutesRing({required this.logs});

  @override
  Widget build(BuildContext context) {
    // Calculate today's total
    final now = DateTime.now();
    final todayLogs = logs.where((log) => 
      log.timestamp.year == now.year && 
      log.timestamp.month == now.month && 
      log.timestamp.day == now.day
    ).toList();
    
    final totalMinutes = todayLogs.fold(0, (sum, log) => sum + log.duration);
    final progress = (totalMinutes / dailyGoal).clamp(0.0, 1.0);
    final isGoalMet = totalMinutes >= dailyGoal;

    return _ActivityCard(
      title: 'Active Minutes (Today)',
      icon: Icons.timer,
      infoText: 'Your daily movement goal.\n\n'
                '• Target: $dailyGoal minutes/day\n'
                '• Clinical Goal: 150 mins/week to improve insulin sensitivity.',
      child: Center(
        child: SizedBox(
          height: 200,
          width: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background Ring
              SizedBox(
                height: 180,
                width: 180,
                child: CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: 15,
                  color: AppTheme.getBorderColor(context).withOpacity(0.5),
                ),
              ),
              // Value Ring
              SizedBox(
                height: 180,
                width: 180,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 15,
                  color: isGoalMet ? AppTheme.primaryGreen : AppTheme.activityColor,
                  strokeCap: StrokeCap.round,
                ),
              ),
              // Center Text
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$totalMinutes',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  Text(
                    '/ $dailyGoal min',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (isGoalMet)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Icon(Icons.star, color: AppTheme.primaryGreen, size: 24),
                    )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 2. WEEKLY CONSISTENCY CHART
// ============================================================================

class _WeeklyConsistencyChart extends StatelessWidget {
  final List<ActivityLog> logs;

  const _WeeklyConsistencyChart({required this.logs});

  @override
  Widget build(BuildContext context) {
    // Group last 7 days
    final now = DateTime.now();
    final Map<int, int> dailyTotals = {};
    
    // Initialize last 7 days with 0
    for (int i = 6; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      final dayKey = d.year * 10000 + d.month * 100 + d.day; // YYYYMMDD
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
    final barGroups = sortedKeys.asMap().entries.map((entry) {
      final index = entry.key;
      final minutes = dailyTotals[entry.value]!;
      // Color logic: Green if >= 30 mins, Blue if > 0, Grey if 0
      final barColor = minutes >= 30 
          ? AppTheme.primaryGreen 
          : (minutes > 0 ? AppTheme.activityColor : Colors.grey.withOpacity(0.3));

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: minutes.toDouble(),
            color: barColor,
            width: 16,
            borderRadius: BorderRadius.circular(4),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: 60, // Max scale reference (1 hour)
              color: AppTheme.getBorderColor(context).withOpacity(0.2),
            ),
          ),
        ],
      );
    }).toList();

    return _ActivityCard(
      title: 'Weekly Consistency',
      icon: Icons.bar_chart,
      infoText: 'Your activity duration over the last 7 days.\n\n'
                '• Green: Goal met (30+ mins)\n'
                '• Orange: Some activity\n'
                '• Grey: No logged activity',
      child: SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            maxY: 70, // Just above 60 mins
            gridData: FlGridData(show: false),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (val, meta) {
                    if (val < 0 || val >= 7) return const SizedBox();
                    final date = DateTime.now().subtract(Duration(days: 6 - val.toInt()));
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        DateFormat('E').format(date)[0], // First letter of day
                        style: TextStyle(
                          color: AppTheme.textSecondaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: barGroups,
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 3. TYPE BREAKDOWN (Inferred from Description)
// ============================================================================

class _TypeBreakdownChart extends StatelessWidget {
  final List<ActivityLog> logs;

  const _TypeBreakdownChart({required this.logs});

  @override
  Widget build(BuildContext context) {
    // Filter last 30 days
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    final recentLogs = logs.where((l) => l.timestamp.isAfter(cutoff)).toList();

    double cardioMins = 0;
    double resistanceMins = 0;
    double otherMins = 0;

    // Keyword matching logic since 'type' isn't distinct in DB, usually in 'activity_description'
    for (var log in recentLogs) {
      // Note: using 'type' property from model which maps to 'activity_description' in DB
      final desc = log.type.toLowerCase(); 
      
      if (desc.contains('walk') || desc.contains('run') || desc.contains('cycl') || 
          desc.contains('swim') || desc.contains('jog') || desc.contains('dance') || 
          desc.contains('hike') || desc.contains('treadmill')) {
        cardioMins += log.duration;
      } else if (desc.contains('weight') || desc.contains('gym') || desc.contains('yoga') || 
                 desc.contains('pilates') || desc.contains('strength') || desc.contains('lift')) {
        resistanceMins += log.duration;
      } else {
        otherMins += log.duration;
      }
    }

    final total = cardioMins + resistanceMins + otherMins;
    
    if (total == 0) {
      return _ActivityCard(
        title: 'Workout Balance',
        icon: Icons.pie_chart,
        infoText: 'Breakdown of Cardio vs Resistance training.',
        child: const Padding(
          padding: EdgeInsets.all(20), 
          child: Center(child: Text('No activity in the last 30 days'))
        ),
      );
    }

    return _ActivityCard(
      title: 'Workout Balance',
      icon: Icons.pie_chart,
      infoText: 'Distribution of your activity types (Last 30 Days).\n\n'
                '• Cardio: Lowers glucose immediately.\n'
                '• Resistance: Builds muscle for long-term metabolic health.',
      child: Row(
        children: [
          SizedBox(
            height: 140,
            width: 140,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 30,
                sections: [
                  if (cardioMins > 0) PieChartSectionData(color: AppTheme.primaryBlue, value: cardioMins, radius: 40, showTitle: false),
                  if (resistanceMins > 0) PieChartSectionData(color: AppTheme.activityColor, value: resistanceMins, radius: 40, showTitle: false),
                  if (otherMins > 0) PieChartSectionData(color: Colors.grey, value: otherMins, radius: 40, showTitle: false),
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (cardioMins > 0) _buildLegendItem('Cardio', '${((cardioMins/total)*100).toStringAsFixed(0)}%', AppTheme.primaryBlue),
                if (cardioMins > 0) const SizedBox(height: 8),
                if (resistanceMins > 0) _buildLegendItem('Resistance', '${((resistanceMins/total)*100).toStringAsFixed(0)}%', AppTheme.activityColor),
                if (resistanceMins > 0) const SizedBox(height: 8),
                if (otherMins > 0) _buildLegendItem('Other', '${((otherMins/total)*100).toStringAsFixed(0)}%', Colors.grey),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, String percent, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
        Text(percent, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// ============================================================================
// 4. HISTORY & IMPACT CARD
// ============================================================================

class _ActivityHistoryList extends StatefulWidget {
  final List<ActivityLog> logs;
  final List<MonitorData> glucoseReadings;

  const _ActivityHistoryList({
    required this.logs,
    required this.glucoseReadings,
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
        color: isDark ? AppTheme.midnightSurface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.getBorderColor(context)),
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
                    decoration: BoxDecoration(color: AppTheme.activityColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.history, color: AppTheme.activityColor, size: 24),
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
    // 1. Find reading closest to start time (within 1 hour before)
    // 2. Find reading closest to end time + 2 hours
    
    double? startGlucose;
    double? endGlucose;
    
    final activityTime = log.timestamp;
    
    // Look for reading in [Time - 60min, Time]
    final beforeReadings = widget.glucoseReadings.where((r) => 
      r.measuredAt.isBefore(activityTime) && 
      r.measuredAt.isAfter(activityTime.subtract(const Duration(minutes: 60)))
    ).toList();
    if (beforeReadings.isNotEmpty) {
      beforeReadings.sort((a, b) => b.measuredAt.compareTo(a.measuredAt)); // Closest to start
      startGlucose = beforeReadings.first.value;
    }

    // Look for reading in [Time, Time + 120min]
    final afterReadings = widget.glucoseReadings.where((r) => 
      r.measuredAt.isAfter(activityTime) && 
      r.measuredAt.isBefore(activityTime.add(const Duration(minutes: 120)))
    ).toList();
    if (afterReadings.isNotEmpty) {
      afterReadings.sort((a, b) => b.measuredAt.compareTo(a.measuredAt)); // Latest in window
      endGlucose = afterReadings.first.value;
    }

    double? impact;
    if (startGlucose != null && endGlucose != null) {
      impact = endGlucose - startGlucose; // Negative means drop (good)
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.activityColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.activityColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.directions_run, color: AppTheme.activityColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.type,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
              if (impact != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      impact < 0 ? Icons.arrow_downward : Icons.arrow_upward,
                      size: 12,
                      color: impact < 0 ? AppTheme.primaryGreen : AppTheme.errorColor,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${impact.abs().toStringAsFixed(0)} mg/dL',
                      style: TextStyle(
                        color: impact < 0 ? AppTheme.primaryGreen : AppTheme.errorColor,
                        fontSize: 12, 
                        fontWeight: FontWeight.w600
                      ),
                    ),
                  ],
                )
              else
                Text(
                  '-- mg/dL',
                  style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 10),
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

  const _ActivityCard({required this.title, required this.icon, required this.infoText, required this.child});

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(icon, color: AppTheme.activityColor),
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.midnightSurface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.getBorderColor(context)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppTheme.activityColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: AppTheme.activityColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))),
              IconButton(onPressed: () => _showInfoDialog(context), icon: Icon(Icons.info_outline, color: AppTheme.textSecondaryColor)),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}
