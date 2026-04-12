import 'package:flutter/material.dart';
import 'package:florence/config/admin_theme.dart';
import 'package:florence/features/admin/core/widgets/admin_sidebar.dart';
import 'package:florence/features/admin/core/widgets/admin_app_bar.dart';

/// Admin Scaffold
/// Main layout wrapper for all admin screens
/// Includes sidebar navigation, app bar, and responsive design
class AdminScaffold extends StatefulWidget {
  /// Page title for app bar
  final String title;

  /// Main content widget
  final Widget body;

  /// Current route for sidebar highlighting
  final String currentRoute;

  /// Whether to show back button in app bar
  final bool showBackButton;

  /// Custom actions for app bar
  final List<Widget>? actions;

  /// Floating action button
  final Widget? floatingActionButton;

  /// Whether to show bottom navigation bar (mobile)
  final bool showBottomNav;

  const AdminScaffold({
    super.key,
    required this.title,
    required this.body,
    required this.currentRoute,
    this.showBackButton = false,
    this.actions,
    this.floatingActionButton,
    this.showBottomNav = false,
  });

  @override
  State<AdminScaffold> createState() => _AdminScaffoldState();
}

class _AdminScaffoldState extends State<AdminScaffold> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _handleNavigation(String route) {
    // Close drawer on mobile
    if (_scaffoldKey.currentState?.isDrawerOpen == true) {
      Navigator.of(context).pop();
    }

    // Navigate to route
    if (route != widget.currentRoute) {
      Navigator.of(context).pushReplacementNamed(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine if we're on mobile/tablet/desktop
        final isMobile = constraints.maxWidth < 600;
        final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 1024;
        final isDesktop = constraints.maxWidth >= 1024;

        return Theme(
          data: AdminTheme.lightTheme,
          child: Scaffold(
            key: _scaffoldKey,
            backgroundColor: AdminTheme.backgroundColor,
            
            // App Bar
            appBar: AdminAppBar(
              title: widget.title,
              showBackButton: widget.showBackButton,
              actions: widget.actions,
              onMenuPressed: isMobile || isTablet
                  ? () {
                      _scaffoldKey.currentState?.openDrawer();
                    }
                  : null,
            ),

            // Sidebar (Desktop: Permanent, Mobile/Tablet: Drawer)
            drawer: (isMobile || isTablet)
                ? Drawer(
                    child: AdminSidebar(
                      currentRoute: widget.currentRoute,
                      onNavigate: _handleNavigation,
                    ),
                  )
                : null,

            // Body
            body: Row(
              children: [
                // Desktop Sidebar (always visible)
                if (isDesktop)
                  AdminSidebar(
                    currentRoute: widget.currentRoute,
                    onNavigate: _handleNavigation,
                  ),

                // Main Content
                Expanded(
                  child: Container(
                    color: AdminTheme.backgroundColor,
                    child: widget.body,
                  ),
                ),
              ],
            ),

            // Floating Action Button
            floatingActionButton: widget.floatingActionButton,

            // Bottom Navigation (Mobile only - if needed)
            bottomNavigationBar: (isMobile && widget.showBottomNav)
                ? _buildBottomNav()
                : null,
          ),
        );
      },
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _getCurrentIndex(),
      onTap: (index) {
        switch (index) {
          case 0:
            _handleNavigation('/admin/dashboard');
            break;
          case 1:
            _handleNavigation('/admin/patients');
            break;
          case 2:
            _handleNavigation('/admin/appointments');
            break;
          case 3:
            _handleNavigation('/admin/users');
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.personal_injury),
          label: 'Patients',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: 'Appointments',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people),
          label: 'Users',
        ),
      ],
    );
  }

  int _getCurrentIndex() {
    if (widget.currentRoute.contains('dashboard')) return 0;
    if (widget.currentRoute.contains('patients')) return 1;
    if (widget.currentRoute.contains('appointments')) return 2;
    if (widget.currentRoute.contains('users')) return 3;
    return 0;
  }
}

/// Simple Admin Page Layout
/// For pages that don't need complex layouts
class AdminPageLayout extends StatelessWidget {
  /// Page title
  final String title;

  /// Optional subtitle
  final String? subtitle;

  /// Content padding
  final EdgeInsets? padding;

  /// Page content
  final Widget child;

  /// Actions (buttons) in the header
  final List<Widget>? actions;

  /// Whether to show a card wrapper
  final bool showCard;

  const AdminPageLayout({
    super.key,
    required this.title,
    this.subtitle,
    this.padding,
    required this.child,
    this.actions,
    this.showCard = true,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: padding ?? const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page Header
          _buildPageHeader(context),

          const SizedBox(height: 24),

          // Content
          if (showCard)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: child,
              ),
            )
          else
            child,
        ],
      ),
    );
  }

  Widget _buildPageHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AdminTheme.textSecondaryColor,
                      ),
                ),
              ],
            ],
          ),
        ),
        if (actions != null && actions!.isNotEmpty) ...[
          const SizedBox(width: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: actions!,
          ),
        ],
      ],
    );
  }
}

/// Responsive Grid Layout
/// Auto-adjusts columns based on screen size
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final int minCrossAxisCount;
  final int maxCrossAxisCount;
  final double minChildWidth;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 16,
    this.runSpacing = 16,
    this.minCrossAxisCount = 1,
    this.maxCrossAxisCount = 4,
    this.minChildWidth = 250,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _calculateCrossAxisCount(constraints.maxWidth);

        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: spacing,
          mainAxisSpacing: runSpacing,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: children,
        );
      },
    );
  }

  int _calculateCrossAxisCount(double width) {
    final count = (width / minChildWidth).floor();
    return count.clamp(minCrossAxisCount, maxCrossAxisCount);
  }
}

/// Stat Card Widget
/// For displaying statistics on dashboard
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 24,
                    ),
                  ),
                  const Spacer(),
                  if (onTap != null)
                    Icon(
                      Icons.arrow_forward,
                      size: 20,
                      color: AdminTheme.textLightColor,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AdminTheme.textSecondaryColor,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AdminTheme.textLightColor,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Loading Overlay
/// Shows loading indicator over content
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      if (message != null) ...[
                        const SizedBox(height: 16),
                        Text(message!),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}