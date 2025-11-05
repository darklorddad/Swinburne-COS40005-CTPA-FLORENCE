/// Notifications Screen for FLORENCE Digital Health Platform
/// Displays all notifications with filtering and actions

import 'package:flutter/material.dart';
import '../../../../core/services/notifications/notification_service.dart';
import '../../../../core/services/notifications/notification_models.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../config/theme.dart';

/// Notifications screen showing all notifications
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  NotificationType? _selectedFilter;

  @override
  void initState() {
    super.initState();
    _notificationService.addListener(_onNotificationsChanged);
  }

  @override
  void dispose() {
    _notificationService.removeListener(_onNotificationsChanged);
    super.dispose();
  }

  void _onNotificationsChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final allNotifications = _notificationService.allNotifications;
    final filteredNotifications = _selectedFilter == null
        ? allNotifications
        : allNotifications
            .where((n) => n.type == _selectedFilter)
            .toList();

    // Group notifications by time
    final today = <HealthNotification>[];
    final yesterday = <HealthNotification>[];
    final thisWeek = <HealthNotification>[];
    final older = <HealthNotification>[];

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));
    final weekStart = todayStart.subtract(const Duration(days: 7));

    for (var notification in filteredNotifications) {
      if (notification.createdAt.isAfter(todayStart)) {
        today.add(notification);
      } else if (notification.createdAt.isAfter(yesterdayStart)) {
        yesterday.add(notification);
      } else if (notification.createdAt.isAfter(weekStart)) {
        thisWeek.add(notification);
      } else {
        older.add(notification);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          // Filter dropdown
          PopupMenuButton<NotificationType?>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter',
            onSelected: (type) {
              setState(() => _selectedFilter = type);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text('All Notifications'),
              ),
              const PopupMenuDivider(),
              ...NotificationType.values.map((type) => PopupMenuItem(
                    value: type,
                    child: Row(
                      children: [
                        _getNotificationIcon(type, 20),
                        const SizedBox(width: 12),
                        Text(_getNotificationTypeName(type)),
                      ],
                    ),
                  )),
            ],
          ),
          // Mark all as read
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: () {
              _notificationService.markAllAsRead();
              setState(() {});
            },
            tooltip: 'Mark all as read',
          ),
          // Clear all
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () async {
              final confirmed = await _showConfirmDialog(
                'Clear All Notifications',
                'Are you sure you want to clear all notifications?',
              );
              if (confirmed) {
                _notificationService.clearAll();
                setState(() {});
              }
            },
            tooltip: 'Clear all',
          ),
        ],
      ),
      body: filteredNotifications.isEmpty
          ? _buildEmptyState()
          : ListView(
              children: [
                if (today.isNotEmpty) _buildGroup('Today', today),
                if (yesterday.isNotEmpty) _buildGroup('Yesterday', yesterday),
                if (thisWeek.isNotEmpty) _buildGroup('This Week', thisWeek),
                if (older.isNotEmpty) _buildGroup('Older', older),
              ],
            ),
    );
  }

  /// Build notification group
  Widget _buildGroup(String title, List<HealthNotification> notifications) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ),
        ...notifications.map((n) => _buildNotificationCard(n)),
      ],
    );
  }

  /// Build notification card
  Widget _buildNotificationCard(HealthNotification notification) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: AppTheme.errorColor,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        _notificationService.deleteNotification(notification.id);
        setState(() {});
      },
      child: InkWell(
        onTap: () {
          // Mark as read
          if (!notification.isRead) {
            _notificationService.markAsRead(notification.id);
            setState(() {});
          }

          // Navigate if action URL exists
          if (notification.actionUrl != null) {
            Navigator.pop(context);
            Navigator.pushNamed(context, notification.actionUrl!);
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: notification.isRead
                ? Colors.transparent
                : _getNotificationColor(notification.type).withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: notification.isRead
                  ? Colors.grey.shade300
                  : _getNotificationColor(notification.type).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getNotificationColor(notification.type)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _getNotificationIcon(notification.type, 24),
                ),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: notification.isRead
                              ? FontWeight.normal
                              : FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: AppTheme.textSecondaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            Formatters.timeAgo(notification.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                          if (notification.priority == NotificationPriority.critical) ...[
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.errorColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'URGENT',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Unread indicator
                if (!notification.isRead)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _getNotificationColor(notification.type),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
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
          Icon(
            Icons.notifications_off_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            _selectedFilter == null
                ? 'No notifications'
                : 'No ${_getNotificationTypeName(_selectedFilter!).toLowerCase()}',
            style: TextStyle(
              fontSize: 18,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Get notification icon
  Icon _getNotificationIcon(NotificationType type, double size) {
    IconData iconData;
    Color color = _getNotificationColor(type);

    switch (type) {
      case NotificationType.alert:
        iconData = Icons.warning;
      case NotificationType.reminder:
        iconData = Icons.alarm;
      case NotificationType.educational:
        iconData = Icons.school;
      case NotificationType.motivational:
        iconData = Icons.emoji_events;
      case NotificationType.summary:
        iconData = Icons.assessment;
      case NotificationType.achievement:
        iconData = Icons.star;
    }

    return Icon(iconData, size: size, color: color);
  }

  /// Get notification color
  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.alert:
        return AppTheme.errorColor;
      case NotificationType.reminder:
        return AppTheme.warningColor;
      case NotificationType.educational:
        return AppTheme.primaryBlue;
      case NotificationType.motivational:
        return AppTheme.primaryGreen;
      case NotificationType.summary:
        return AppTheme.accentPurple;
      case NotificationType.achievement:
        return AppTheme.accentGold;
    }
  }

  /// Get notification type name
  String _getNotificationTypeName(NotificationType type) {
    switch (type) {
      case NotificationType.alert:
        return 'Alerts';
      case NotificationType.reminder:
        return 'Reminders';
      case NotificationType.educational:
        return 'Educational';
      case NotificationType.motivational:
        return 'Motivational';
      case NotificationType.summary:
        return 'Summaries';
      case NotificationType.achievement:
        return 'Achievements';
    }
  }

  /// Show confirm dialog
  Future<bool> _showConfirmDialog(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
