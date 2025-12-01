import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../config/theme.dart';
import '../../core/models/health_data_models.dart';
import '../../core/providers/monitor_data_providers.dart' as core_data;
import '../../dashboard/providers/dashboard_providers.dart';

/// Diet Analytics Screen (formerly MealImpactScreen)
class DietAnalyticsScreen extends ConsumerWidget {
  const DietAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(dailyPatientLogsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diet Analytics'),
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
      body: logsAsync.when(
        data: (logs) {
          // Sort logs descending by date, then by meal time priority
          final sortedLogs = List<DailyPatientLog>.from(logs)
            ..sort((a, b) {
              final dateComp = b.logDate.compareTo(a.logDate);
              if (dateComp != 0) return dateComp;
              return _getMealTimePriority(b.mealTime).compareTo(_getMealTimePriority(a.mealTime));
            });

          return RefreshIndicator(
            onRefresh: () async {
              return ref.refresh(core_data.monitorDataProvider.future);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // 1. Statistics
                  _DietStatsSection(logs: sortedLogs),
                  const SizedBox(height: 20),

                  // 2. Traffic Light Calendar (New Section)
                  _TrafficLightCalendar(logs: sortedLogs),
                  const SizedBox(height: 20),

                  // 3. Impact Chart
                  _DietImpactChart(logs: sortedLogs),
                  const SizedBox(height: 20),

                  // 4. History List
                  _DietHistoryList(logs: sortedLogs),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading diet data: $err')),
      ),
    );
  }

  int _getMealTimePriority(String time) {
    switch (time.toUpperCase()) {
      case 'BREAKFAST': return 1;
      case 'LUNCH': return 2;
      case 'DINNER': return 3;
      default: return 0;
    }
  }
}

// ============================================================================
// 1. DIET STATISTICS
// ============================================================================

class _DietStatsSection extends StatelessWidget {
  final List<DailyPatientLog> logs;

  const _DietStatsSection({required this.logs});

  @override
  Widget build(BuildContext context) {
    // 1. Total logs
    final total = logs.length;

    // 2. Avg Spike
    double totalSpike = 0;
    int spikeCount = 0;
    for (var log in logs) {
      if (log.glucoseBeforeMeal != null && log.glucoseAfterMeal != null) {
        totalSpike += (log.glucoseAfterMeal! - log.glucoseBeforeMeal!);
        spikeCount++;
      }
    }
    final avgSpike = spikeCount > 0 ? totalSpike / spikeCount : 0.0;

    // 3. Most Frequent Meal Type
    final typeCounts = <String, int>{};
    for (var log in logs) {
      final t = log.mealTime.toUpperCase();
      typeCounts[t] = (typeCounts[t] ?? 0) + 1;
    }
    
    String topType = '-';
    if (typeCounts.isNotEmpty) {
      topType = typeCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      // Capitalize format
      if (topType.isNotEmpty) {
        topType = topType[0].toUpperCase() + topType.substring(1).toLowerCase();
      }
    }

    return _DietCard(
      title: 'Overview',
      icon: Icons.analytics_outlined,
      infoText: 'Key statistics from your meal logs.\n\n'
                ' Avg Spike: Average rise in glucose after meals.\n'
                ' Top Meal: Most frequently logged meal time.',
      child: Row(
        children: [
          Expanded(
            child: _buildStatBox(
              context, 
              'Total Logs', 
              '$total', 
              'meals', 
              AppTheme.primaryGreen
            )
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatBox(
              context, 
              'Avg Spike', 
              avgSpike > 0 ? '+${avgSpike.toStringAsFixed(0)}' : '--', 
              'mg/dL', 
              avgSpike > 50 ? AppTheme.errorColor : (avgSpike > 30 ? AppTheme.warningColor : AppTheme.primaryGreen)
            )
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatBox(
              context, 
              'Top Meal', 
              topType, 
              '', 
              AppTheme.primaryGreen
            )
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(BuildContext context, String title, String value, String unit, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title, 
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 10, 
              fontWeight: FontWeight.bold
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value, 
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold, 
                    color: color
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 2),
                Text(
                  unit, 
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10)
                ),
              ]
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 2. DIET IMPACT CHART (Avg Spike by Type)
// ============================================================================

class _DietImpactChart extends StatelessWidget {
  final List<DailyPatientLog> logs;

  const _DietImpactChart({required this.logs});

  @override
  Widget build(BuildContext context) {
    // Filter last 28 days
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(days: 28));
    final recentLogs = logs.where((l) => l.logDate.isAfter(cutoff)).toList();

    // Calculate avg spike per meal type
    final dataMap = <String, List<double>>{
      'BREAKFAST': [],
      'LUNCH': [],
      'DINNER': []
    };

    for (var log in recentLogs) {
      if (log.glucoseBeforeMeal != null && log.glucoseAfterMeal != null) {
        final spike = log.glucoseAfterMeal! - log.glucoseBeforeMeal!;
        if (dataMap.containsKey(log.mealTime)) {
          dataMap[log.mealTime]!.add(spike);
        }
      }
    }

    final categories = ['BREAKFAST', 'LUNCH', 'DINNER'];
    final barGroups = <BarChartGroupData>[];
    double maxVal = 0;

    for (int i = 0; i < categories.length; i++) {
      final type = categories[i];
      final spikes = dataMap[type]!;
      double avg = 0;
      if (spikes.isNotEmpty) {
        avg = spikes.reduce((a, b) => a + b) / spikes.length;
      }
      if (avg > maxVal) maxVal = avg;

      // Color logic
      Color barColor = AppTheme.primaryGreen;
      if (avg > 50) barColor = AppTheme.errorColor;
      else if (avg > 30) barColor = AppTheme.warningColor;
      
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: avg > 0 ? avg : 2, // Minimal height if 0 or negative to show empty
              color: spikes.isEmpty ? AppTheme.textSecondaryColor.withOpacity(0.2) : barColor,
              width: 24,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            )
          ],
          showingTooltipIndicators: spikes.isNotEmpty ? [0] : [],
        )
      );
    }

    return _DietCard(
      title: 'Glucose Impact',
      icon: Icons.bar_chart,
      infoText: 'Average glucose spike by meal time (Last 28 Days).\n\n'
                ' Height represents the rise in glucose (mg/dL).\n'
                ' Green: Stable (<30)\n'
                ' Orange: Moderate (30-50)\n'
                ' Red: High (>50)',
      child: SizedBox(
        height: 220,
        child: BarChart(
          BarChartData(
            maxY: math.max(maxVal * 1.2, 60),
            alignment: BarChartAlignment.spaceAround,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 20,
              getDrawingHorizontalLine: (_) => FlLine(color: AppTheme.getBorderColor(context).withOpacity(0.2), strokeWidth: 1),
            ),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (val, meta) {
                    if (val < 0 || val >= 3) return const SizedBox();
                    final labels = ['Breakfast', 'Lunch', 'Dinner'];
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        labels[val.toInt()],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textSecondaryColor
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border.all(color: AppTheme.getBorderColor(context).withOpacity(0.5)),
            ),
            barGroups: barGroups,
            barTouchData: BarTouchData(
              enabled: false,
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (group) => Colors.transparent,
                tooltipPadding: EdgeInsets.zero,
                tooltipMargin: 4,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  if (dataMap[categories[group.x.toInt()]]!.isEmpty) return null;
                  return BarTooltipItem(
                    '+${rod.toY.toInt()}',
                    TextStyle(
                      color: rod.color,
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
// 3. HISTORY LIST
// ============================================================================

class _DietHistoryList extends StatefulWidget {
  final List<DailyPatientLog> logs;

  const _DietHistoryList({required this.logs});

  @override
  State<_DietHistoryList> createState() => _DietHistoryListState();
}

class _DietHistoryListState extends State<_DietHistoryList> {
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
    final currentItems = totalItems > 0 ? widget.logs.sublist(start, end) : <DailyPatientLog>[];

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
            const Padding(padding: EdgeInsets.all(16), child: Text('No meals logged yet'))
          else
            ...currentItems.map((log) => _buildLogItem(context, log)),
        ],
      ),
    );
  }

  Widget _buildLogItem(BuildContext context, DailyPatientLog log) {
    // Calculate spike and determine color/text
    String valueText = 'Logged';
    String unitText = '';
    Color statusColor = AppTheme.primaryGreen;
    String? deltaText;

    if (log.glucoseBeforeMeal != null && log.glucoseAfterMeal != null) {
      final spike = log.glucoseAfterMeal! - log.glucoseBeforeMeal!;
      
      // Show range instead of just delta
      valueText = '${log.glucoseBeforeMeal!.toInt()} → ${log.glucoseAfterMeal!.toInt()}';
      unitText = 'mg/dL';
      
      // Delta text
      deltaText = (spike > 0 ? '+' : '') + '${spike.toInt()}';

      if (spike > 50) statusColor = AppTheme.errorColor;
      else if (spike > 30) statusColor = AppTheme.warningColor;
      else statusColor = AppTheme.primaryGreen;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final displayMealTime = log.mealTime.isNotEmpty 
        ? log.mealTime[0].toUpperCase() + log.mealTime.substring(1).toLowerCase()
        : log.mealTime;

    final mealName = log.mealDesc != null && log.mealDesc!.isNotEmpty 
        ? log.mealDesc! 
        : displayMealTime;

    // Use specific time if available, otherwise fallback to logDate
    final displayDate = log.effectiveTime;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.midnightSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03), 
            blurRadius: 8, 
            offset: const Offset(0, 2)
          )
        ],
        border: Border.all(color: statusColor.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // LEFT: Value & Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      valueText,
                      style: TextStyle(
                        fontWeight: FontWeight.normal,
                        fontSize: 18,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    if (unitText.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Text(
                        unitText,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondaryColor,
                              fontSize: 12,
                            ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  mealName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // RIGHT: Delta/Type & Time
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (deltaText != null) ...[
                    Text(
                      displayMealTime,
                      style: TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (deltaText != null ? statusColor : AppTheme.primaryGreen).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: (deltaText != null ? statusColor : AppTheme.primaryGreen).withOpacity(0.3), 
                        width: 1
                      ),
                    ),
                    child: Text(
                      deltaText ?? displayMealTime,
                      style: TextStyle(
                        color: deltaText != null ? statusColor : AppTheme.primaryGreen,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                DateFormat('dd/MM/yy HH:mm').format(displayDate.toLocal()),
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
  }
}

// ============================================================================
// HELPER WRAPPER
// ============================================================================

class _DietCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String infoText;
  final Widget child;

  const _DietCard({
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
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

// ============================================================================
// TRAFFIC LIGHT CALENDAR
// ============================================================================

class _TrafficLightCalendar extends StatelessWidget {
  final List<DailyPatientLog> logs;

  const _TrafficLightCalendar({required this.logs});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 1. Prepare Data: Map Date -> Max Spike for that day
    final Map<int, double> dayMaxSpike = {};
    final Map<int, int> dayLogCount = {};

    for (var log in logs) {
      // FIX: Convert to Local Time to ensure alignment with UI
      final localDate = log.logDate.toLocal();
      final dateKey = DateTime(localDate.year, localDate.month, localDate.day).millisecondsSinceEpoch;
      
      // Count logs
      dayLogCount[dateKey] = (dayLogCount[dateKey] ?? 0) + 1;

      // Calculate spike
      if (log.glucoseBeforeMeal != null && log.glucoseAfterMeal != null) {
        final spike = log.glucoseAfterMeal! - log.glucoseBeforeMeal!;
        
        // Keep the HIGHEST spike of the day (worst case scenario dictates the color)
        if (!dayMaxSpike.containsKey(dateKey) || spike > dayMaxSpike[dateKey]!) {
          dayMaxSpike[dateKey] = spike;
        }
      } else {
        // Logged but no glucose data? Treat as 0 spike (Green) if not already set
        dayMaxSpike.putIfAbsent(dateKey, () => 0);
      }
    }

    // 2. Logic to Align Grid to Monday
    final currentWeekday = today.weekday; // 1=Mon...7=Sun
    final startOfCurrentWeek = today.subtract(Duration(days: currentWeekday - 1));
    final startDate = startOfCurrentWeek.subtract(const Duration(days: 21)); // Go back 3 weeks

    return _DietCard(
      title: 'Consistency Calendar',
      icon: Icons.calendar_view_month,
      infoText: 'A 4-week view of your diet control.\n\n'
                '• Green: Controlled (Max spike < 30)\n'
                '• Yellow: Moderate (Max spike 30-50)\n'
                '• Red: High Spike (Max spike > 50)\n'
                '• Grey: No meals logged',
      child: Column(
        children: [
          // Days of Week Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                .map((d) => Expanded(
                      child: Text(
                        d,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.textSecondaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
          
          // The Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 28,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              final date = startDate.add(Duration(days: index));
              
              // Handle Future Dates (Hide Cell)
              if (date.isAfter(today)) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.getBorderColor(context).withOpacity(0.3), width: 1),
                  ),
                );
              }

              final dateKey = date.millisecondsSinceEpoch;
              final hasLog = dayLogCount.containsKey(dateKey);
              final maxSpike = dayMaxSpike[dateKey];

              Color cellColor;
              Color textColor;
              String tooltip;

              if (!hasLog) {
                cellColor = Colors.transparent;
                textColor = AppTheme.textSecondaryColor.withOpacity(0.5);
                tooltip = 'No logs';
              } else if (maxSpike == null) {
                // Logged but no glucose data
                cellColor = AppTheme.primaryBlue.withOpacity(0.2);
                textColor = AppTheme.primaryBlue;
                tooltip = 'Meal logged (No Glucose)';
              } else if (maxSpike > 50) {
                cellColor = AppTheme.errorColor;
                textColor = Colors.white;
                tooltip = 'High Spike: +${maxSpike.toInt()}';
              } else if (maxSpike > 30) {
                cellColor = AppTheme.warningColor;
                textColor = Colors.white;
                tooltip = 'Moderate: +${maxSpike.toInt()}';
              } else {
                cellColor = AppTheme.primaryGreen;
                textColor = Colors.white;
                tooltip = 'Stable: +${maxSpike.toInt()}';
              }

              // Highlight "Today"
              final isToday = date.year == now.year && date.month == now.month && date.day == now.day;

              return Tooltip(
                message: '${DateFormat('MMM d').format(date)}\n$tooltip',
                child: Container(
                  decoration: BoxDecoration(
                    color: cellColor,
                    borderRadius: BorderRadius.circular(8),
                    border: !hasLog 
                      ? Border.all(color: AppTheme.getBorderColor(context).withOpacity(0.5), width: 1)
                      : (isToday ? Border.all(color: AppTheme.textPrimaryColor, width: 2) : null),
                  ),
                  alignment: Alignment.center,
                  child: hasLog ? Text(
                    '${date.day}',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ) : Text(
                    '${date.day}',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(color: AppTheme.primaryGreen, label: 'Good'),
              const SizedBox(width: 16),
              _LegendDot(color: AppTheme.warningColor, label: 'Fair'),
              const SizedBox(width: 16),
              _LegendDot(color: AppTheme.errorColor, label: 'High Spike'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondaryColor,
          ),
        ),
      ],
    );
  }
}
