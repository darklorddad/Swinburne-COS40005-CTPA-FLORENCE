import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../shared/widgets/card_widgets.dart';
import '../../../../config/theme.dart';
import '../../../../config/routes.dart';
import '../../../../core/services/automation/pattern_detection_service.dart';
import '../../core/services/data_ingestion_service.dart';
import 'pattern_detail_screen.dart';

/// Trends Screen
/// Displays glucose trends, charts, and analytics
class TrendsScreen extends StatefulWidget {
  const TrendsScreen({super.key});

  @override
  State<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends State<TrendsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  bool _isDetectingPatterns = false;
  String _selectedPeriod = '7 Days';

  // Services
  final PatternDetectionService _patternService = PatternDetectionService();
  final DataIngestionService _dataService = DataIngestionService();

  // Time period options
  final List<String> _periods = [
    'Today',
    '7 Days',
    '14 Days',
    '30 Days',
    '90 Days',
  ];

  // Mock glucose data for charts
  final List<FlSpot> _glucoseData = [];

  // Mock statistics
  final double _averageGlucose = 118.5;
  final double _highestGlucose = 195.0;
  final double _lowestGlucose = 65.0;
  final double _standardDeviation = 28.5;
  final double _estimatedA1c = 6.2;
  final int _totalReadings = 28;

  // Time in range percentages
  final double _timeInRange = 72.0;
  final double _timeAboveRange = 18.0;
  final double _timeBelowRange = 10.0;

