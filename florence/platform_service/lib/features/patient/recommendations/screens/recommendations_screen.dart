import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../shared/widgets/card_widgets.dart';
import '../../../../config/theme.dart';
import '../../../../core/layout/responsive_layout_system.dart';
import 'recommendation_detail_screen.dart';
import '../services/recommendation_engine.dart';
import '../models/recommendation_models.dart';

/// Health Insights Screen
/// Displays AI-generated health insights with explainability
class RecommendationsScreen extends ConsumerStatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  ConsumerState<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends ConsumerState<RecommendationsScreen> {
  bool _isLoading = false;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    // Initial generation if empty
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndLoadInsights();
    });
  }

  Future<void> _checkAndLoadInsights() async {
    final currentRecs = ref.read(recommendationProvider);
    if (currentRecs.isEmpty) {
      await _generateNewInsights();
    }
  }

  /// Generate new AI insights
  Future<void> _generateNewInsights() async {
    setState(() => _isGenerating = true);

    try {
      await ref.read(recommendationProvider.notifier).generateRecommendations(daysToAnalyze: 7);
      // In a real scenario, we might compare old vs new count here or return new ones from the method
      if (mounted) {
        Helpers.showSuccess(context, 'Analysis complete');
      }
    } catch (e) {
      debugPrint('Error generating insights: $e');
      if (mounted) {
        Helpers.showError(context, 'Failed to generate insights');
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final insights = ref.watch(recommendationProvider);
    final activeInsights = insights.where((r) => r.isActive).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Insights'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: IconButton(
              icon: _isGenerating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.refresh),
              onPressed: _isGenerating
                  ? null
                  : () async {
                      await _generateNewInsights();
                    },
              tooltip: 'Refresh Insights',
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : activeInsights.isEmpty && !_isGenerating
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _generateNewInsights,
                  child: ListView(
                    children: [
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 800),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                ...activeInsights
                                    .map((insight) => _buildInsightCard(insight)),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lightbulb_outline,
              size: 64,
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No insights yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'We need more data to generate insights for you.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _generateNewInsights,
            child: const Text('Analyze Now'),
          ),
        ],
      ),
    );
  }

  /// Build insight card
  Widget _buildInsightCard(HealthRecommendation insight) {
    return BaseCard(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RecommendationDetailScreen(recommendation: insight),
        ),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              _buildCategoryIcon(insight.category),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      insight.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      _formatTime(insight.generatedAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondaryColor,
                          ),
                    ),
                  ],
                ),
              ),
              if (insight.priority == RecommendationPriority.high || 
                  insight.priority == RecommendationPriority.urgent)
                _buildPriorityBadge(insight.priority),
            ],
          ),
          const SizedBox(height: 16),

          // Main Description
          Text(
            insight.description,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),

          // Explainability Section (Why this matters)
          if (insight.explanation != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: AppTheme.primaryBlue),
                      const SizedBox(width: 8),
                      Text(
                        'Why this insight?',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: AppTheme.primaryBlue,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    insight.explanation!.rationale,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (insight.explanation!.expectedImpact.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.trending_up, size: 16, color: AppTheme.primaryGreen),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            insight.explanation!.expectedImpact,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimaryColor,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build category icon
  Widget _buildCategoryIcon(RecommendationCategory category) {
    final config = _getCategoryConfig(category);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: config['color'].withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        config['icon'],
        color: config['color'],
        size: 24,
      ),
    );
  }

  /// Build priority badge
  Widget _buildPriorityBadge(RecommendationPriority priority) {
    final config = _getPriorityConfig(priority);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: config['color'].withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: config['color']),
      ),
      child: Text(
        config['label'],
        style: TextStyle(
          color: config['color'],
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
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
        return {'label': 'IMPORTANT', 'color': AppTheme.warningColor};
      case RecommendationPriority.medium:
        return {'label': 'MEDIUM', 'color': AppTheme.infoColor};
      case RecommendationPriority.low:
        return {'label': 'LOW', 'color': AppTheme.textSecondaryColor};
    }
  }

  /// Format time
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return Formatters.date(time.toLocal());
  }
}
