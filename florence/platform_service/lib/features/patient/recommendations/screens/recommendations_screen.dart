import 'package:flutter/material.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../shared/widgets/card_widgets.dart';
import '../../../../config/theme.dart';
import '../../../../config/routes.dart';
import 'recommendation_detail_screen.dart';
import '../services/recommendation_engine.dart';
import '../models/recommendation_models.dart';

/// Recommendations Feed Screen
/// Displays list of AI-generated health recommendations
class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  bool _isGenerating = false;

  // Recommendation engine
  final RecommendationEngine _engine = RecommendationEngine();

  // Recommendations data
  List<HealthRecommendation> _allRecommendations = [];
  List<HealthRecommendation> _activeRecommendations = [];
  List<HealthRecommendation> _completedRecommendations = [];
  List<HealthRecommendation> _dismissedRecommendations = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadRecommendations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Load recommendations
  Future<void> _loadRecommendations() async {
    setState(() => _isLoading = true);

    try {
      // Get all cached recommendations from engine
      _allRecommendations = _engine.allRecommendations;

      // If no recommendations, generate them
      if (_allRecommendations.isEmpty) {
        await _generateNewRecommendations();
      }

      // Filter by status
      _filterRecommendations();
    } catch (e) {
      debugPrint('Error loading recommendations: $e');
      if (mounted) {
        Helpers.showError(context, 'Failed to load recommendations');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Generate new AI recommendations
  Future<void> _generateNewRecommendations() async {
    setState(() => _isGenerating = true);

    try {
      final newRecs = await _engine.generateRecommendations(daysToAnalyze: 7);

      if (mounted) {
        setState(() {
          _allRecommendations = _engine.allRecommendations;
        });

        if (newRecs.isNotEmpty) {
          Helpers.showSuccess(
            context,
            'Generated ${newRecs.length} new recommendations',
          );
        }
      }
    } catch (e) {
      debugPrint('Error generating recommendations: $e');
      if (mounted) {
        Helpers.showError(context, 'Failed to generate recommendations');
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  /// Filter recommendations by status
  void _filterRecommendations() {
    _activeRecommendations = _allRecommendations
        .where((r) => r.isActive)
        .toList();

    _completedRecommendations = _allRecommendations
        .where((r) => r.status == RecommendationStatus.completed)
        .toList();

    _dismissedRecommendations = _allRecommendations
        .where((r) => r.status == RecommendationStatus.dismissed)
        .toList();
  }

  /// Mark recommendation as done
  Future<void> _markAsDone(HealthRecommendation recommendation) async {
    try {
      _engine.completeRecommendation(recommendation.id);

      setState(() {
        _allRecommendations = _engine.allRecommendations;
        _filterRecommendations();
      });

      Helpers.showSuccess(context, 'Marked as done! Great job!');
    } catch (e) {
      Helpers.showError(context, 'Failed to update recommendation');
    }
  }

  /// Dismiss recommendation
  Future<void> _dismissRecommendation(HealthRecommendation recommendation) async {
    final confirmed = await Helpers.showConfirmDialog(
      context,
      title: 'Dismiss Recommendation',
      message: 'Are you sure you want to dismiss this recommendation?',
    );

    if (confirmed) {
      try {
        _engine.dismissRecommendation(recommendation.id);

        setState(() {
          _allRecommendations = _engine.allRecommendations;
          _filterRecommendations();
        });

        Helpers.showInfo(context, 'Recommendation dismissed');
      } catch (e) {
        Helpers.showError(context, 'Failed to dismiss recommendation');
      }
    }
  }

  /// View recommendation details
  void _viewDetails(HealthRecommendation recommendation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecommendationDetailScreen(
          recommendation: recommendation,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recommendations'),
        actions: [
          // Generate new recommendations button
          IconButton(
            icon: _isGenerating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.auto_awesome),
            onPressed: _isGenerating
                ? null
                : () async {
                    await _generateNewRecommendations();
                    _filterRecommendations();
                    setState(() {});
                  },
            tooltip: 'Generate New Recommendations',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Active'),
                  if (_activeRecommendations.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    _buildCountBadge(_activeRecommendations.length),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Completed'),
                  if (_completedRecommendations.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    _buildCountBadge(_completedRecommendations.length),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Dismissed'),
                  if (_dismissedRecommendations.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    _buildCountBadge(_dismissedRecommendations.length),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Active tab
                _buildRecommendationsList(_activeRecommendations, true),

                // Completed tab
                _buildRecommendationsList(_completedRecommendations, false),

                // Dismissed tab
                _buildRecommendationsList(_dismissedRecommendations, false),
              ],
            ),
    );
  }

  /// Build count badge
  Widget _buildCountBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        count.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Build recommendations list
  Widget _buildRecommendationsList(
    List<HealthRecommendation> recommendations,
    bool showActions,
  ) {
    return Column(
      children: [
        // ALWAYS VISIBLE: Generate New Recommendations Button at the top
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: ElevatedButton.icon(
            onPressed: _isGenerating
                ? null
                : () async {
                    await _generateNewRecommendations();
                    _filterRecommendations();
                    setState(() {});
                  },
            icon: _isGenerating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(_isGenerating
                ? 'Generating Recommendations...'
                : 'Generate New Recommendations'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        // Recommendations List
        Expanded(
          child: recommendations.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadRecommendations,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: recommendations.length,
                    itemBuilder: (context, index) {
                      final recommendation = recommendations[index];
                      return _buildRecommendationCard(recommendation, showActions);
                    },
                  ),
                ),
        ),
      ],
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
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_outline,
              size: 64,
              color: AppTheme.primaryGreen,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'All caught up!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'No recommendations here',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
          ),
        ],
      ),
    );
  }

  /// Build single recommendation card
  Widget _buildRecommendationCard(
    HealthRecommendation recommendation,
    bool showActions,
  ) {
    return Dismissible(
      key: Key(recommendation.id),
      // enabled: showActions,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppTheme.primaryGreen,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerLeft,
        child: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Mark Done',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppTheme.errorColor,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Dismiss',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.close, color: Colors.white),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          _markAsDone(recommendation);
          return false;
        } else {
          return true; // Will trigger dismiss
        }
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          _dismissRecommendation(recommendation);
        }
      },
      child: BaseCard(
        onTap: () => _viewDetails(recommendation),
        margin: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                // Category icon
                _buildCategoryIcon(recommendation.category),
                const SizedBox(width: 12),

                // Title and priority
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              recommendation.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                          _buildPriorityBadge(recommendation.priority),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(recommendation.generatedAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondaryColor,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Description
            Text(
              recommendation.description,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            // Action buttons (only for active)
            if (showActions) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _markAsDone(recommendation),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Mark Done'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryGreen,
                        side: BorderSide(color: AppTheme.primaryGreen),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _dismissRecommendation(recommendation),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Dismiss'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textSecondaryColor,
                        side: BorderSide(color: AppTheme.borderColor),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // Completed/Dismissed info
            if (recommendation.status == RecommendationStatus.completed) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: AppTheme.primaryGreen,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Completed',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ],

            if (recommendation.status == RecommendationStatus.dismissed) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppTheme.textSecondaryColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Dismissed',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondaryColor,
                        ),
                  ),
                ],
              ),
            ],
          ],
        ),
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
        border: Border.all(
          color: config['color'],
          width: 1,
        ),
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
        return {
          'icon': Icons.restaurant,
          'color': AppTheme.mealColor,
        };
      case RecommendationCategory.activity:
        return {
          'icon': Icons.directions_run,
          'color': AppTheme.activityColor,
        };
      case RecommendationCategory.sleep:
        return {
          'icon': Icons.bedtime,
          'color': const Color(0xFF9C27B0),
        };
      case RecommendationCategory.timing:
        return {
          'icon': Icons.access_time,
          'color': AppTheme.primaryBlue,
        };
      case RecommendationCategory.lifestyle:
        return {
          'icon': Icons.self_improvement,
          'color': const Color(0xFF00BCD4),
        };
      case RecommendationCategory.medication:
        return {
          'icon': Icons.medication,
          'color': AppTheme.medicationColor,
        };
    }
  }

  /// Get priority configuration
  Map<String, dynamic> _getPriorityConfig(RecommendationPriority priority) {
    switch (priority) {
      case RecommendationPriority.urgent:
        return {
          'label': 'URGENT',
          'color': const Color(0xFFD32F2F),
        };
      case RecommendationPriority.high:
        return {
          'label': 'HIGH',
          'color': AppTheme.warningColor,
        };
      case RecommendationPriority.medium:
        return {
          'label': 'MEDIUM',
          'color': AppTheme.infoColor,
        };
      case RecommendationPriority.low:
        return {
          'label': 'LOW',
          'color': AppTheme.textSecondaryColor,
        };
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
      return Formatters.date(time);
    }
  }
}