  // Detected patterns
  List<DetectedPattern> _patterns = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTrendsData();
    _loadPatterns();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  /// Load trends data
  Future<void> _loadTrendsData() async {
    setState(() => _isLoading = true);
    
    try {
      // TODO: Load real data from Supabase
      // For now, generate mock data
      _generateMockData();
      
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));
      
    } catch (e) {
      debugPrint('Error loading trends: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  /// Generate mock glucose data
  void _generateMockData() {
    _glucoseData.clear();
    
    // Generate 7 days of data (4 readings per day)
    final random = [
      110, 125, 145, 118, // Day 1
      105, 132, 158, 122, // Day 2
      98, 128, 142, 115,  // Day 3
      112, 138, 165, 125, // Day 4
      108, 122, 148, 120, // Day 5
      115, 135, 155, 128, // Day 6
      102, 118, 138, 112, // Day 7
    ];
    
    for (int i = 0; i < random.length; i++) {
      _glucoseData.add(FlSpot(i.toDouble(), random[i].toDouble()));
    }
  }
  
  /// Load patterns
  Future<void> _loadPatterns() async {
    try {
      final hours = _selectedPeriod == 'Today'
          ? 24
          : _selectedPeriod == '7 Days'
              ? 168
              : _selectedPeriod == '14 Days'
                  ? 336
                  : _selectedPeriod == '30 Days'
                      ? 720
                      : 2160; // 90 days

      final patterns = await _patternService.detectPatterns(
        hoursToAnalyze: hours,
        useAI: true,
      );

      if (mounted) {
        setState(() {
          _patterns = patterns;
        });
      }
    } catch (e) {
      debugPrint('Error loading patterns: $e');
    }
  }

  /// Detect patterns manually
  Future<void> _detectPatternsManually() async {
    setState(() => _isDetectingPatterns = true);

    try {
      await _loadPatterns();

      if (mounted) {
        Helpers.showSuccess(
          context,
          'Found ${_patterns.length} patterns',
        );
      }
    } catch (e) {
      if (mounted) {
        Helpers.showError(context, 'Failed to detect patterns');
      }
    } finally {
      if (mounted) {
        setState(() => _isDetectingPatterns = false);
      }
    }
  }

  /// Change time period
  void _changePeriod(String period) {
    setState(() {
      _selectedPeriod = period;
    });
    _loadTrendsData();
    _loadPatterns();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Glucose Trends'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () {
              Helpers.showInfo(context, 'Export feature coming soon');
            },
            tooltip: 'Export Data',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.show_chart),
              text: 'Overview',
            ),
            Tab(
              icon: Icon(Icons.auto_graph),
              text: 'Patterns',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Overview Tab
                RefreshIndicator(
                  onRefresh: _loadTrendsData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Time period selector
                        _buildPeriodSelector(),
                        const SizedBox(height: 24),

                        // Glucose line chart
                        _buildGlucoseChart(),
                        const SizedBox(height: 24),

                        // Time in range chart
                        _buildTimeInRangeSection(),
                        const SizedBox(height: 24),

                        // Statistics cards
                        _buildStatisticsSection(),
                        const SizedBox(height: 24),

                        // Insights card
                        _buildInsightsCard(),
                        const SizedBox(height: 24),

                        // Advanced Analysis Section
                        _buildAdvancedAnalysisSection(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // Patterns Tab
                RefreshIndicator(
                  onRefresh: _loadPatterns,
                  child: _buildPatternsTab(),
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
  
  /// Build glucose line chart
  Widget _buildGlucoseChart() {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Glucose Levels',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.glucoseNormal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Target: 70-180',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.glucoseNormal,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Chart
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 40,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppTheme.borderColor,
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondaryColor,
                              ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 4,
                      getTitlesWidget: (value, meta) {
                        final day = (value / 4).floor() + 1;
                        if (value % 4 == 0) {
                          return Text(
                            'Day $day',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textSecondaryColor,
                                ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(color: AppTheme.borderColor),
                    left: BorderSide(color: AppTheme.borderColor),
                  ),
                ),
                minX: 0,
                maxX: _glucoseData.length.toDouble() - 1,
                minY: 40,
                maxY: 220,
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
                        Color color = AppTheme.glucoseNormal;
                        if (spot.y < 70) {
                          color = AppTheme.glucoseLow;
                        } else if (spot.y > 180) {
                          color = AppTheme.glucoseHigh;
                        }
                        return FlDotCirclePainter(
                          radius: 3,
                          color: color,
                          strokeWidth: 0,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    ),
                  ),
                ],
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: 70,
                      color: AppTheme.glucoseLow.withValues(alpha: 0.5),
                      strokeWidth: 2,
                      dashArray: [5, 5],
                    ),
                    HorizontalLine(
                      y: 180,
                      color: AppTheme.glucoseHigh.withValues(alpha: 0.5),
                      strokeWidth: 2,
                      dashArray: [5, 5],
                    ),
                  ],
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: AppTheme.primaryBlue.withValues(alpha: 0.8),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          '${spot.y.toInt()} mg/dL',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Legend
          _buildChartLegend(),
        ],
      ),
    );
  }
  
  /// Build chart legend
  Widget _buildChartLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem('Normal', AppTheme.glucoseNormal),
        const SizedBox(width: 24),
        _buildLegendItem('Low', AppTheme.glucoseLow),
        const SizedBox(width: 24),
        _buildLegendItem('High', AppTheme.glucoseHigh),
      ],
    );
  }
  
  /// Build single legend item
  Widget _buildLegendItem(String label, Color color) {
    return Row(
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
  
  /// Build time in range section
  Widget _buildTimeInRangeSection() {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Time in Range',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),
          
          Row(
            children: [
              // Pie chart
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 180,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 50,
                      sections: [
                        PieChartSectionData(
                          value: _timeInRange,
                          title: '${_timeInRange.toInt()}%',
                          color: AppTheme.glucoseNormal,
                          radius: 50,
                          titleStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          value: _timeAboveRange,
                          title: '${_timeAboveRange.toInt()}%',
                          color: AppTheme.glucoseHigh,
                          radius: 50,
                          titleStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          value: _timeBelowRange,
                          title: '${_timeBelowRange.toInt()}%',
                          color: AppTheme.glucoseLow,
                          radius: 50,
                          titleStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Legend
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTimeRangeItem(
                      'In Range',
                      '70-180 mg/dL',
                      _timeInRange,
                      AppTheme.glucoseNormal,
                    ),
                    const SizedBox(height: 12),
                    _buildTimeRangeItem(
                      'Above Range',
                      '>180 mg/dL',
                      _timeAboveRange,
                      AppTheme.glucoseHigh,
                    ),
                    const SizedBox(height: 12),
                    _buildTimeRangeItem(
                      'Below Range',
                      '<70 mg/dL',
                      _timeBelowRange,
                      AppTheme.glucoseLow,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  /// Build time range item
  Widget _buildTimeRangeItem(
    String label,
    String range,
    double percentage,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                range,
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
  
  /// Build statistics section
  Widget _buildStatisticsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistics',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: [
            StatCard(
              label: 'Average',
              value: _averageGlucose.toStringAsFixed(0),
              unit: 'mg/dL',
              icon: Icons.show_chart,
              color: AppTheme.primaryBlue,
            ),
            StatCard(
              label: 'Estimated A1c',
              value: _estimatedA1c.toStringAsFixed(1),
              unit: '%',
              icon: Icons.pie_chart,
              color: AppTheme.primaryGreen,
            ),
            StatCard(
              label: 'Highest',
              value: _highestGlucose.toStringAsFixed(0),
              unit: 'mg/dL',
              icon: Icons.arrow_upward,
              color: AppTheme.glucoseHigh,
            ),
            StatCard(
              label: 'Lowest',
              value: _lowestGlucose.toStringAsFixed(0),
              unit: 'mg/dL',
              icon: Icons.arrow_downward,
              color: AppTheme.glucoseLow,
            ),
            StatCard(
              label: 'Std Deviation',
              value: _standardDeviation.toStringAsFixed(0),
              unit: 'mg/dL',
              icon: Icons.analytics_outlined,
              color: AppTheme.mealColor,
            ),
            StatCard(
              label: 'Total Readings',
              value: _totalReadings.toString(),
              unit: 'readings',
              icon: Icons.water_drop_outlined,
              color: AppTheme.medicationColor,
            ),
          ],
        ),
      ],
    );
  }
  
  /// Build insights card
  Widget _buildInsightsCard() {
    return BaseCard(
      // backgroundColor: AppTheme.infoColor.withOpacity(0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: AppTheme.infoColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'AI Insights',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.infoColor,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          Text(
            '• Your glucose is most stable on weekdays\n'
            '• Morning readings are consistently in range\n'
            '• Consider reducing carbs at dinner to improve overnight levels',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.infoColor,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 12),
          
          TextButton(
            onPressed: () {
              AppRoutes.push(context, AppRoutes.recommendations);
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.infoColor,
              padding: EdgeInsets.zero,
            ),
            child: const Text('View All Recommendations →'),
          ),
        ],
      ),
    );
  }

  /// Build advanced analysis section with navigation cards
  Widget _buildAdvancedAnalysisSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Advanced Analysis',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Explore detailed insights about your glucose patterns',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),

        // Navigation cards
        _buildNavigationCard(
          icon: Icons.show_chart,
          title: 'Detailed Glucose Analysis',
          description: 'Interactive charts, heatmaps, and daily patterns',
          color: AppTheme.primaryBlue,
          onTap: () {
            AppRoutes.push(context, AppRoutes.trendsDetail);
          },
        ),
        const SizedBox(height: 12),
        _buildNavigationCard(
          icon: Icons.restaurant_menu,
          title: 'Meal Impact Analysis',
          description: 'See how different foods affect your glucose levels',
          color: AppTheme.mealColor,
          onTap: () {
            AppRoutes.push(context, AppRoutes.mealImpact);
          },
        ),
        const SizedBox(height: 12),
        _buildNavigationCard(
          icon: Icons.fitness_center,
          title: 'Activity Impact Analysis',
          description: 'Discover which activities work best for glucose control',
          color: AppTheme.activityColor,
          onTap: () {
            AppRoutes.push(context, AppRoutes.activityImpact);
          },
        ),
      ],
    );
  }

  /// Build navigation card
  Widget _buildNavigationCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.borderColor,
            width: 1,
          ),
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
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondaryColor,
                        ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppTheme.textSecondaryColor,
            ),
          ],
        ),
      ),
    );
  }

  /// Build patterns tab
  Widget _buildPatternsTab() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with detect button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detected Patterns',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'AI-powered health pattern analysis',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondaryColor,
                          ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isDetectingPatterns ? null : _detectPatternsManually,
                icon: _isDetectingPatterns
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome, size: 18),
                label: Text(_isDetectingPatterns ? 'Analyzing...' : 'Detect'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Patterns list
          if (_patterns.isEmpty)
            _buildEmptyPatternsState()
          else
            ...List.generate(
              _patterns.length,
              (index) => _buildPatternCard(_patterns[index]),
            ),
        ],
      ),
    );
  }

  /// Build empty patterns state
  Widget _buildEmptyPatternsState() {
    return BaseCard(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_graph,
                  size: 64,
                  color: AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No Patterns Detected',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap "Detect" to analyze your health data for patterns',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build pattern card
  Widget _buildPatternCard(DetectedPattern pattern) {
    final severityConfig = _getPatternSeverityConfig(pattern.severity);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PatternDetailScreen(pattern: pattern),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: BaseCard(
        margin: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Header row
          Row(
            children: [
              // Severity indicator
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: severityConfig['color'].withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  severityConfig['icon'],
                  color: severityConfig['color'],
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),

              // Pattern title and type
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pattern.type.toString().split('.').last.replaceAll('_', ' ').toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: severityConfig['color'],
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pattern.description,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),

              // Severity badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: severityConfig['color'].withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: severityConfig['color'],
                    width: 1.5,
                  ),
                ),
                child: Text(
                  severityConfig['label'],
                  style: TextStyle(
                    color: severityConfig['color'],
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // AI Insight
          if (pattern.aiInsight != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.infoColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.infoColor.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: AppTheme.infoColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      pattern.aiInsight!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textPrimaryColor,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Metadata and tap indicator
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _buildPatternMetadata(
                      Icons.access_time,
                      'Detected ${_formatPatternTime(pattern.detectedAt)}',
                    ),
                    _buildPatternMetadata(
                      Icons.data_usage,
                      '${pattern.dataPointIds.length} data points',
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppTheme.textSecondaryColor,
                size: 24,
              ),
            ],
          ),
          ],
        ),
      ),
    );
  }

  /// Build pattern metadata item
  Widget _buildPatternMetadata(IconData icon, String text, {Color? color}) {
    final effectiveColor = color ?? AppTheme.textSecondaryColor;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: effectiveColor),
        const SizedBox(width: 4),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: effectiveColor,
              ),
        ),
      ],
    );
  }

  /// Get pattern severity configuration
  Map<String, dynamic> _getPatternSeverityConfig(PatternSeverity severity) {
    switch (severity) {
      case PatternSeverity.critical:
        return {
          'label': 'CRITICAL',
          'color': const Color(0xFFD32F2F),
          'icon': Icons.warning,
        };
      case PatternSeverity.high:
        return {
          'label': 'HIGH',
          'color': AppTheme.warningColor,
          'icon': Icons.error_outline,
        };
      case PatternSeverity.medium:
        return {
          'label': 'MEDIUM',
          'color': AppTheme.infoColor,
          'icon': Icons.info_outline,
        };
      case PatternSeverity.low:
        return {
          'label': 'LOW',
          'color': AppTheme.primaryGreen,
          'icon': Icons.check_circle_outline,
        };
    }
  }

  /// Format pattern time
  String _formatPatternTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${(diff.inDays / 7).floor()}w ago';
    }
  }
}