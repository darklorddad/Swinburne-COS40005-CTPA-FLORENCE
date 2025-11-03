import 'package:flutter/material.dart';

/// Empty state widget
/// Displays when there's no data to show

class EmptyStateWidget extends StatelessWidget {
  final String message;
  final String? title;
  final IconData? icon;
  final Widget? illustration;
  final VoidCallback? onAction;
  final String? actionText;
  final String? subtitle;
  
  const EmptyStateWidget({
    super.key,
    required this.message,
    this.title,
    this.icon,
    this.illustration,
    this.onAction,
    this.actionText,
    this.subtitle,
  });
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Illustration or icon
            if (illustration != null)
              illustration!
            else
              Icon(
                icon ?? Icons.inbox_outlined,
                size: 80,
                color: Colors.grey.shade400,
              ),
            const SizedBox(height: 24),
            
            // Title
            if (title != null) ...[
              Text(
                title!,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
            ],
            
            // Message
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
              textAlign: TextAlign.center,
            ),
            
            // Subtitle
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
            
            // Action button
            if (onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionText ?? 'Add'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// No data widget - specific for when there's no data
class NoDataWidget extends StatelessWidget {
  final String? message;
  final VoidCallback? onRefresh;
  
  const NoDataWidget({
    super.key,
    this.message,
    this.onRefresh,
  });
  
  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      title: 'No Data',
      message: message ?? 'There\'s no data to display yet.',
      icon: Icons.description_outlined,
      onAction: onRefresh,
      actionText: onRefresh != null ? 'Refresh' : null,
    );
  }
}

/// No search results widget
class NoSearchResultsWidget extends StatelessWidget {
  final String? searchQuery;
  final VoidCallback? onClearSearch;
  
  const NoSearchResultsWidget({
    super.key,
    this.searchQuery,
    this.onClearSearch,
  });
  
  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      title: 'No Results',
      message: searchQuery != null
          ? 'No results found for "$searchQuery"'
          : 'No results found',
      subtitle: 'Try adjusting your search or filters',
      icon: Icons.search_off,
      onAction: onClearSearch,
      actionText: onClearSearch != null ? 'Clear Search' : null,
    );
  }
}

/// No glucose readings widget
class NoGlucoseReadingsWidget extends StatelessWidget {
  final VoidCallback? onAddReading;
  
  const NoGlucoseReadingsWidget({
    super.key,
    this.onAddReading,
  });
  
  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      title: 'No Glucose Readings',
      message: 'Start tracking your glucose levels to see insights and trends.',
      icon: Icons.water_drop_outlined,
      onAction: onAddReading,
      actionText: 'Add Reading',
    );
  }
}

/// No meals logged widget
class NoMealsWidget extends StatelessWidget {
  final VoidCallback? onLogMeal;
  
  const NoMealsWidget({
    super.key,
    this.onLogMeal,
  });
  
  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      title: 'No Meals Logged',
      message: 'Log your meals to track how food affects your glucose levels.',
      icon: Icons.restaurant_outlined,
      onAction: onLogMeal,
      actionText: 'Log Meal',
    );
  }
}

/// No activities widget
class NoActivitiesWidget extends StatelessWidget {
  final VoidCallback? onLogActivity;
  
  const NoActivitiesWidget({
    super.key,
    this.onLogActivity,
  });
  
  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      title: 'No Activities',
      message: 'Track your physical activities to see how they impact your health.',
      icon: Icons.directions_run_outlined,
      onAction: onLogActivity,
      actionText: 'Log Activity',
    );
  }
}

/// No recommendations widget
class NoRecommendationsWidget extends StatelessWidget {
  const NoRecommendationsWidget({super.key});
  
  @override
  Widget build(BuildContext context) {
    return const EmptyStateWidget(
      title: 'No Recommendations',
      message: 'Keep logging your health data to receive personalized recommendations.',
      icon: Icons.lightbulb_outlined,
    );
  }
}

/// No notifications widget
class NoNotificationsWidget extends StatelessWidget {
  const NoNotificationsWidget({super.key});
  
  @override
  Widget build(BuildContext context) {
    return const EmptyStateWidget(
      title: 'No Notifications',
      message: 'You\'re all caught up! You\'ll see notifications here when there are updates.',
      icon: Icons.notifications_none,
    );
  }
}