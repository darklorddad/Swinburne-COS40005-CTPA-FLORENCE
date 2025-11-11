import 'dart:math' as dart_math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../shared/widgets/card_widgets.dart';
import '../../../../config/theme.dart';

/// Glucose Trends Detail Screen
/// Full-screen detailed view with advanced glucose trend analytics
class GlucoseTrendsDetailScreen extends StatefulWidget {
  const GlucoseTrendsDetailScreen({super.key});

  @override
  State<GlucoseTrendsDetailScreen> createState() =>
      _GlucoseTrendsDetailScreenState();
}

class _GlucoseTrendsDetailScreenState extends State<GlucoseTrendsDetailScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  String _selectedPeriod = '7 Days';
  late TabController _tabController;

  // Time period options
  final List<String> _periods = [
    'Today',
    '7 Days',
    '14 Days',
    '30 Days',
    '90 Days',
  ];

  // Mock glucose data for charts
  List<FlSpot> _glucoseData = [];
  List<BarChartGroupData> _dailyAverages = [];
  Map<int, Map<int, double>> _heatmapData = {}; // day × hour → glucose

  // Statistics
  double _averageGlucose = 118.5;
  double _highestGlucose = 195.0;
  double _lowestGlucose = 65.0;
  double _standardDeviation = 28.5;
  double _estimatedA1c = 6.2;
  int _totalReadings = 28;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDetailedTrendsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Load detailed trends data
  Future<void> _loadDetailedTrendsData() async {
    setState(() => _isLoading = true);

    try {
      // TODO: Load real data from Supabase
      // For now, generate mock data
      _generateMockData();

      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      debugPrint('Error loading detailed trends: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Generate comprehensive mock glucose data
  void _generateMockData() {
    _glucoseData.clear();
    _dailyAverages.clear();
    _heatmapData.clear();

    // Generate 7 days of data (4-6 readings per day)
    final readings = [
      [82, 110, 145, 118, 95], // Day 0 - Monday
      [88, 105, 158, 122, 102], // Day 1 - Tuesday
      [75, 98, 142, 115, 90], // Day 2 - Wednesday
      [95, 112, 165, 125, 108], // Day 3 - Thursday
      [85, 108, 148, 120, 98], // Day 4 - Friday
      [92, 115, 155, 128, 105], // Day 5 - Saturday
      [78, 102, 138, 112, 95], // Day 6 - Sunday
    ];

    int spotIndex = 0;
    for (int day = 0; day < readings.length; day++) {
      final dayReadings = readings[day];
      double daySum = 0;

      for (int i = 0; i < dayReadings.length; i++) {
        final value = dayReadings[i].toDouble();
        _glucoseData.add(FlSpot(spotIndex.toDouble(), value));
        daySum += value;

        // Add to heatmap (hour = reading index * 4)
        final hour = (i * 4) + 6; // Start at 6 AM
        if (!_heatmapData.containsKey(day)) {
          _heatmapData[day] = {};
        }
        _heatmapData[day]![hour] = value;

        spotIndex++;
      }

      // Calculate daily average for bar chart
      final dayAvg = daySum / dayReadings.length;
      _dailyAverages.add(
        BarChartGroupData(
          x: day,
          barRods: [
            BarChartRodData(
              toY: dayAvg,
              color: AppTheme.getGlucoseColor(dayAvg, 70, 180),
              width: 32,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
    }

    // Recalculate statistics
    _calculateStatistics();
  }

  /// Calculate statistics from mock data
  void _calculateStatistics() {
    if (_glucoseData.isEmpty) return;

    final values = _glucoseData.map((e) => e.y).toList();
    _averageGlucose = values.reduce((a, b) => a + b) / values.length;
    _highestGlucose = values.reduce((a, b) => a > b ? a : b);
    _lowestGlucose = values.reduce((a, b) => a < b ? a : b);
    _totalReadings = values.length;

    // Calculate standard deviation
    final variance = values
            .map((v) => (v - _averageGlucose) * (v - _averageGlucose))
            .reduce((a, b) => a + b) /
        values.length;
    _standardDeviation = dart_math.sqrt(variance);

    // Estimate A1c: A1c ≈ (average glucose + 46.7) / 28.7
    _estimatedA1c = (_averageGlucose + 46.7) / 28.7;
  }

  /// Change time period
  void _changePeriod(String period) {
    setState(() {
      _selectedPeriod = period;
    });
    _loadDetailedTrendsData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Glucose Trends Detail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () {
              Helpers.showInfo(context, 'Export feature coming soon');
            },
            tooltip: 'Export Data',
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              Helpers.showInfo(context, 'Share feature coming soon');
            },
            tooltip: 'Share',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Timeline', icon: Icon(Icons.show_chart, size: 20)),
            Tab(text: 'Daily Avg', icon: Icon(Icons.bar_chart, size: 20)),
            Tab(text: 'Heatmap', icon: Icon(Icons.grid_on, size: 20)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Period selector
                Container(
                  padding: EdgeInsets.all(
                    ResponsiveHelper.getResponsivePadding(context),
                  ),
                  color: AppTheme.backgroundColor,
                  child: _buildPeriodSelector(),
                ),

                // Time in Range & AI Insights (moved up for prominence)
                Container(
                  padding: EdgeInsets.all(
                    ResponsiveHelper.getResponsivePadding(context),
                  ),
                  color: AppTheme.primaryBlue.withOpacity(0.05),
                  child: _buildAIInsightsSection(),
                ),

                // Statistics summary bar
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveHelper.getResponsiveHorizontalPadding(context),
                    vertical: 12,
                  ),
                  color: AppTheme.surfaceColor,
                  child: _buildStatisticsBar(),
                ),

                // Tab views
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTimelineView(),
                      _buildDailyAveragesView(),
                      _buildHeatmapView(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  /// Build period selector
  Widget _buildPeriodSelector() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _periods.length,
        itemBuilder: (context, index) {
          final period = _periods[index];
          final isSelected = period == _selectedPeriod;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(period),
              selected: isSelected,
              onSelected: (_) => _changePeriod(period),
              selectedColor: AppTheme.primaryBlue,
              backgroundColor: AppTheme.backgroundColor,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  /// Build compact statistics bar
  Widget _buildStatisticsBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem('Avg', '${_averageGlucose.toStringAsFixed(0)} mg/dL'),
        _buildStatItem('High', '${_highestGlucose.toStringAsFixed(0)} mg/dL'),
        _buildStatItem('Low', '${_lowestGlucose.toStringAsFixed(0)} mg/dL'),
        _buildStatItem('A1c', '${_estimatedA1c.toStringAsFixed(1)}%'),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  /// Build AI Insights Section (prominent placement above statistics)
  Widget _buildAIInsightsSection() {
    // Calculate time in range (70-180 mg/dL)
    final inRangeCount = _glucoseData.where((spot) => spot.y >= 70 && spot.y <= 180).length;
    final timeInRange = _glucoseData.isEmpty ? 0.0 : (inRangeCount / _glucoseData.length) * 100;

    // Determine status
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (timeInRange >= 70) {
      statusColor = AppTheme.primaryGreen;
      statusText = 'Excellent Control';
      statusIcon = Icons.check_circle;
    } else if (timeInRange >= 50) {
      statusColor = AppTheme.warningColor;
      statusText = 'Good Control';
      statusIcon = Icons.info;
    } else {
      statusColor = AppTheme.errorColor;
      statusText = 'Needs Attention';
      statusIcon = Icons.warning;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Time in Range - Large prominent display
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: statusColor.withOpacity(0.3), width: 2),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  statusIcon,
                  color: statusColor,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Time in Range',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${timeInRange.toStringAsFixed(0)}%',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // AI Insights Row
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.psychology,
                color: AppTheme.primaryBlue,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _getAIInsightText(timeInRange),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Get AI insight text based on time in range
  String _getAIInsightText(double timeInRange) {
    if (timeInRange >= 70) {
      return 'Your glucose control is excellent! Keep up your current routine.';
    } else if (timeInRange >= 50) {
      return 'Good progress! Focus on post-meal activity to improve further.';
    } else {
      return 'Consider reviewing meal timing and portions with your care team.';
    }
  }

  /// Build timeline view with full-screen line chart
  Widget _buildTimelineView() {
    return RefreshIndicator(
      onRefresh: _loadDetailedTrendsData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BaseCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Glucose Timeline',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Interactive chart - tap data points for details',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: ResponsiveHelper.getResponsiveChartHeight(context),
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: true,
                          horizontalInterval: 30,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: AppTheme.borderColor,
                              strokeWidth: 1,
                            );
                          },
                        ),
                        titlesData: FlTitlesData(
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              interval: 5,
                              getTitlesWidget: (value, meta) {
                                if (value % 5 != 0) return const SizedBox();
                                final day = (value / 5).floor();
                                final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                                if (day >= dayNames.length) return const SizedBox();
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    dayNames[day],
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 42,
                              interval: 30,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toInt().toString(),
                                  style: Theme.of(context).textTheme.bodySmall,
                                );
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border.all(
                            color: AppTheme.borderColor,
                          ),
                        ),
                        minX: 0,
                        maxX: _glucoseData.length.toDouble() - 1,
                        minY: 40,
                        maxY: 220,
                        // Reference lines for range
                        extraLinesData: ExtraLinesData(
                          horizontalLines: [
                            HorizontalLine(
                              y: 70,
                              color: AppTheme.glucoseLow.withValues(alpha: 0.5),
                              strokeWidth: 2,
                              dashArray: [5, 5],
                              label: HorizontalLineLabel(
                                show: true,
                                labelResolver: (line) => 'Low',
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                            HorizontalLine(
                              y: 180,
                              color: AppTheme.glucoseHigh.withValues(alpha: 0.5),
                              strokeWidth: 2,
                              dashArray: [5, 5],
                              label: HorizontalLineLabel(
                                show: true,
                                labelResolver: (line) => 'High',
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: _glucoseData,
                            isCurved: true,
                            color: AppTheme.primaryBlue,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) {
                                return FlDotCirclePainter(
                                  radius: 4,
                                  color: AppTheme.getGlucoseColor(spot.y, 70, 180),
                                  strokeWidth: 2,
                                  strokeColor: Colors.white,
                                );
                              },
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                            ),
                          ),
                        ],
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipItems: (touchedSpots) {
                              return touchedSpots.map((spot) {
                                final value = spot.y;
                                final color = AppTheme.getGlucoseColor(value, 70, 180);
                                return LineTooltipItem(
                                  '${value.toStringAsFixed(0)} mg/dL\n',
                                  TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: _getGlucoseStatus(value),
                                      style: TextStyle(
                                        color: color,
                                        fontSize: 12,
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
                  const SizedBox(height: 16),
                  _buildLegend(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build daily averages bar chart view
  Widget _buildDailyAveragesView() {
    return RefreshIndicator(
      onRefresh: _loadDetailedTrendsData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BaseCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily Average Glucose',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Average glucose levels per day',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 400,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: 200,
                        minY: 0,
                        groupsSpace: 20,
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              final dayNames = [
                                'Monday',
                                'Tuesday',
                                'Wednesday',
                                'Thursday',
                                'Friday',
                                'Saturday',
                                'Sunday'
                              ];
                              return BarTooltipItem(
                                '${dayNames[group.x.toInt()]}\n',
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                children: [
                                  TextSpan(
                                    text: '${rod.toY.toStringAsFixed(0)} mg/dL avg',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                                if (value.toInt() >= dayNames.length) {
                                  return const SizedBox();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    dayNames[value.toInt()],
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 42,
                              interval: 50,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toInt().toString(),
                                  style: Theme.of(context).textTheme.bodySmall,
                                );
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border.all(
                            color: AppTheme.borderColor,
                          ),
                        ),
                        gridData: FlGridData(
                          show: true,
                          horizontalInterval: 50,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: AppTheme.borderColor,
                              strokeWidth: 1,
                            );
                          },
                          drawVerticalLine: false,
                        ),
                        barGroups: _dailyAverages,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            BaseCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weekly Insights',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  _buildInsightItem(
                    Icons.trending_up,
                    'Best Day',
                    'Wednesday',
                    'Average: 106 mg/dL',
                    AppTheme.successColor,
                  ),
                  const SizedBox(height: 12),
                  _buildInsightItem(
                    Icons.trending_down,
                    'Needs Attention',
                    'Thursday',
                    'Average: 135 mg/dL',
                    AppTheme.warningColor,
                  ),
                  const SizedBox(height: 12),
                  _buildInsightItem(
                    Icons.timeline,
                    'Most Consistent',
                    'Weekend',
                    'Lower variability',
                    AppTheme.infoColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build heatmap view (day × hour pattern)
  Widget _buildHeatmapView() {
    return RefreshIndicator(
      onRefresh: _loadDetailedTrendsData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BaseCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Glucose Pattern Heatmap',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Identify patterns by day of week and time of day',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 24),
                  _buildHeatmapGrid(),
                  const SizedBox(height: 24),
                  _buildHeatmapLegend(),
                ],
              ),
            ),
            const SizedBox(height: 16),
            BaseCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pattern Insights',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  _buildInsightItem(
                    Icons.wb_sunny_outlined,
                    'Morning Pattern',
                    'Glucose tends to be lower in the morning',
                    '6 AM - 10 AM: Avg 92 mg/dL',
                    AppTheme.successColor,
                  ),
                  const SizedBox(height: 12),
                  _buildInsightItem(
                    Icons.restaurant,
                    'Post-Meal Spikes',
                    'Highest readings after lunch',
                    '2 PM - 4 PM: Avg 152 mg/dL',
                    AppTheme.warningColor,
                  ),
                  const SizedBox(height: 12),
                  _buildInsightItem(
                    Icons.bedtime,
                    'Evening Control',
                    'Good control in the evening',
                    '6 PM - 10 PM: Avg 110 mg/dL',
                    AppTheme.successColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build heatmap grid
  Widget _buildHeatmapGrid() {
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final hours = [6, 10, 14, 18, 22]; // Simplified time slots

    return Column(
      children: [
        // Header row with hours
        Row(
          children: [
            const SizedBox(width: 50), // Space for day labels
            ...hours.map((hour) {
              return Expanded(
                child: Center(
                  child: Text(
                    '${hour}:00',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              );
            }),
          ],
        ),
        const SizedBox(height: 8),
        // Grid rows
        ...List.generate(7, (dayIndex) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                // Day label
                SizedBox(
                  width: 50,
                  child: Text(
                    dayNames[dayIndex],
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                // Heat cells
                ...hours.map((hour) {
                  final value = _heatmapData[dayIndex]?[hour] ?? 0;
                  final color = _getHeatmapColor(value);
                  return Expanded(
                    child: Container(
                      height: 40,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Text(
                          value > 0 ? value.toInt().toString() : '-',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: value > 0 ? Colors.white : AppTheme.textSecondaryColor,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        }),
      ],
    );
  }

  /// Build heatmap legend
  Widget _buildHeatmapLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Low',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(width: 8),
        ...List.generate(5, (index) {
          final value = 60 + (index * 30).toDouble();
          return Container(
            width: 40,
            height: 20,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: _getHeatmapColor(value),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
        const SizedBox(width: 8),
        Text(
          'High',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  /// Get heatmap color based on glucose value
  Color _getHeatmapColor(double value) {
    if (value == 0) return AppTheme.backgroundColor;
    if (value < 70) return AppTheme.glucoseLow;
    if (value <= 180) return AppTheme.glucoseNormal;
    return AppTheme.glucoseHigh;
  }

  /// Build legend for timeline chart
  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem('Low (<70)', AppTheme.glucoseLow),
        const SizedBox(width: 16),
        _buildLegendItem('Normal (70-180)', AppTheme.glucoseNormal),
        const SizedBox(width: 16),
        _buildLegendItem('High (>180)', AppTheme.glucoseHigh),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  /// Build insight item
  Widget _buildInsightItem(
    IconData icon,
    String title,
    String value,
    String subtitle,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Get glucose status label
  String _getGlucoseStatus(double value) {
    if (value < 70) return 'Low';
    if (value <= 180) return 'Normal';
    return 'High';
  }
}
