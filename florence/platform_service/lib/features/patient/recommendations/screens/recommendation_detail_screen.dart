import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:florence/core/utils/formatters.dart';
import 'package:florence/core/utils/helpers.dart';
import 'package:florence/shared/widgets/card_widgets.dart';
import 'package:florence/shared/widgets/button_widgets.dart';
import 'package:florence/config/theme.dart';
import 'package:florence/config/routes.dart';
import 'package:florence/features/patient/recommendations/models/recommendation_models.dart';

/// Recommendation Detail Screen
/// Shows full details of a recommendation with explanation and action steps
class RecommendationDetailScreen extends StatefulWidget {
  final HealthRecommendation recommendation;

  const RecommendationDetailScreen({
    super.key,
    required this.recommendation,
  });

  @override
  State<RecommendationDetailScreen> createState() =>
      _RecommendationDetailScreenState();
}

class _RecommendationDetailScreenState
    extends State<RecommendationDetailScreen> {
  bool _isLoading = false;

  // Related data
  final List<Map<String, dynamic>> _relatedData = [];

  /// Mark as done
  Future<void> _markAsDone() async {
    setState(() => _isLoading = true);

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        Helpers.showSuccess(context, 'Marked as done! Great job! 🎉');
        AppRoutes.pop(context);
      }
    } catch (e) {
      if (mounted) {
        Helpers.showError(context, 'Failed to mark as done');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Dismiss recommendation
  Future<void> _dismiss() async {
    final confirmed = await Helpers.showConfirmDialog(
      context,
      title: 'Dismiss Recommendation',
      message: 'Are you sure you want to dismiss this recommendation?',
    );

    if (!confirmed) return;

    setState(() => _isLoading = true);

    try {
      
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        Helpers.showInfo(context, 'Recommendation dismissed');
        AppRoutes.pop(context);
      }
    } catch (e) {
      if (mounted) {
        Helpers.showError(context, 'Failed to dismiss');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Snooze for 1 day
  Future<void> _snooze() async {
    setState(() => _isLoading = true);

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        Helpers.showSuccess(context, 'Snoozed for 1 day');
        AppRoutes.pop(context);
      }
    } catch (e) {
      if (mounted) {
        Helpers.showError(context, 'Failed to snooze');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final recommendation = widget.recommendation;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recommendation'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header section
                _buildHeader(recommendation),

                // Why This Matters section
                _buildWhyThisMattersSection(recommendation),

                // Action Steps section
                _buildActionStepsSection(recommendation),

                // Related Data section
                _buildRelatedDataSection(),

                const SizedBox(height: 100), // Space for fixed buttons
              ],
            ),
          ),
        ),
      ),
      // Fixed action buttons at bottom
      bottomNavigationBar: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: _buildActionButtons(),
        ),
      ),
    );
  }

  /// Build header section
  Widget _buildHeader(HealthRecommendation recommendation) {
    final categoryConfig = _getCategoryConfig(recommendation.category);
    final priorityConfig = _getPriorityConfig(recommendation.priority);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            categoryConfig['color'].withValues(alpha: 0.1),
            categoryConfig['color'].withValues(alpha: 0.05),
          ],
        ),
      ),
      child: Column(
        children: [
          // Category icon (large)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: categoryConfig['color'].withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              categoryConfig['icon'],
              size: 48,
              color: categoryConfig['color'],
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            recommendation.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Priority badge and date
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: priorityConfig['color'].withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: priorityConfig['color'],
                    width: 1.5,
                  ),
                ),
                child: Text(
                  priorityConfig['label'],
                  style: TextStyle(
                    color: priorityConfig['color'],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Generated ${_formatTime(recommendation.generatedAt)}',
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

  /// Build Why This Matters section
  Widget _buildWhyThisMattersSection(HealthRecommendation recommendation) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: BaseCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 24,
                  color: AppTheme.infoColor,
                ),
                const SizedBox(width: 12),
                Text(
                  'Why This Matters',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Full explanation
            Text(
              _getFullExplanation(recommendation),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.6,
                  ),
            ),

            const SizedBox(height: 20),

            // Supporting chart (mini)
            _buildMiniChart(recommendation),
          ],
        ),
      ),
    );
  }

  /// Build Action Steps section
  Widget _buildActionStepsSection(HealthRecommendation recommendation) {
    final steps = _getActionSteps(recommendation);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: BaseCard(
        // backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.lightbulb_outline,
                    size: 24,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Action Steps',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryBlue,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Step-by-step instructions
            ...steps.asMap().entries.map((entry) {
              final index = entry.key;
              final step = entry.value;

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
                        color: AppTheme.primaryBlue,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Step text
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          step,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    height: 1.5,
                                  ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// Build Related Data section
  Widget _buildRelatedDataSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: BaseCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics_outlined,
                  size: 24,
                  color: AppTheme.textSecondaryColor,
                ),
                const SizedBox(width: 12),
                Text(
                  'This recommendation is based on:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // List of data points
            ..._relatedData.map((data) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _getDataIcon(data['type']),
                      size: 20,
                      color: AppTheme.primaryBlue,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                data['type'],
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              Text(
                                data['value'],
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: AppTheme.primaryBlue,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                // Ensure timestamp is treated as DateTime before converting
                                Formatters.dateTime((data['timestamp'] as DateTime).toLocal()),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppTheme.textSecondaryColor,
                                    ),
                              ),
                              Text(
                                data['note'],
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppTheme.textSecondaryColor,
                                      fontStyle: FontStyle.italic,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// Build mini chart
  Widget _buildMiniChart(HealthRecommendation recommendation) {
    // TODO: Fetch real data for the mini chart
    final spots = <FlSpot>[];

    if (spots.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your dinner glucose pattern',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                minY: 80,
                maxY: 220,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppTheme.primaryBlue,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 3,
                          color: spot.y > 180
                              ? AppTheme.glucoseHigh
                              : AppTheme.primaryBlue,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build action buttons
  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Mark as Done button (primary)
            PrimaryButton(
              text: 'Mark as Done',
              onPressed: _isLoading ? null : _markAsDone,
              isLoading: _isLoading,
              width: double.infinity,
            ),
            const SizedBox(height: 8),

            // Secondary actions row
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _isLoading ? null : _dismiss,
                    child: const Text('Dismiss'),
                  ),
                ),
                Container(
                  width: 1,
                  height: 20,
                  color: AppTheme.borderColor,
                ),
                Expanded(
                  child: TextButton(
                    onPressed: _isLoading ? null : _snooze,
                    child: const Text('Snooze for 1 day'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Get full explanation based on recommendation
  String _getFullExplanation(HealthRecommendation recommendation) {
    switch (recommendation.category) {
      case RecommendationCategory.meal:
        return 'Based on your glucose data from the past week, we\'ve noticed a pattern of elevated blood glucose levels following dinner. Your post-dinner readings have been averaging 195 mg/dL, which is significantly above your target range of 70-180 mg/dL.\n\nHigh-carbohydrate meals, especially those consumed later in the evening, can lead to prolonged glucose elevation and affect your overnight levels. Reducing your carb intake at dinner can help stabilize your glucose and improve your overall diabetes management.';

      case RecommendationCategory.activity:
        return 'Our analysis shows that on days when you walk in the morning, your glucose levels remain more stable throughout the day. Morning exercise has several benefits: it improves insulin sensitivity, helps lower fasting glucose, and sets a positive tone for the rest of the day.\n\nConsistent morning activity has been shown to reduce glucose variability by up to 20% and can significantly improve long-term diabetes outcomes. Your data specifically shows a 15% improvement in time-in-range on days you exercise in the morning.';

      case RecommendationCategory.timing:
        return 'Your glucose tracking reveals that eating lunch earlier in the day leads to better post-meal glucose control. When you eat before 1 PM, your average post-lunch glucose is 135 mg/dL compared to 165 mg/dL when eating after 1 PM.\n\nThis pattern suggests your body\'s insulin sensitivity is higher earlier in the day, which is common. Shifting your meal timing to align with your body\'s natural rhythms can significantly improve your glucose management without changing what you eat.';

      case RecommendationCategory.sleep:
        return 'Your overnight glucose data shows significant improvement when you maintain a consistent bedtime around 10 PM. Irregular sleep patterns can disrupt your body\'s hormonal balance, affecting insulin sensitivity and glucose regulation.\n\nConsistent sleep helps regulate cortisol and growth hormone, both of which impact blood glucose. Your data shows 15% better overnight glucose stability when you sleep by 10 PM compared to later bedtimes.';

      case RecommendationCategory.lifestyle:
        return 'We\'ve observed that your glucose readings are consistently better on days when you log water intake, suggesting proper hydration. Adequate hydration helps your kidneys flush out excess glucose and improves insulin sensitivity.\n\nDehydration can cause glucose to become more concentrated in your bloodstream, leading to higher readings. Your well-hydrated days show an average of 8% lower glucose levels compared to days with less water intake.';

      case RecommendationCategory.medication:
        return 'Medication adherence is crucial for effective diabetes management. Setting a consistent reminder can help ensure you take your medication at the optimal time, maximizing its effectiveness.\n\nYour medication works best when taken at regular intervals. Consistent timing helps maintain stable glucose levels and reduces the risk of both highs and lows.';

      default:
        return recommendation.description;
    }
  }

  /// Get action steps based on recommendation
  List<String> _getActionSteps(HealthRecommendation recommendation) {
    switch (recommendation.category) {
      case RecommendationCategory.meal:
        return [
          'Reduce your carbohydrate portion at dinner by 25-30%. For example, if you usually have 1 cup of rice, try reducing to ¾ cup.',
          'Add more non-starchy vegetables to fill your plate. Aim for half your plate to be vegetables like broccoli, spinach, or cauliflower.',
          'Include lean protein (chicken, fish, tofu) with every dinner to slow down glucose absorption.',
          'Consider eating dinner at least 3 hours before bedtime to allow glucose levels to stabilize.',
          'Track your post-dinner glucose 2 hours after eating to monitor improvements.',
        ];

      case RecommendationCategory.activity:
        return [
          'Set an alarm for 8:00 AM daily as a reminder to start your morning walk.',
          'Start with a 20-minute walk at a comfortable pace. You don\'t need to go fast - consistency matters more than intensity.',
          'Walk outside if weather permits, or use a treadmill as an alternative. Indoor walking videos work too!',
          'Check your glucose before and after walking to see the immediate impact (usually drops 20-30 mg/dL).',
          'Gradually increase to 30-40 minutes as it becomes part of your routine.',
        ];

      case RecommendationCategory.timing:
        return [
          'Gradually shift your lunch time earlier by 15 minutes each week until you\'re eating before 1 PM.',
          'Prepare your lunch the night before or in the morning to remove barriers to eating earlier.',
          'If you work, consider adjusting your lunch break schedule with your employer or team.',
          'Log your post-lunch glucose at 2 hours to track the improvement from this change.',
          'Aim for consistency - try to eat lunch at the same time every day.',
        ];

      case RecommendationCategory.sleep:
        return [
          'Set a reminder at 9:30 PM to begin your bedtime routine.',
          'Create a relaxing wind-down routine: dim lights, avoid screens, read or listen to calming music.',
          'Keep your bedroom cool (65-68°F) and dark for optimal sleep quality.',
          'Avoid large meals or high-carb snacks 3 hours before bed to prevent overnight glucose spikes.',
          'Check your morning fasting glucose to see improvements from consistent sleep timing.',
        ];

      case RecommendationCategory.lifestyle:
        return [
          'Start your day by drinking a full glass (8 oz) of water upon waking.',
          'Carry a reusable water bottle with you throughout the day as a visual reminder.',
          'Set hourly reminders on your phone to take a few sips of water.',
          'Aim for at least 8 glasses (64 oz) of water daily, more if you\'re active or in hot weather.',
          'Use the app\'s water logging feature to track your intake and see the correlation with your glucose levels.',
        ];

      case RecommendationCategory.medication:
        return [
          'Set a daily alarm on your phone for 7:00 PM as a medication reminder.',
          'Place your medication in a visible location where you\'ll see it at the scheduled time.',
          'Use a pill organizer to prepare your medication for the week ahead.',
          'Log your medication intake in the app to help track adherence.',
          'If you miss a dose, consult your healthcare provider about what to do - don\'t double up without guidance.',
        ];

      default:
        return [
          'Review this recommendation carefully.',
          'Start implementing the suggested changes gradually.',
          'Track your progress in the app.',
          'Consult with your healthcare provider if you have questions.',
        ];
    }
  }

  /// Get category configuration
  Map<String, dynamic> _getCategoryConfig(RecommendationCategory category) {
    switch (category) {
      case RecommendationCategory.meal:
        return {'icon': Icons.restaurant, 'color': AppTheme.mealColor};
      case RecommendationCategory.activity:
        return {'icon': Icons.directions_run, 'color': AppTheme.activityColor};
      case RecommendationCategory.sleep:
        return {'icon': Icons.bedtime, 'color': const Color(0xFF9C27B0)};
      case RecommendationCategory.timing:
        return {'icon': Icons.access_time, 'color': AppTheme.primaryBlue};
      case RecommendationCategory.lifestyle:
        return {'icon': Icons.self_improvement, 'color': const Color(0xFF00BCD4)};
      case RecommendationCategory.medication:
        return {'icon': Icons.medication, 'color': AppTheme.medicationColor};
    }
  }

  /// Get priority configuration
  Map<String, dynamic> _getPriorityConfig(RecommendationPriority priority) {
    switch (priority) {
      case RecommendationPriority.urgent:
        return {'label': 'URGENT', 'color': const Color(0xFFD32F2F)};
      case RecommendationPriority.high:
        return {'label': 'HIGH', 'color': AppTheme.warningColor};
      case RecommendationPriority.medium:
        return {'label': 'MEDIUM', 'color': AppTheme.infoColor};
      case RecommendationPriority.low:
        return {'label': 'LOW', 'color': AppTheme.textSecondaryColor};
    }
  }

  /// Get data icon
  IconData _getDataIcon(String type) {
    switch (type) {
      case 'Glucose Reading':
        return Icons.water_drop;
      case 'Meal Log':
        return Icons.restaurant;
      case 'Activity':
        return Icons.directions_run;
      case 'Medication':
        return Icons.medication;
      default:
        return Icons.analytics;
    }
  }

  /// Format time
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return Formatters.date(time.toLocal());
    }
  }
}
