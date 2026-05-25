import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:florence/config/theme.dart';
import 'package:florence/config/routes.dart';
import 'package:florence/core/layout/responsive_layout_system.dart';
import 'package:florence/features/patient/core/models/health_data_models.dart';
import 'package:florence/features/patient/core/providers/monitor_data_providers.dart' as core_data;
import 'package:florence/features/patient/dashboard/providers/dashboard_providers.dart';

/// Diet Analytics Screen (formerly MealImpactScreen)
class DietAnalyticsScreen extends ConsumerWidget {
  final VoidCallback? onSwitchToLogMeal;
  final VoidCallback? onSwitchToLogGlucose;
  const DietAnalyticsScreen({
    super.key,
    this.onSwitchToLogMeal,
    this.onSwitchToLogGlucose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(dailyPatientLogsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diet Analytics'),
        elevation: 0,
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showLogOptions(context),
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
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: context.isDesktop
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    children: [
                                      _DietStatsSection(logs: sortedLogs),
                                      const SizedBox(height: 20),
                                      _TrafficLightCalendar(logs: sortedLogs),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    children: [
                                      _DietImpactChart(logs: sortedLogs),
                                      const SizedBox(height: 20),
                                      _HistorySection(logs: sortedLogs),
                                      const SizedBox(height: 24),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                _DietStatsSection(logs: sortedLogs),
                                const SizedBox(height: 20),
                                _TrafficLightCalendar(logs: sortedLogs),
                                const SizedBox(height: 20),
                                _DietImpactChart(logs: sortedLogs),
                                const SizedBox(height: 20),
                                _HistorySection(logs: sortedLogs),
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

  void _showLogOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.midnightSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Text(
                    'Log Diet',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 24),
                  _buildLogOption(
                    context,
                    title: 'Log w/ Glucose',
                    subtitle: 'Measure impact of food on your levels',
                    icon: Icons.water_drop_rounded,
                    color: AppTheme.primaryRed,
                    onTap: () {
                      Navigator.pop(context);
                      if (onSwitchToLogGlucose != null) {
                        onSwitchToLogGlucose!();
                      } else {
                        AppRoutes.push(context, AppRoutes.logGlucose);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildLogOption(
                    context,
                    title: 'Log Meal Only',
                    subtitle: 'Quickly record what you ate',
                    icon: Icons.restaurant_rounded,
                    color: AppTheme.mealColor,
                    onTap: () {
                      Navigator.pop(context);
                      if (onSwitchToLogMeal != null) {
                        onSwitchToLogMeal!();
                      } else {
                        AppRoutes.push(context, AppRoutes.logMeal);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.getBorderColor(context)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppTheme.textSecondaryColor),
          ],
        ),
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
    // 1. Stable Meals % (Quality Metric: Spike < 30mg/dL)
    final total = logs.length;
    int stableCount = 0;
    int pairCount = 0;
    
    // 2. Avg Spike
    double totalSpike = 0;
    int spikeCount = 0;
    
    // Infer if data is mmol/L (values < 40)
    final bool isMmol = logs.any((l) => (l.glucoseBeforeMeal ?? 100) < 40);
    final double stableLimit = isMmol ? 1.7 : 30.0;
    final double warningLimit = isMmol ? 2.8 : 50.0;

    for (var log in logs) {
      if (log.glucoseBeforeMeal != null && log.glucoseAfterMeal != null) {
        final spike = log.glucoseAfterMeal! - log.glucoseBeforeMeal!;
        totalSpike += spike;
        spikeCount++;
        pairCount++;
        
        if (spike < stableLimit) {
          stableCount++;
        }
      }
    }
    
    final stablePercentage = pairCount > 0 ? (stableCount / pairCount * 100).toStringAsFixed(0) : '0';
    final avgSpike = spikeCount > 0 ? totalSpike / spikeCount : 0.0;

    // 3. Avg Calories
    int totalCalories = 0;
    int calorieCount = 0;
    for (var log in logs) {
      if (log.calories != null && log.calories! > 0) {
        totalCalories += log.calories!;
        calorieCount++;
      }
    }
    final avgCalories = calorieCount > 0 ? totalCalories ~/ calorieCount : 0;

    return _DietCard(
      title: 'Overview',
      icon: Icons.analytics_outlined,
      infoText: 'Key statistics from your meal logs.\n\n'
                '• Stable Meals: % of meals with healthy glucose rise (<30mg/dL).\n'
                '• Avg Spike: Average rise in glucose after meals.\n'
                '• Avg Calories: Average estimated calories per logged meal.',
      child: Row(
        children: [
          Expanded(
            child: _buildStatBox(
              context, 
              'Stable Meals', 
              pairCount > 0 ? '$stablePercentage%' : '--', 
              'target', 
              stableCount > 0 ? AppTheme.primaryGreen : AppTheme.textSecondaryColor
            )
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatBox(
              context, 
              'Avg Spike', 
              spikeCount > 0 ? (avgSpike > 0 ? '+' : '') + avgSpike.toStringAsFixed(0) : '--', 
              'mg/dL', 
              avgSpike > warningLimit ? AppTheme.errorColor : (avgSpike > stableLimit ? AppTheme.warningColor : AppTheme.primaryGreen)
            )
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatBox(
              context, 
              'Avg Calories', 
              avgCalories > 0 ? '$avgCalories' : '--', 
              'kcal', 
              avgCalories > 0 ? AppTheme.primaryGreen : AppTheme.textSecondaryColor
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
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
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
        // Normalize key to Uppercase to match dataMap keys strictly
        final key = log.mealTime.toUpperCase();
        if (dataMap.containsKey(key)) {
          dataMap[key]!.add(spike);
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

      final bool isMmol = recentLogs.any((l) => (l.glucoseBeforeMeal ?? 100) < 40);
      final double stableLimit = isMmol ? 1.7 : 30.0;
      final double warningLimit = isMmol ? 2.8 : 50.0;

      // Color logic
      Color barColor = AppTheme.primaryGreen;
      if (avg > warningLimit) {
        barColor = AppTheme.errorColor;
      } else if (avg > stableLimit) barColor = AppTheme.warningColor;
      
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: avg > 0 ? avg : 2, // Minimal height if 0 or negative to show empty
              color: spikes.isEmpty ? AppTheme.textSecondaryColor.withValues(alpha: 0.2) : barColor,
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
              getDrawingHorizontalLine: (_) => FlLine(color: AppTheme.getBorderColor(context).withValues(alpha: 0.2), strokeWidth: 1),
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
              border: Border.all(color: AppTheme.getBorderColor(context).withValues(alpha: 0.5)),
            ),
            barGroups: barGroups,
            barTouchData: BarTouchData(
              enabled: false,
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (group) => Colors.transparent,
                tooltipPadding: EdgeInsets.zero,
                tooltipMargin: 4,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final cat = categories[group.x.toInt()];
                  final spikes = dataMap[cat]!;
                  if (spikes.isEmpty) return null;
                  
                  final avg = spikes.reduce((a, b) => a + b) / spikes.length;
                  final prefix = avg > 0 ? '+' : '';

                  return BarTooltipItem(
                    '$prefix${avg.toInt()}',
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

class _HistorySection extends StatefulWidget {
  final List<DailyPatientLog> logs;

  const _HistorySection({required this.logs});

  @override
  State<_HistorySection> createState() => _HistorySectionState();
}

class _HistorySectionState extends State<_HistorySection> {
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
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
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
                      color: AppTheme.primaryBlue.withValues(alpha: 0.1), 
                      borderRadius: BorderRadius.circular(12)
                    ),
                    child: const Icon(Icons.history, color: AppTheme.primaryBlue, size: 24),
                  ),
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
            ...currentItems.map((log) => _buildLogItem(context, log)),
        ],
      ),
    );
  }

  Widget _buildLogItem(BuildContext context, DailyPatientLog log) {
    // Calculate spike and determine color/text
    String valueText = 'N/A';
    String unitText = '';
    Color statusColor = AppTheme.primaryBlue;
    String? deltaText = 'N/A';

    if (log.glucoseBeforeMeal != null && log.glucoseAfterMeal != null) {
      final spike = log.glucoseAfterMeal! - log.glucoseBeforeMeal!;
      
      final bool isMmol = log.glucoseBeforeMeal! < 40;
      final double stableLimit = isMmol ? 1.7 : 30.0;
      final double warningLimit = isMmol ? 2.8 : 50.0;

      // Show range instead of just delta
      valueText = isMmol 
          ? '${log.glucoseBeforeMeal!.toStringAsFixed(1)} → ${log.glucoseAfterMeal!.toStringAsFixed(1)}'
          : '${log.glucoseBeforeMeal!.toInt()} → ${log.glucoseAfterMeal!.toInt()}';
      unitText = isMmol ? 'mmol/L' : 'mg/dL';
      
      // Delta text
      deltaText = '${spike > 0 ? '+' : ''}${isMmol ? spike.toStringAsFixed(1) : spike.toInt()}';

      if (spike > warningLimit) {
        statusColor = AppTheme.errorColor;
      } else if (spike > stableLimit) {
        statusColor = AppTheme.warningColor;
      } else {
        statusColor = AppTheme.primaryGreen;
      }
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
    final hasSpecificTime = log.glucoseBeforeMealTime != null || log.glucoseAfterMealTime != null;

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
        border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // NEW: Photo Thumbnail
          if (log.photoUrl != null && log.photoUrl!.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: log.photoUrl!,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.image, size: 20, color: Colors.grey),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 48,
                  height: 48,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.broken_image, size: 20, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],

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
                        fontSize: 20,
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
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        mealName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (log.calories != null && log.calories! > 0)
                      Text(
                        ' • ${log.calories} kcal',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondaryColor,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 24), // Increased spacing

          // RIGHT: Delta/Type & Time
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...[
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
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      deltaText ?? displayMealTime,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                hasSpecificTime 
                    ? DateFormat('dd/MM/yy HH:mm').format(displayDate.toLocal())
                    : DateFormat('dd/MM/yy').format(displayDate.toLocal()),
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
      final localDate = log.logDate.toLocal();
      final dateKey = DateTime(localDate.year, localDate.month, localDate.day).millisecondsSinceEpoch;
      dayLogCount[dateKey] = (dayLogCount[dateKey] ?? 0) + 1;

      if (log.glucoseBeforeMeal != null && log.glucoseAfterMeal != null) {
        final spike = log.glucoseAfterMeal! - log.glucoseBeforeMeal!;
        if (!dayMaxSpike.containsKey(dateKey) || spike > dayMaxSpike[dateKey]!) {
          dayMaxSpike[dateKey] = spike;
        }
      }
    }

    // 2. Logic to Show EXACTLY 28 Past Days (ending Today)
    // We calculate back 27 days from today.
    final startDate = today.subtract(const Duration(days: 27));
    
    // Calculate empty slots needed at start to align with Monday
    // Mon=1 -> 0 empty. Tue=2 -> 1 empty. etc.
    final emptySlots = startDate.weekday - 1; 
    
    // Calculate total cells to fill complete rows (multiple of 7)
    // e.g. if we have 28 days + 2 empty slots = 30 cells -> round up to 35 (5 rows)
    final rawTotal = 28 + emptySlots;
    final totalCells = (rawTotal / 7).ceil() * 7;

    return _DietCard(
      title: 'Consistency Calendar',
      icon: Icons.calendar_view_month,
      infoText: 'A 28-day view of your diet control.\n\n'
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
            itemCount: totalCells,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              // Helper for empty grid cells (Leading or Trailing)
              Widget buildEmptyCell() {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.getBorderColor(context).withValues(alpha: 0.5), // Visible border
                      width: 1
                    ),
                  ),
                );
              }

              // 1. Leading Empty Slots
              if (index < emptySlots) {
                return buildEmptyCell();
              }

              final dayIndex = index - emptySlots;

              // 2. Trailing Empty Slots (Fillers after Today to complete the row)
              if (dayIndex >= 28) {
                return buildEmptyCell();
              }

              // 3. Actual Data Days
              final date = startDate.add(Duration(days: dayIndex));
              final dateKey = date.millisecondsSinceEpoch;
              final hasLog = dayLogCount.containsKey(dateKey);
              final maxSpike = dayMaxSpike[dateKey];

              Color cellColor;
              Color textColor;
              String tooltip;

              if (!hasLog) {
                cellColor = Colors.transparent;
                textColor = AppTheme.textSecondaryColor.withValues(alpha: 0.5);
                tooltip = 'No logs';
              } else if (maxSpike == null) {
                // Logged but no glucose data
                cellColor = AppTheme.primaryBlue;
                textColor = Colors.white;
                tooltip = 'Meal logged (Incomplete Pair)';
              } else {
                final bool isMmol = maxSpike < 15.0; // Spikes > 15 are definitely mg/dL
                final double stableLimit = isMmol ? 1.7 : 30.0;
                final double warningLimit = isMmol ? 2.8 : 50.0;

                if (maxSpike > warningLimit) {
                  cellColor = AppTheme.errorColor;
                  textColor = Colors.white;
                  tooltip = 'High Spike: +${maxSpike.toStringAsFixed(1)}';
                } else if (maxSpike > stableLimit) {
                  cellColor = AppTheme.warningColor;
                  textColor = Colors.white;
                  tooltip = 'Moderate: +${maxSpike.toStringAsFixed(1)}';
                } else {
                  cellColor = AppTheme.primaryGreen;
                  textColor = Colors.white;
                  tooltip = 'Stable: +${maxSpike.toStringAsFixed(1)}';
                }
              }
                cellColor = AppTheme.primaryGreen;
                textColor = Colors.white;
                tooltip = 'Stable: +${maxSpike.toInt()}';
              }

              // Highlight "Today"
              final isToday = date.year == now.year && date.month == now.month && date.day == now.day;

              // Border Logic
              Border? border;
              if (isToday) {
                border = Border.all(color: AppTheme.textPrimaryColor, width: 1.0); // Highlight Today
              } else if (!hasLog) {
                border = Border.all(color: AppTheme.getBorderColor(context).withValues(alpha: 0.5), width: 1);
              }

              // Text Color Logic (If today + no log, match the border color)
              final effectiveTextColor = (isToday && !hasLog) 
                  ? AppTheme.textPrimaryColor 
                  : textColor;

              return Tooltip(
                message: '${DateFormat('MMM d').format(date)}\n$tooltip',
                child: Container(
                  decoration: BoxDecoration(
                    color: cellColor,
                    borderRadius: BorderRadius.circular(8),
                    border: border,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${date.day}',
                    style: TextStyle(
                      color: effectiveTextColor,
                      fontWeight: hasLog || isToday ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          
          // Legend
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 8,
            children: [
              _LegendDot(color: AppTheme.textSecondaryColor.withValues(alpha: 0.5), label: 'No Data', isOutline: true),
              _LegendDot(color: AppTheme.primaryBlue, label: 'No Pair'),
              _LegendDot(color: AppTheme.primaryGreen, label: 'Good'),
              _LegendDot(color: AppTheme.warningColor, label: 'Fair'),
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
  final bool isOutline;

  const _LegendDot({
    required this.color, 
    required this.label,
    this.isOutline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isOutline ? Colors.transparent : color,
            shape: BoxShape.circle,
            border: isOutline ? Border.all(color: color, width: 1) : null,
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
