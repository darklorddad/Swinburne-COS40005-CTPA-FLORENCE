import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../shared/widgets/card_widgets.dart';
import '../../../../config/theme.dart';

/// Activity Impact Analysis Screen
/// Shows how different physical activities affect glucose levels
class ActivityImpactScreen extends StatefulWidget {
  const ActivityImpactScreen({super.key});

  @override
  State<ActivityImpactScreen> createState() => _ActivityImpactScreenState();
}

class _ActivityImpactScreenState extends State<ActivityImpactScreen> {
  bool _isLoading = false;
  String _selectedIntensity = 'All';

  // Intensity filter options
  final List<String> _intensities = [
    'All',
    'Light',
    'Moderate',
    'Vigorous',
  ];

  // Mock activity impact data
  List<ActivityImpact> _allActivities = [];
  List<ActivityImpact> _filteredActivities = [];

  @override
  void initState() {
    super.initState();
    _loadActivityImpactData();
  }

  /// Load activity impact data
  Future<void> _loadActivityImpactData() async {
    setState(() => _isLoading = true);

    try {
      // TODO: Load real data from Supabase
      // For now, generate mock data
      _generateMockActivityData();

      // Filter by intensity
      _filterActivitiesByIntensity();

      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      debugPrint('Error loading activity impact data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Generate mock activity impact data
  void _generateMockActivityData() {
    _allActivities = [
      // Light intensity
      ActivityImpact(
        activityName: 'Walking (Slow)',
        intensity: 'Light',
        avgDuration: 30,
        beforeGlucose: 145,
        afterGlucose: 130,
        glucoseDrop: 15,
        frequency: 25,
        caloriesBurned: 90,
        effectiveness: 3.5,
        optimalTiming: 'After meals',
      ),
      ActivityImpact(
        activityName: 'Yoga',
        intensity: 'Light',
        avgDuration: 45,
        beforeGlucose: 128,
        afterGlucose: 118,
        glucoseDrop: 10,
        frequency: 12,
        caloriesBurned: 135,
        effectiveness: 3.0,
        optimalTiming: 'Morning',
      ),
      ActivityImpact(
        activityName: 'Stretching',
        intensity: 'Light',
        avgDuration: 20,
        beforeGlucose: 135,
        afterGlucose: 128,
        glucoseDrop: 7,
        frequency: 15,
        caloriesBurned: 40,
        effectiveness: 2.5,
        optimalTiming: 'Anytime',
      ),

      // Moderate intensity
      ActivityImpact(
        activityName: 'Walking (Brisk)',
        intensity: 'Moderate',
        avgDuration: 30,
        beforeGlucose: 152,
        afterGlucose: 122,
        glucoseDrop: 30,
        frequency: 20,
        caloriesBurned: 150,
        effectiveness: 4.5,
        optimalTiming: 'After lunch',
      ),
      ActivityImpact(
        activityName: 'Cycling',
        intensity: 'Moderate',
        avgDuration: 40,
        beforeGlucose: 148,
        afterGlucose: 110,
        glucoseDrop: 38,
        frequency: 10,
        caloriesBurned: 280,
        effectiveness: 4.8,
        optimalTiming: 'Morning',
      ),
      ActivityImpact(
        activityName: 'Swimming',
        intensity: 'Moderate',
        avgDuration: 35,
        beforeGlucose: 140,
        afterGlucose: 105,
        glucoseDrop: 35,
        frequency: 8,
        caloriesBurned: 245,
        effectiveness: 4.7,
        optimalTiming: 'Afternoon',
      ),
      ActivityImpact(
        activityName: 'Dancing',
        intensity: 'Moderate',
        avgDuration: 30,
        beforeGlucose: 138,
        afterGlucose: 115,
        glucoseDrop: 23,
        frequency: 6,
        caloriesBurned: 180,
        effectiveness: 4.0,
        optimalTiming: 'Evening',
      ),

      // Vigorous intensity
      ActivityImpact(
        activityName: 'Running',
        intensity: 'Vigorous',
        avgDuration: 25,
        beforeGlucose: 155,
        afterGlucose: 108,
        glucoseDrop: 47,
        frequency: 15,
        caloriesBurned: 325,
        effectiveness: 5.0,
        optimalTiming: 'Morning',
      ),
      ActivityImpact(
        activityName: 'HIIT Workout',
        intensity: 'Vigorous',
        avgDuration: 20,
        beforeGlucose: 142,
        afterGlucose: 98,
        glucoseDrop: 44,
        frequency: 8,
        caloriesBurned: 280,
        effectiveness: 4.9,
        optimalTiming: 'Morning',
      ),
      ActivityImpact(
        activityName: 'Weight Training',
        intensity: 'Vigorous',
        avgDuration: 45,
        beforeGlucose: 138,
        afterGlucose: 102,
        glucoseDrop: 36,
        frequency: 12,
        caloriesBurned: 315,
        effectiveness: 4.6,
        optimalTiming: 'Afternoon',
      ),
      ActivityImpact(
        activityName: 'Basketball',
        intensity: 'Vigorous',
        avgDuration: 35,
        beforeGlucose: 145,
        afterGlucose: 105,
        glucoseDrop: 40,
        frequency: 6,
        caloriesBurned: 350,
        effectiveness: 4.7,
        optimalTiming: 'Afternoon',
      ),
    ];

    // Sort by effectiveness (descending)
    _allActivities.sort((a, b) => b.effectiveness.compareTo(a.effectiveness));
  }

  /// Filter activities by intensity
  void _filterActivitiesByIntensity() {
    if (_selectedIntensity == 'All') {
      _filteredActivities = List.from(_allActivities);
    } else {
      _filteredActivities = _allActivities
          .where((activity) => activity.intensity == _selectedIntensity)
          .toList();
    }
  }

  /// Change intensity filter
  void _changeIntensity(String intensity) {
    setState(() {
      _selectedIntensity = intensity;
      _filterActivitiesByIntensity();
    });
  }

  @override
  Widget build(BuildContext context) {
    final topActivities = _filteredActivities.take(5).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Impact Analysis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              _showInfoDialog();
            },
            tooltip: 'Information',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadActivityImpactData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Intensity filter
                    _buildIntensityFilter(),
                    const SizedBox(height: 24),

                    // Summary stats
                    _buildSummaryStats(),
                    const SizedBox(height: 24),

                    // Correlation scatter chart
                    _buildCorrelationChart(),
                    const SizedBox(height: 24),

                    // Duration vs effectiveness
                    _buildDurationEffectivenessChart(),
                    const SizedBox(height: 24),

                    // Top activities
                    _buildTopActivitiesSection(topActivities),
                    const SizedBox(height: 24),

                    // Complete activity ranking
                    _buildCompleteRanking(),
                    const SizedBox(height: 24),

                    // Recommendations
                    _buildRecommendationsSection(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  /// Build intensity filter
  Widget _buildIntensityFilter() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _intensities.length,
        itemBuilder: (context, index) {
          final intensity = _intensities[index];
          final isSelected = intensity == _selectedIntensity;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(intensity),
              selected: isSelected,
              onSelected: (_) => _changeIntensity(intensity),
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

  /// Build summary statistics
  Widget _buildSummaryStats() {
    final avgDrop = _filteredActivities.isEmpty
        ? 0.0
        : _filteredActivities
                .map((a) => a.glucoseDrop)
                .reduce((a, b) => a + b) /
            _filteredActivities.length;

    final totalActivities = _filteredActivities.length;
    final totalSessions = _filteredActivities.isEmpty
        ? 0
        : _filteredActivities
            .map((a) => a.frequency)
            .reduce((a, b) => a + b);

    final bestActivity = _filteredActivities.isEmpty
        ? null
        : _filteredActivities.reduce(
            (a, b) => a.effectiveness > b.effectiveness ? a : b);

    return BaseCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatColumn(
            'Avg Drop',
            '${avgDrop.toStringAsFixed(0)} mg/dL',
            Icons.trending_down,
            AppTheme.successColor,
          ),
          _buildStatColumn(
            'Activities',
            totalActivities.toString(),
            Icons.fitness_center,
            AppTheme.textPrimaryColor,
          ),
          _buildStatColumn(
            'Sessions',
            totalSessions.toString(),
            Icons.calendar_today,
            AppTheme.infoColor,
          ),
          _buildStatColumn(
            'Top',
            bestActivity?.activityName.split(' ').first ?? '-',
            Icons.star,
            AppTheme.warningColor,
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Build correlation scatter chart (Duration vs Glucose Drop)
  Widget _buildCorrelationChart() {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Activity Duration vs Glucose Drop',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Correlation between workout length and effectiveness',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: ResponsiveHelper.getResponsiveCardChartHeight(context),
            child: _filteredActivities.isEmpty
                ? Center(
                    child: Text(
                      'No activity data for this intensity',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  )
                : ScatterChart(
                    ScatterChartData(
                      minX: 0,
                      maxX: 60,
                      minY: 0,
                      maxY: 60,
                      scatterSpots: _filteredActivities.map((activity) {
                        return ScatterSpot(
                          activity.avgDuration.toDouble(),
                          activity.glucoseDrop.toDouble(),
                          dotPainter: FlDotCirclePainter(
                            color: _getIntensityColor(activity.intensity),
                            radius: 8,
                          ),
                        );
                      }).toList(),
                      scatterTouchData: ScatterTouchData(
                        touchTooltipData: ScatterTouchTooltipData(
                          getTooltipItems: (spot) {
                            final activity = _filteredActivities.firstWhere(
                              (a) =>
                                  a.avgDuration.toDouble() == spot.x &&
                                  a.glucoseDrop.toDouble() == spot.y,
                            );
                            return ScatterTooltipItem(
                              '${activity.activityName}\n${activity.avgDuration} min → -${activity.glucoseDrop} mg/dL',
                              textStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
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
                          axisNameWidget: Text(
                            'Duration (minutes)',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 15,
                            getTitlesWidget: (value, meta) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  value.toInt().toString(),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          axisNameWidget: Text(
                            'Glucose Drop (mg/dL)',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 42,
                            interval: 15,
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
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      gridData: FlGridData(
                        show: true,
                        horizontalInterval: 15,
                        verticalInterval: 15,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: AppTheme.borderColor,
                            strokeWidth: 1,
                          );
                        },
                        getDrawingVerticalLine: (value) {
                          return FlLine(
                            color: AppTheme.borderColor,
                            strokeWidth: 1,
                          );
                        },
                      ),
                    ),
                  ),
          ),
          if (_filteredActivities.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Light', _getIntensityColor('Light')),
                const SizedBox(width: 16),
                _buildLegendItem('Moderate', _getIntensityColor('Moderate')),
                const SizedBox(width: 16),
                _buildLegendItem('Vigorous', _getIntensityColor('Vigorous')),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Build duration vs effectiveness chart
  Widget _buildDurationEffectivenessChart() {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Activity Effectiveness Ranking',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Based on glucose reduction per minute',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: ResponsiveHelper.getResponsiveCardChartHeight(context),
            child: _filteredActivities.isEmpty
                ? Center(
                    child: Text(
                      'No activity data for this intensity',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  )
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 6,
                      minY: 0,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final activity =
                                _filteredActivities[group.x.toInt()];
                            return BarTooltipItem(
                              '${activity.activityName}\n',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Rating: ${activity.effectiveness}/5',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
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
                              if (value.toInt() >= _filteredActivities.length) {
                                return const SizedBox();
                              }
                              final activity =
                                  _filteredActivities[value.toInt()];
                              final words = activity.activityName.split(' ');
                              final shortName = words.first;
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  shortName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(fontSize: 10),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 42,
                            interval: 1,
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
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      gridData: FlGridData(
                        show: true,
                        horizontalInterval: 1,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: AppTheme.borderColor,
                            strokeWidth: 1,
                          );
                        },
                        drawVerticalLine: false,
                      ),
                      barGroups: _filteredActivities
                          .asMap()
                          .entries
                          .map((entry) {
                        final index = entry.key;
                        final activity = entry.value;
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: activity.effectiveness,
                              color: _getIntensityColor(activity.intensity),
                              width: 24,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// Build top activities section
  Widget _buildTopActivitiesSection(List<ActivityImpact> topActivities) {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.activityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.emoji_events,
                  color: AppTheme.activityColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Most Effective Activities',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      'Best activities for glucose control',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...topActivities.map((activity) => _buildActivityCard(activity)),
        ],
      ),
    );
  }

  /// Build complete ranking section
  Widget _buildCompleteRanking() {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Complete Activity Ranking',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'All activities sorted by effectiveness',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          ..._filteredActivities.map((activity) {
            final rank = _filteredActivities.indexOf(activity) + 1;
            return _buildCompactActivityCard(activity, rank);
          }),
        ],
      ),
    );
  }

  /// Build activity card
  Widget _buildActivityCard(ActivityImpact activity) {
    final color = _getIntensityColor(activity.intensity);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '-${activity.glucoseDrop}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  'mg/dL',
                  style: TextStyle(
                    fontSize: 10,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        activity.activityName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < activity.effectiveness.floor()
                              ? Icons.star
                              : Icons.star_border,
                          size: 14,
                          color: AppTheme.warningColor,
                        );
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${activity.avgDuration} min avg • ${activity.caloriesBurned} cal',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  '${activity.intensity} • Best: ${activity.optimalTiming}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build compact activity card for complete ranking
  Widget _buildCompactActivityCard(ActivityImpact activity, int rank) {
    final color = _getIntensityColor(activity.intensity);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.activityName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  '${activity.intensity} • ${activity.avgDuration} min',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '-${activity.glucoseDrop}',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build recommendations section
  Widget _buildRecommendationsSection() {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.infoColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.lightbulb_outline,
                  color: AppTheme.infoColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Activity Recommendations',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRecommendationItem(
            'Optimal timing',
            'Activities are most effective 30-60 minutes after meals',
            Icons.schedule,
          ),
          const SizedBox(height: 12),
          _buildRecommendationItem(
            'Consistency is key',
            'Regular moderate activity (30 min/day) is better than occasional intense workouts',
            Icons.repeat,
          ),
          const SizedBox(height: 12),
          _buildRecommendationItem(
            'Mix intensity levels',
            'Combine light activities (walking) with vigorous ones (running) throughout the week',
            Icons.shuffle,
          ),
          const SizedBox(height: 12),
          _buildRecommendationItem(
            'Track your progress',
            'Your top activity is ${_filteredActivities.isNotEmpty ? _filteredActivities.first.activityName : 'Unknown'}. Keep it up!',
            Icons.trending_up,
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationItem(
    String title,
    String description,
    IconData icon,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 18, color: AppTheme.primaryBlue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
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

  /// Get color based on intensity
  Color _getIntensityColor(String intensity) {
    switch (intensity) {
      case 'Light':
        return AppTheme.successColor;
      case 'Moderate':
        return AppTheme.infoColor;
      case 'Vigorous':
        return AppTheme.primaryRed;
      default:
        return AppTheme.textSecondaryColor;
    }
  }

  /// Show information dialog
  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Activity Impact'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'This analysis shows how physical activity affects your glucose levels.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text(
                'Effectiveness Rating: Based on glucose reduction per minute of activity.',
              ),
              SizedBox(height: 8),
              Text('Light: Low-intensity activities (walking, yoga).'),
              SizedBox(height: 8),
              Text('Moderate: Medium-intensity activities (brisk walking, cycling).'),
              SizedBox(height: 8),
              Text('Vigorous: High-intensity activities (running, HIIT).'),
              SizedBox(height: 12),
              Text(
                'Regular physical activity is one of the most effective ways to manage glucose levels.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

/// Activity Impact Data Model
class ActivityImpact {
  final String activityName;
  final String intensity;
  final int avgDuration;
  final int beforeGlucose;
  final int afterGlucose;
  final int glucoseDrop;
  final int frequency;
  final int caloriesBurned;
  final double effectiveness;
  final String optimalTiming;

  ActivityImpact({
    required this.activityName,
    required this.intensity,
    required this.avgDuration,
    required this.beforeGlucose,
    required this.afterGlucose,
    required this.glucoseDrop,
    required this.frequency,
    required this.caloriesBurned,
    required this.effectiveness,
    required this.optimalTiming,
  });
}
