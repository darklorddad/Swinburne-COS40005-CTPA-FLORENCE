import 'package:flutter/material.dart';
import '../../../../shared/widgets/card_widgets.dart';
import '../../../../config/theme.dart';

/// Upcoming Reminders Card
/// Displays upcoming health reminders and tasks
class UpcomingRemindersCard extends StatelessWidget {
  final List<Map<String, dynamic>> reminders;
  final VoidCallback? onViewAll;
  
  const UpcomingRemindersCard({
    super.key,
    required this.reminders,
    this.onViewAll,
  });
  
  @override
  Widget build(BuildContext context) {
    if (reminders.isEmpty) {
      return BaseCard(
        child: Column(
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 48,
              color: AppTheme.successColor,
            ),
            const SizedBox(height: 12),
            Text(
              'All caught up!',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'No upcoming reminders',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
            ),
          ],
        ),
      );
    }
    
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.notifications_outlined,
                    size: 20,
                    color: AppTheme.primaryBlue,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Upcoming',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              if (onViewAll != null)
                TextButton(
                  onPressed: onViewAll,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'View all',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Reminders list
          ...reminders.take(3).map((reminder) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ReminderItem(
                icon: reminder['icon'] as IconData,
                title: reminder['title'] as String,
                time: reminder['time'] as String,
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Single reminder item
class _ReminderItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String time;
  
  const _ReminderItem({
    required this.icon,
    required this.title,
    required this.time,
  });
  
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Icon
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: AppTheme.primaryBlue,
          ),
        ),
        const SizedBox(width: 12),
        
        // Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 12,
                    color: AppTheme.textSecondaryColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    time,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondaryColor,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Arrow
        Icon(
          Icons.chevron_right,
          size: 20,
          color: AppTheme.textSecondaryColor,
        ),
      ],
    );
  }
}