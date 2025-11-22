import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../../../../config/theme.dart';
import '../../core/models/health_data_models.dart';
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
          // Sort logs descending by date
          final sortedLogs = List<DailyPatientLog>.from(logs)
            ..sort((a, b) => b.logDate.compareTo(a.logDate));

          return RefreshIndicator(
            onRefresh: () async {
              await ref.refresh(dailyPatientLogsProvider.future);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // 1. Statistics
                  _DietStatsSection(logs: sortedLogs),
                  const SizedBox(height: 20),

                  // 2. Impact Chart
                  _DietImpactChart(logs: sortedLogs),
                  const SizedBox(height: 20),

                  // 3. History List
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
              AppTheme.mealColor
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
              AppTheme.primaryBlue
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
    // Calculate avg spike per meal type
    final dataMap = <String, List<double>>{
      'BREAKFAST': [],
      'LUNCH': [],
      'DINNER': []
    };

    for (var log in logs) {
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
      
      // If avg is negative (drop), maybe show different color? Stick to green for now.
      
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
      infoText: 'Average glucose spike by meal time.\n\n'
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
            borderData: FlBorderData(show: false),
            barGroups: barGroups,
            barTouchData: BarTouchData(
              enabled: false,
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => Colors.transparent,
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
    // Calculate spike if available
    String statusText = 'LOGGED';
    Color statusColor = AppTheme.primaryBlue;

    if (log.glucoseBeforeMeal != null && log.glucoseAfterMeal != null) {
      final spike = log.glucoseAfterMeal! - log.glucoseBeforeMeal!;
      if (spike > 0) {
        statusText = '+${spike.toInt()} mg/dL';
        if (spike > 50) statusColor = AppTheme.errorColor;
        else if (spike > 30) statusColor = AppTheme.warningColor;
        else statusColor = AppTheme.primaryGreen;
      } else {
        statusText = '${spike.toInt()} mg/dL';
        statusColor = AppTheme.primaryGreen;
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mealName = log.mealDesc != null && log.mealDesc!.isNotEmpty 
        ? log.mealDesc! 
        : log.mealTime[0].toUpperCase() + log.mealTime.substring(1).toLowerCase();

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
          // LEFT: Name & Time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mealName,
                  style: TextStyle(
                    fontWeight: FontWeight.normal,
                    fontSize: 16,
                    color: AppTheme.textPrimaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 12, color: AppTheme.textSecondaryColor),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMM d').format(log.logDate), // Just date as log_date is DATE
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondaryColor,
                            fontSize: 11,
                          ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.mealColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        log.mealTime,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.mealColor
                        ),
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),

          // RIGHT: Status Badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (log.glucoseBeforeMeal != null) ...[
                const SizedBox(height: 6),
                Text(
                  '${log.glucoseBeforeMeal!.toInt()} → ${log.glucoseAfterMeal?.toInt() ?? "?"}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: AppTheme.textSecondaryColor,
                  ),
                )
              ]
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
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}
