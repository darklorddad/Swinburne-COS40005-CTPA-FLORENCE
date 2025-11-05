/// Pattern Detail Screen for FLORENCE Digital Health Platform
/// Shows detailed information about a detected health pattern

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../config/theme.dart';
import '../../../../core/services/automation/pattern_detection_service.dart';
import '../../core/services/data_ingestion_service.dart';
import '../../core/models/health_data_models.dart';
import '../../../../core/utils/formatters.dart';

/// Detail screen for a specific detected pattern
class PatternDetailScreen extends StatefulWidget {
  final DetectedPattern pattern;

  const PatternDetailScreen({
    super.key,
    required this.pattern,
  });

  @override
  State<PatternDetailScreen> createState() => _PatternDetailScreenState();
}

class _PatternDetailScreenState extends State<PatternDetailScreen> {
  final DataIngestionService _dataService = DataIngestionService();
  List<GlucoseReading> _relatedReadings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPatternData();
  }

  Future<void> _loadPatternData() async {
    setState(() => _isLoading = true);

    try {
      // Get glucose readings related to this pattern
      final allReadings = _dataService.allGlucoseReadings;
      _relatedReadings = allReadings
          .where((r) => widget.pattern.dataPointIds.contains(r.id))
          .toList();

      // Sort by timestamp
      _relatedReadings.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    } catch (e) {
      debugPrint('Error loading pattern data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pattern.typeLabel),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Share pattern details
            },
            tooltip: 'Share',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pattern Overview Card
                  _buildOverviewCard(),
                  const SizedBox(height: 16),

                  // Data Timeline
                  _buildSectionHeader('Data Timeline'),
                  const SizedBox(height: 12),
                  _buildTimelineCard(),
                  const SizedBox(height: 16),

                  // Mini Chart
                  _buildSectionHeader('Glucose Trend'),
                  const SizedBox(height: 12),
                  _buildChartCard(),
                  const SizedBox(height: 16),

                  // AI Explanation
                  _buildSectionHeader('AI Analysis'),
                  const SizedBox(height: 12),
                  _buildAIExplanationCard(),
                  const SizedBox(height: 16),

                  // Action Steps
                  _buildSectionHeader('Recommended Actions'),
                  const SizedBox(height: 12),
                  _buildActionStepsCard(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  /// Build section header
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  /// Build pattern overview card
  Widget _buildOverviewCard() {
    final severityConfig = _getPatternSeverityConfig(widget.pattern.severity);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Severity badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: severityConfig['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: severityConfig['color'],
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        severityConfig['icon'],
                        color: severityConfig['color'],
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        severityConfig['label'],
                        style: TextStyle(
                          color: severityConfig['color'],
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  'Detected ${_formatPatternTime(widget.pattern.detectedAt)}',
                  style: TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Description
            Text(
              widget.pattern.description,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),

            // Metadata
            Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                _buildMetadataItem(
                  Icons.data_usage,
                  '${_relatedReadings.length} readings',
                ),
                _buildMetadataItem(
                  Icons.date_range,
                  _getDateRange(),
                ),
                if (widget.pattern.requiresAction)
                  _buildMetadataItem(
                    Icons.warning_amber,
                    'Action Required',
                    color: AppTheme.warningColor,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build timeline card
  Widget _buildTimelineCard() {
    if (_relatedReadings.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              'No data points available',
              style: TextStyle(color: AppTheme.textSecondaryColor),
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: _relatedReadings.map((reading) {
            return _buildTimelineItem(reading);
          }).toList(),
        ),
      ),
    );
  }

  /// Build timeline item
  Widget _buildTimelineItem(GlucoseReading reading) {
    final isNormal = reading.isNormal;
    final color = isNormal
        ? AppTheme.primaryGreen
        : reading.value > 180
            ? AppTheme.errorColor
            : AppTheme.warningColor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Time indicator
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),

          // Time
          SizedBox(
            width: 80,
            child: Text(
              DateFormat('h:mm a').format(reading.timestamp),
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),

          // Glucose value
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(
              '${reading.value.toStringAsFixed(0)} mg/dL',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Context
          Expanded(
            child: Text(
              reading.context,
              style: TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Build chart card
  Widget _buildChartCard() {
    if (_relatedReadings.isEmpty) {
      return Card(
        child: Container(
          height: 200,
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              'No chart data available',
              style: TextStyle(color: AppTheme.textSecondaryColor),
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 50,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey.shade300,
                    strokeWidth: 1,
                  );
                },
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= 0 &&
                          value.toInt() < _relatedReadings.length) {
                        final reading = _relatedReadings[value.toInt()];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            DateFormat('HH:mm').format(reading.timestamp),
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: (_relatedReadings.length - 1).toDouble(),
              minY: 70,
              maxY: 250,
              lineBarsData: [
                LineChartBarData(
                  spots: _relatedReadings.asMap().entries.map((entry) {
                    return FlSpot(
                      entry.key.toDouble(),
                      entry.value.value,
                    );
                  }).toList(),
                  isCurved: true,
                  color: AppTheme.primaryBlue,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      final reading = _relatedReadings[index];
                      final color = reading.isNormal
                          ? AppTheme.primaryGreen
                          : reading.value > 180
                              ? AppTheme.errorColor
                              : AppTheme.warningColor;

                      return FlDotCirclePainter(
                        radius: 4,
                        color: color,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build AI explanation card
  Widget _buildAIExplanationCard() {
    return Card(
      color: AppTheme.primaryBlue.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.psychology,
                    color: AppTheme.primaryBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'AI-Powered Insights',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Pattern-specific explanation
            Text(
              _getAIExplanation(),
              style: const TextStyle(
                fontSize: 15,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build action steps card
  Widget _buildActionStepsCard() {
    final actions = _getRecommendedActions();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...actions.asMap().entries.map((entry) {
              return _buildActionStep(entry.key + 1, entry.value);
            }),
          ],
        ),
      ),
    );
  }

  /// Build single action step
  Widget _buildActionStep(int number, Map<String, dynamic> action) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step number
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.primaryGreen,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(
                  color: AppTheme.primaryGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Action content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      action['icon'],
                      size: 20,
                      color: AppTheme.primaryGreen,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        action['title'],
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  action['description'],
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondaryColor,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build metadata item
  Widget _buildMetadataItem(IconData icon, String text, {Color? color}) {
    final effectiveColor = color ?? AppTheme.textSecondaryColor;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: effectiveColor),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: effectiveColor,
            fontSize: 13,
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
          'color': AppTheme.errorColor,
          'icon': Icons.error,
          'label': 'Critical',
        };
      case PatternSeverity.high:
        return {
          'color': AppTheme.warningColor,
          'icon': Icons.warning_amber,
          'label': 'High Priority',
        };
      case PatternSeverity.medium:
        return {
          'color': Colors.orange,
          'icon': Icons.info,
          'label': 'Medium Priority',
        };
      case PatternSeverity.low:
        return {
          'color': AppTheme.primaryBlue,
          'icon': Icons.info_outline,
          'label': 'Low Priority',
        };
    }
  }

  /// Get date range string
  String _getDateRange() {
    if (_relatedReadings.isEmpty) return 'No data';
    if (_relatedReadings.length == 1) {
      return DateFormat('MMM d, h:mm a').format(_relatedReadings.first.timestamp);
    }

    final first = _relatedReadings.first.timestamp;
    final last = _relatedReadings.last.timestamp;

    if (first.day == last.day) {
      return '${DateFormat('MMM d').format(first)}, ${DateFormat('h:mm a').format(first)} - ${DateFormat('h:mm a').format(last)}';
    } else {
      return '${DateFormat('MMM d').format(first)} - ${DateFormat('MMM d').format(last)}';
    }
  }

  /// Format pattern detection time
  String _formatPatternTime(DateTime time) {
    return Formatters.timeAgo(time);
  }

  /// Get AI explanation based on pattern type
  String _getAIExplanation() {
    switch (widget.pattern.type) {
      case PatternType.glucoseSpike:
        return 'Our AI detected a rapid increase in your glucose levels. This spike pattern typically occurs after consuming high-carb meals or during periods of stress. Understanding the timing and triggers of these spikes can help you make better dietary choices.';

      case PatternType.glucoseDrop:
        return 'A concerning drop in glucose levels was identified by our AI. This pattern may indicate excessive insulin, inadequate food intake, or increased physical activity. It\'s important to monitor for symptoms of hypoglycemia and take preventive action.';

      case PatternType.postMealSpike:
        return 'Your glucose levels show elevated post-meal readings. Our AI analysis suggests this is related to meal composition and timing. Managing carbohydrate intake and meal spacing can help reduce these spikes.';

      case PatternType.consecutiveHigh:
        return 'Our AI detected multiple consecutive high readings, indicating sustained hyperglycemia. This pattern suggests the need to review your medication regimen, dietary habits, and physical activity level with your healthcare provider.';

      case PatternType.highVariability:
        return 'Your glucose levels show significant fluctuations throughout the day. Our AI identifies this as high variability, which can be more harmful than consistently elevated levels. Focus on regular meal timing, consistent carb portions, and stress management.';

      case PatternType.lowActivity:
        return 'Based on your activity data, our AI noticed decreased physical movement correlating with this glucose pattern. Regular physical activity is crucial for glucose management. Even small increases in daily movement can make a significant difference.';

      case PatternType.missedMedication:
        return 'Our AI detected potential medication non-adherence based on glucose patterns and logged medication data. Consistent medication timing is essential for stable glucose control. Consider setting reminders or using a pill organizer.';

      default:
        return 'Our AI has analyzed your glucose data and identified this pattern as noteworthy. Understanding your unique patterns helps you make informed decisions about your diabetes management.';
    }
  }

  /// Get recommended actions based on pattern
  List<Map<String, dynamic>> _getRecommendedActions() {
    switch (widget.pattern.type) {
      case PatternType.glucoseSpike:
        return [
          {
            'icon': Icons.restaurant,
            'title': 'Review Recent Meals',
            'description':
                'Identify high-carb foods that triggered the spike and consider portion control or healthier alternatives.',
          },
          {
            'icon': Icons.directions_walk,
            'title': 'Take a Short Walk',
            'description':
                'A 10-15 minute walk after meals can help lower blood glucose levels naturally.',
          },
          {
            'icon': Icons.water_drop,
            'title': 'Stay Hydrated',
            'description':
                'Drink plenty of water to help your body flush out excess glucose.',
          },
        ];

      case PatternType.glucoseDrop:
        return [
          {
            'icon': Icons.fastfood,
            'title': 'Have a Fast-Acting Carb',
            'description':
                'If feeling symptoms, consume 15g of fast-acting carbs like glucose tablets or juice.',
          },
          {
            'icon': Icons.access_time,
            'title': 'Check Meal Timing',
            'description':
                'Ensure you\'re eating regular meals and snacks to prevent drops between meals.',
          },
          {
            'icon': Icons.medical_services,
            'title': 'Review Medication',
            'description':
                'Discuss with your doctor if you experience frequent lows - medication adjustment may be needed.',
          },
        ];

      case PatternType.consecutiveHigh:
        return [
          {
            'icon': Icons.phone_in_talk,
            'title': 'Contact Healthcare Provider',
            'description':
                'Sustained high readings require professional evaluation - schedule an appointment soon.',
          },
          {
            'icon': Icons.local_drink,
            'title': 'Increase Water Intake',
            'description':
                'Drink more water throughout the day to help manage elevated glucose levels.',
          },
          {
            'icon': Icons.fitness_center,
            'title': 'Increase Physical Activity',
            'description':
                'Add more movement to your day - even light activity can help lower glucose.',
          },
        ];

      case PatternType.lowActivity:
        return [
          {
            'icon': Icons.directions_walk,
            'title': 'Start Small',
            'description':
                'Begin with 10-minute walks after meals and gradually increase duration.',
          },
          {
            'icon': Icons.alarm,
            'title': 'Set Movement Reminders',
            'description':
                'Schedule regular breaks to stand and move throughout the day.',
          },
          {
            'icon': Icons.group,
            'title': 'Find an Activity Buddy',
            'description':
                'Exercise with a friend or family member for motivation and accountability.',
          },
        ];

      default:
        return [
          {
            'icon': Icons.monitor_heart,
            'title': 'Continue Monitoring',
            'description':
                'Keep tracking your glucose levels to identify additional patterns.',
          },
          {
            'icon': Icons.book,
            'title': 'Log Related Factors',
            'description':
                'Record meals, activities, and medications to understand pattern triggers.',
          },
          {
            'icon': Icons.support_agent,
            'title': 'Discuss with Care Team',
            'description':
                'Share this pattern information with your healthcare provider at your next visit.',
          },
        ];
    }
  }
}
