import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../shared/widgets/card_widgets.dart';
import '../../../../config/theme.dart';

/// Meal Impact Analysis Screen
/// Shows how different foods affect glucose levels
class MealImpactScreen extends StatefulWidget {
  const MealImpactScreen({super.key});

  @override
  State<MealImpactScreen> createState() => _MealImpactScreenState();
}

class _MealImpactScreenState extends State<MealImpactScreen> {
  bool _isLoading = false;
  String _selectedMealType = 'All';

  // Meal type filter options
  final List<String> _mealTypes = [
    'All',
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snack',
  ];

  // Mock meal impact data
  List<MealImpact> _allMealImpacts = [];
  List<MealImpact> _filteredMealImpacts = [];

  @override
  void initState() {
    super.initState();
    _loadMealImpactData();
  }

  /// Load meal impact data
  Future<void> _loadMealImpactData() async {
    setState(() => _isLoading = true);

    try {
      // TODO: Load real data from Supabase
      // For now, generate mock data
      _generateMockMealData();

      // Filter by meal type
      _filterMealsByType();

      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      debugPrint('Error loading meal impact data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Generate mock meal impact data
  void _generateMockMealData() {
    _allMealImpacts = [
      // Breakfast foods
      MealImpact(
        foodName: 'Oatmeal with Berries',
        mealType: 'Breakfast',
        beforeGlucose: 95,
        afterGlucose: 125,
        glucoseSpike: 30,
        frequency: 12,
        averageCarbs: 45,
      ),
      MealImpact(
        foodName: 'Scrambled Eggs & Toast',
        mealType: 'Breakfast',
        beforeGlucose: 92,
        afterGlucose: 110,
        glucoseSpike: 18,
        frequency: 15,
        averageCarbs: 25,
      ),
      MealImpact(
        foodName: 'Pancakes with Syrup',
        mealType: 'Breakfast',
        beforeGlucose: 88,
        afterGlucose: 175,
        glucoseSpike: 87,
        frequency: 3,
        averageCarbs: 85,
      ),
      MealImpact(
        foodName: 'Greek Yogurt with Nuts',
        mealType: 'Breakfast',
        beforeGlucose: 90,
        afterGlucose: 105,
        glucoseSpike: 15,
        frequency: 10,
        averageCarbs: 20,
      ),

      // Lunch foods
      MealImpact(
        foodName: 'Grilled Chicken Salad',
        mealType: 'Lunch',
        beforeGlucose: 102,
        afterGlucose: 118,
        glucoseSpike: 16,
        frequency: 18,
        averageCarbs: 15,
      ),
      MealImpact(
        foodName: 'Turkey Sandwich (Whole Wheat)',
        mealType: 'Lunch',
        beforeGlucose: 98,
        afterGlucose: 135,
        glucoseSpike: 37,
        frequency: 14,
        averageCarbs: 40,
      ),
      MealImpact(
        foodName: 'Pasta with Marinara',
        mealType: 'Lunch',
        beforeGlucose: 105,
        afterGlucose: 182,
        glucoseSpike: 77,
        frequency: 5,
        averageCarbs: 75,
      ),
      MealImpact(
        foodName: 'Quinoa Bowl with Veggies',
        mealType: 'Lunch',
        beforeGlucose: 100,
        afterGlucose: 128,
        glucoseSpike: 28,
        frequency: 8,
        averageCarbs: 35,
      ),

      // Dinner foods
      MealImpact(
        foodName: 'Salmon with Broccoli',
        mealType: 'Dinner',
        beforeGlucose: 108,
        afterGlucose: 122,
        glucoseSpike: 14,
        frequency: 16,
        averageCarbs: 10,
      ),
      MealImpact(
        foodName: 'Steak with Sweet Potato',
        mealType: 'Dinner',
        beforeGlucose: 112,
        afterGlucose: 145,
        glucoseSpike: 33,
        frequency: 10,
        averageCarbs: 30,
      ),
      MealImpact(
        foodName: 'Pizza (2 slices)',
        mealType: 'Dinner',
        beforeGlucose: 110,
        afterGlucose: 195,
        glucoseSpike: 85,
        frequency: 4,
        averageCarbs: 70,
      ),
      MealImpact(
        foodName: 'Stir-fry with Brown Rice',
        mealType: 'Dinner',
        beforeGlucose: 105,
        afterGlucose: 138,
        glucoseSpike: 33,
        frequency: 12,
        averageCarbs: 45,
      ),

      // Snacks
      MealImpact(
        foodName: 'Apple with Almond Butter',
        mealType: 'Snack',
        beforeGlucose: 95,
        afterGlucose: 108,
        glucoseSpike: 13,
        frequency: 20,
        averageCarbs: 20,
      ),
      MealImpact(
        foodName: 'Protein Bar',
        mealType: 'Snack',
        beforeGlucose: 102,
        afterGlucose: 125,
        glucoseSpike: 23,
        frequency: 15,
        averageCarbs: 25,
      ),
      MealImpact(
        foodName: 'Chocolate Cookies',
        mealType: 'Snack',
        beforeGlucose: 98,
        afterGlucose: 165,
        glucoseSpike: 67,
        frequency: 6,
        averageCarbs: 55,
      ),
      MealImpact(
        foodName: 'Carrot Sticks with Hummus',
        mealType: 'Snack',
        beforeGlucose: 100,
        afterGlucose: 110,
        glucoseSpike: 10,
        frequency: 18,
        averageCarbs: 12,
      ),
    ];

    // Sort by glucose spike (ascending)
    _allMealImpacts.sort((a, b) => a.glucoseSpike.compareTo(b.glucoseSpike));
  }

  /// Filter meals by selected type
  void _filterMealsByType() {
    if (_selectedMealType == 'All') {
      _filteredMealImpacts = List.from(_allMealImpacts);
    } else {
      _filteredMealImpacts = _allMealImpacts
          .where((meal) => meal.mealType == _selectedMealType)
          .toList();
    }
  }

  /// Change meal type filter
  void _changeMealType(String mealType) {
    setState(() {
      _selectedMealType = mealType;
      _filterMealsByType();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bestFoods = _filteredMealImpacts.take(5).toList();
    final worstFoods = _filteredMealImpacts.reversed.take(5).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Impact Analysis'),
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
              onRefresh: _loadMealImpactData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Meal type filter
                    _buildMealTypeFilter(),
                    const SizedBox(height: 24),

                    // Summary stats
                    _buildSummaryStats(),
                    const SizedBox(height: 24),

                    // Before/After comparison chart
                    _buildComparisonChart(),
                    const SizedBox(height: 24),

                    // Best foods section
                    _buildBestFoodsSection(bestFoods),
                    const SizedBox(height: 24),

                    // Worst foods section
                    _buildWorstFoodsSection(worstFoods),
                    const SizedBox(height: 24),

                    // Complete food ranking
                    _buildCompleteRanking(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  /// Build meal type filter
  Widget _buildMealTypeFilter() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _mealTypes.length,
        itemBuilder: (context, index) {
          final mealType = _mealTypes[index];
          final isSelected = mealType == _selectedMealType;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(mealType),
              selected: isSelected,
              onSelected: (_) => _changeMealType(mealType),
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
    final avgSpike = _filteredMealImpacts.isEmpty
        ? 0.0
        : _filteredMealImpacts
                .map((m) => m.glucoseSpike)
                .reduce((a, b) => a + b) /
            _filteredMealImpacts.length;

    final totalMeals = _filteredMealImpacts.length;
    final goodMeals =
        _filteredMealImpacts.where((m) => m.glucoseSpike <= 30).length;
    final badMeals =
        _filteredMealImpacts.where((m) => m.glucoseSpike > 50).length;

    return BaseCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatColumn(
            'Avg Spike',
            '${avgSpike.toStringAsFixed(0)} mg/dL',
            Icons.trending_up,
            AppTheme.infoColor,
          ),
          _buildStatColumn(
            'Total Meals',
            totalMeals.toString(),
            Icons.restaurant,
            AppTheme.textPrimaryColor,
          ),
          _buildStatColumn(
            'Good Choices',
            goodMeals.toString(),
            Icons.check_circle,
            AppTheme.successColor,
          ),
          _buildStatColumn(
            'Need Caution',
            badMeals.toString(),
            Icons.warning,
            AppTheme.warningColor,
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
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

  /// Build before/after comparison chart
  Widget _buildComparisonChart() {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Before vs After Glucose',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'How your glucose changes after eating',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: ResponsiveHelper.getResponsiveCardChartHeight(context),
            child: _filteredMealImpacts.isEmpty
                ? Center(
                    child: Text(
                      'No meal data for this category',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  )
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 220,
                      minY: 0,
                      groupsSpace: 12,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final meal = _filteredMealImpacts[group.x.toInt()];
                            final isBefore = rodIndex == 0;
                            return BarTooltipItem(
                              '${meal.foodName}\n',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              children: [
                                TextSpan(
                                  text: isBefore
                                      ? 'Before: ${meal.beforeGlucose} mg/dL'
                                      : 'After: ${meal.afterGlucose} mg/dL',
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
                              if (value.toInt() >= _filteredMealImpacts.length) {
                                return const SizedBox();
                              }
                              final meal = _filteredMealImpacts[value.toInt()];
                              final words = meal.foodName.split(' ');
                              final shortName = words.length > 2
                                  ? '${words[0]} ${words[1]}'
                                  : meal.foodName;
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  shortName,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 9),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
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
                        border: Border.all(color: AppTheme.borderColor),
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
                      barGroups: _filteredMealImpacts
                          .take(8) // Show only first 8 for readability
                          .toList()
                          .asMap()
                          .entries
                          .map((entry) {
                        final index = entry.key;
                        final meal = entry.value;
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: meal.beforeGlucose.toDouble(),
                              color: AppTheme.infoColor,
                              width: 12,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                            BarChartRodData(
                              toY: meal.afterGlucose.toDouble(),
                              color: _getGlucoseSpikeColor(meal.glucoseSpike),
                              width: 12,
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
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Before', AppTheme.infoColor),
              const SizedBox(width: 24),
              _buildLegendItem('After (Good)', AppTheme.successColor),
              const SizedBox(width: 24),
              _buildLegendItem('After (High)', AppTheme.errorColor),
            ],
          ),
        ],
      ),
    );
  }

  /// Build best foods section
  Widget _buildBestFoodsSection(List<MealImpact> bestFoods) {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.thumb_up,
                  color: AppTheme.successColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Best Choices',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      'Foods with minimal glucose impact',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...bestFoods.map((meal) => _buildFoodRankingCard(meal, true)),
        ],
      ),
    );
  }

  /// Build worst foods section
  Widget _buildWorstFoodsSection(List<MealImpact> worstFoods) {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.thumb_down,
                  color: AppTheme.errorColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Need Caution',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      'Foods causing large glucose spikes',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...worstFoods.map((meal) => _buildFoodRankingCard(meal, false)),
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
            'Complete Food Ranking',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'All foods sorted by glucose impact',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          ..._filteredMealImpacts.map((meal) {
            final rank = _filteredMealImpacts.indexOf(meal) + 1;
            return _buildCompactFoodCard(meal, rank);
          }),
        ],
      ),
    );
  }

  /// Build food ranking card
  Widget _buildFoodRankingCard(MealImpact meal, bool isGood) {
    final color = isGood ? AppTheme.successColor : AppTheme.errorColor;
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
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${meal.glucoseSpike.toInt()}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
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
                  meal.foodName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${meal.beforeGlucose} → ${meal.afterGlucose} mg/dL',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  '${meal.averageCarbs}g carbs • Eaten ${meal.frequency}x',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                ),
              ],
            ),
          ),
          Icon(
            isGood ? Icons.trending_down : Icons.trending_up,
            color: color,
          ),
        ],
      ),
    );
  }

  /// Build compact food card for complete ranking
  Widget _buildCompactFoodCard(MealImpact meal, int rank) {
    final color = _getGlucoseSpikeColor(meal.glucoseSpike);
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
                  meal.foodName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  '${meal.mealType} • ${meal.averageCarbs}g carbs',
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
              '+${meal.glucoseSpike}',
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

  /// Get color based on glucose spike
  Color _getGlucoseSpikeColor(int spike) {
    if (spike <= 30) return AppTheme.successColor;
    if (spike <= 50) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }

  /// Show information dialog
  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Meal Impact'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'This analysis shows how different foods affect your glucose levels.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text('Glucose Spike: The difference between your glucose level before and after eating.'),
              SizedBox(height: 8),
              Text('Good Choices: Foods causing spikes of 30 mg/dL or less.'),
              SizedBox(height: 8),
              Text('Need Caution: Foods causing spikes over 50 mg/dL.'),
              SizedBox(height: 12),
              Text(
                'Use this information to make better food choices and maintain stable glucose levels.',
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

/// Meal Impact Data Model
class MealImpact {
  final String foodName;
  final String mealType;
  final int beforeGlucose;
  final int afterGlucose;
  final int glucoseSpike;
  final int frequency;
  final int averageCarbs;

  MealImpact({
    required this.foodName,
    required this.mealType,
    required this.beforeGlucose,
    required this.afterGlucose,
    required this.glucoseSpike,
    required this.frequency,
    required this.averageCarbs,
  });
}
