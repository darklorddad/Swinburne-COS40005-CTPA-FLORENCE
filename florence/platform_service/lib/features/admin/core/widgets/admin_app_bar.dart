import 'package:flutter/material.dart';
import 'package:florence/config/admin_theme.dart';
import 'package:florence/features/admin/core/services/admin_auth_service.dart';
import 'package:florence/features/admin/core/services/permission_service.dart';
import 'package:florence/config/routes.dart';
import 'package:florence/main.dart';

/// Admin App Bar
/// Top app bar with search, notifications, and user menu
class AdminAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Page title
  final String title;

  /// Whether to show back button
  final bool showBackButton;

  /// Custom actions (right side of app bar)
  final List<Widget>? actions;

  /// Callback when menu button is pressed (for mobile)
  final VoidCallback? onMenuPressed;

  const AdminAppBar({
    super.key,
    required this.title,
    this.showBackButton = false,
    this.actions,
    this.onMenuPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final permissionService = PermissionService();
    final currentUser = permissionService.currentUser;

    return AppBar(
      elevation: 0,
      backgroundColor: AdminTheme.surfaceColor,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            )
          : (onMenuPressed != null
              ? IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: onMenuPressed,
                )
              : null),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),
      actions: [
        // Custom actions
        if (actions != null) ...actions!,

        // Search
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            // Show search dialog
            _showSearchDialog(context);
          },
          tooltip: 'Search',
        ),

        const SizedBox(width: 8),

        // Notifications
        _NotificationButton(),

        const SizedBox(width: 8),

        // User Menu
        _UserMenu(currentUser: currentUser),

        const SizedBox(width: 16),
      ],
    );
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search patients, users, or records...',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Perform search
              Navigator.pop(context);
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }
}

/// Notification Button with Badge
class _NotificationButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: Get actual notification count from service
    const notificationCount = 3;

    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {
            _showNotificationsMenu(context);
          },
          tooltip: 'Notifications',
        ),
        if (notificationCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AdminTheme.errorColor,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              child: Text(
                notificationCount > 9 ? '9+' : notificationCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  void _showNotificationsMenu(BuildContext context) {
    showMenu<dynamic>(
      context: context,
      position: const RelativeRect.fromLTRB(1000, 70, 0, 0),
      items: <PopupMenuEntry<dynamic>>[
        const PopupMenuItem(
          enabled: false,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Notifications',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const PopupMenuDivider(),
        _buildNotificationItem(
          icon: Icons.person_add,
          title: 'New user registered',
          subtitle: 'Dr. Sarah Williams joined',
          time: '5 min ago',
        ),
        _buildNotificationItem(
          icon: Icons.warning_amber,
          title: 'High glucose alert',
          subtitle: 'Patient John Doe: 285 mg/dL',
          time: '15 min ago',
        ),
        _buildNotificationItem(
          icon: Icons.event,
          title: 'Upcoming appointment',
          subtitle: 'Consultation in 30 minutes',
          time: '30 min ago',
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          child: const Center(
            child: Text(
              'View All Notifications',
              style: TextStyle(
                color: AdminTheme.primaryIndigo,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          onTap: () {
            // Navigate to notifications page
          },
        ),
      ],
    );
  }

  PopupMenuItem _buildNotificationItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
  }) {
    return PopupMenuItem(
      child: SizedBox(
        width: 300,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AdminTheme.infoColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: AdminTheme.infoColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AdminTheme.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 11,
                      color: AdminTheme.textLightColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// User Menu Dropdown
class _UserMenu extends StatelessWidget {
  final dynamic currentUser;

  const _UserMenu({required this.currentUser});

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const SizedBox.shrink();
    }

    // Check for mobile width to conditionally hide text
    final isMobile = MediaQuery.of(context).size.width < 600;

    return PopupMenuButton<String>(
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AdminTheme.backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AdminTheme.borderColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // User Avatar
            CircleAvatar(
              radius: 16,
              backgroundColor: AdminTheme.getRoleColor(currentUser.role.displayName),
              child: Text(
                currentUser.initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // User Info - Hide on mobile
            if (!isMobile) ...[
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    currentUser.firstName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    currentUser.role.displayName,
                    style: TextStyle(
                      fontSize: 11,
                      color: AdminTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.arrow_drop_down,
                size: 20,
              ),
            ],
          ],
        ),
      ),
      itemBuilder: (context) => [
        // User Info Header
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                currentUser.fullName,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                currentUser.email,
                style: TextStyle(
                  fontSize: 12,
                  color: AdminTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 8),
              AdminTheme.getRoleBadge(currentUser.role.displayName),
              if (currentUser.organizationName != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.business,
                      size: 12,
                      color: AdminTheme.textLightColor,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        currentUser.organizationName!,
                        style: TextStyle(
                          fontSize: 11,
                          color: AdminTheme.textLightColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const PopupMenuDivider(),

        // Profile
        const PopupMenuItem(
          value: 'profile',
          child: Row(
            children: [
              Icon(Icons.person_outline, size: 18),
              SizedBox(width: 12),
              Text('My Profile'),
            ],
          ),
        ),

        // Settings
        const PopupMenuItem(
          value: 'settings',
          child: Row(
            children: [
              Icon(Icons.settings_outlined, size: 18),
              SizedBox(width: 12),
              Text('Settings'),
            ],
          ),
        ),

        const PopupMenuDivider(),

        // Logout
        const PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, size: 18, color: AdminTheme.errorColor),
              SizedBox(width: 12),
              Text(
                'Sign Out',
                style: TextStyle(color: AdminTheme.errorColor),
              ),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'profile':
            Navigator.pushNamed(context, '/admin/profile');
            break;
          case 'settings':
            Navigator.pushNamed(context, '/admin/settings');
            break;
          case 'logout':
            _handleLogout(context);
            break;
        }
      },
    );
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // This will trigger the onAuthStateChange listener in app.dart,
              // which will then handle navigating the user back to the main login screen.
              await supabase.auth.signOut();
              if (context.mounted) {
                // We just need to pop the dialog. The auth listener handles the rest.
                Navigator.of(context).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminTheme.errorColor,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
