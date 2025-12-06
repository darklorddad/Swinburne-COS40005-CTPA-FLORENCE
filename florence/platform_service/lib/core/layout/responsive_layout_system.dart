// ============================================================================
// RESPONSIVE LAYOUT SYSTEM FOR FLORENCE
// ============================================================================
// This file contains all the utilities needed for responsive & adaptive design

import 'package:flutter/material.dart';

// ============================================================================
// 1. BREAKPOINTS
// ============================================================================

class Breakpoints {
  // Mobile: < 600px
  static const double mobile = 600;
  
  // Tablet: 600px - 1024px
  static const double tablet = 1024;
  
  // Desktop: > 1024px
  static const double desktop = 1024;
  
  // Large Desktop: > 1440px
  static const double largeDesktop = 1440;
}

// ============================================================================
// 2. DEVICE TYPE ENUM
// ============================================================================

enum DeviceType {
  mobile,
  tablet,
  desktop,
  largeDesktop,
}

// ============================================================================
// 3. RESPONSIVE HELPER EXTENSION
// ============================================================================

extension ResponsiveExtension on BuildContext {
  /// Get current screen width
  double get screenWidth => MediaQuery.of(this).size.width;
  
  /// Get current screen height
  double get screenHeight => MediaQuery.of(this).size.height;
  
  /// Check if mobile
  bool get isMobile => screenWidth < Breakpoints.mobile;
  
  /// Check if tablet
  bool get isTablet => screenWidth >= Breakpoints.mobile && screenWidth < Breakpoints.desktop;
  
  /// Check if desktop
  bool get isDesktop => screenWidth >= Breakpoints.desktop;
  
  /// Check if large desktop
  bool get isLargeDesktop => screenWidth >= Breakpoints.largeDesktop;
  
  /// Get device type
  DeviceType get deviceType {
    if (screenWidth >= Breakpoints.largeDesktop) return DeviceType.largeDesktop;
    if (screenWidth >= Breakpoints.desktop) return DeviceType.desktop;
    if (screenWidth >= Breakpoints.mobile) return DeviceType.tablet;
    return DeviceType.mobile;
  }
  
  /// Get responsive value based on screen size
  T responsive<T>({
    required T mobile,
    T? tablet,
    T? desktop,
    T? largeDesktop,
  }) {
    if (isLargeDesktop && largeDesktop != null) return largeDesktop;
    if (isDesktop && desktop != null) return desktop;
    if (isTablet && tablet != null) return tablet;
    return mobile;
  }
}

// ============================================================================
// 4. RESPONSIVE PADDING
// ============================================================================

class ResponsivePadding {
  static EdgeInsets page(BuildContext context) {
    return EdgeInsets.symmetric(
      horizontal: context.responsive(
        mobile: 16.0,
        tablet: 24.0,
        desktop: 32.0,
        largeDesktop: 48.0,
      ),
      vertical: context.responsive(
        mobile: 16.0,
        tablet: 20.0,
        desktop: 24.0,
      ),
    );
  }
  
  static EdgeInsets card(BuildContext context) {
    return EdgeInsets.all(
      context.responsive(
        mobile: 16.0,
        tablet: 20.0,
        desktop: 24.0,
      ),
    );
  }
  
  static EdgeInsets section(BuildContext context) {
    return EdgeInsets.only(
      bottom: context.responsive(
        mobile: 24.0,
        tablet: 32.0,
        desktop: 40.0,
      ),
    );
  }
}

// ============================================================================
// 5. RESPONSIVE SPACING
// ============================================================================

class ResponsiveSpacing {
  static double small(BuildContext context) {
    return context.responsive(
      mobile: 8.0,
      tablet: 12.0,
      desktop: 16.0,
    );
  }
  
  static double medium(BuildContext context) {
    return context.responsive(
      mobile: 16.0,
      tablet: 20.0,
      desktop: 24.0,
    );
  }
  
  static double large(BuildContext context) {
    return context.responsive(
      mobile: 24.0,
      tablet: 32.0,
      desktop: 40.0,
    );
  }
}

// ============================================================================
// 6. RESPONSIVE GRID
// ============================================================================

class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 16.0,
    this.runSpacing = 16.0,
  });
  
  @override
  Widget build(BuildContext context) {
    // Determine number of columns based on screen size
    final crossAxisCount = context.responsive(
      mobile: 1,
      tablet: 2,
      desktop: 4,
    );
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: runSpacing,
        childAspectRatio: context.responsive(
          mobile: 2.5,
          tablet: 2.0,
          desktop: 2.0,
        ),
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}

// ============================================================================
// 7. RESPONSIVE WRAPPER (Main Container)
// ============================================================================

class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  final bool showNavigationRail;
  final int? currentIndex;
  final ValueChanged<int>? onNavigationChanged;
  
  const ResponsiveWrapper({
    super.key,
    required this.child,
    this.showNavigationRail = true,
    this.currentIndex,
    this.onNavigationChanged,
  });
  
  @override
  Widget build(BuildContext context) {
    // On desktop, show side navigation rail
    if (context.isDesktop && showNavigationRail) {
      return Row(
        children: [
          // Side Navigation Rail
          NavigationRail(
            selectedIndex: currentIndex ?? 0,
            onDestinationSelected: onNavigationChanged,
            labelType: NavigationRailLabelType.all,
            backgroundColor: Colors.white,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.show_chart_outlined),
                selectedIcon: Icon(Icons.show_chart),
                label: Text('Trends'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.add_circle_outline),
                selectedIcon: Icon(Icons.add_circle),
                label: Text('Log Data'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.chat_outlined),
                selectedIcon: Icon(Icons.chat),
                label: Text('AI Assistant'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: Text('Profile'),
              ),
            ],
          ),
          
          const VerticalDivider(thickness: 1, width: 1),
          
          // Main Content Area with max width
          Expanded(
            child: _ContentArea(child: child),
          ),
        ],
      );
    }
    
    // On mobile/tablet, just wrap content
    return _ContentArea(child: child);
  }
}

// ============================================================================
// 8. CONTENT AREA (Constrained Width)
// ============================================================================

class _ContentArea extends StatelessWidget {
  final Widget child;
  
  const _ContentArea({required this.child});
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: context.responsive(
            mobile: double.infinity,
            tablet: 800.0,
            desktop: 1200.0,
            largeDesktop: 1400.0,
          ),
        ),
        child: child,
      ),
    );
  }
}

// ============================================================================
// 9. RESPONSIVE CARD LAYOUT
// ============================================================================

class ResponsiveCardLayout extends StatelessWidget {
  final List<Widget> children;
  final int mobileColumns;
  final int tabletColumns;
  final int desktopColumns;
  
  const ResponsiveCardLayout({
    super.key,
    required this.children,
    this.mobileColumns = 1,
    this.tabletColumns = 2,
    this.desktopColumns = 2,
  });
  
  @override
  Widget build(BuildContext context) {
    final columns = context.responsive(
      mobile: mobileColumns,
      tablet: tabletColumns,
      desktop: desktopColumns,
    );

    if (columns == 1) {
      return Column(
        children: children.map((child) {
          return Padding(
            padding: EdgeInsets.only(bottom: ResponsiveSpacing.medium(context)),
            child: child,
          );
        }).toList(),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final spacing = ResponsiveSpacing.medium(context);
        // Calculate item width based on available width in the parent
        final itemWidth = (width - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: children.map((child) {
            return SizedBox(
              width: itemWidth,
              child: child,
            );
          }).toList(),
        );
      },
    );
  }
}

// ============================================================================
// 10. RESPONSIVE TWO COLUMN LAYOUT
// ============================================================================

class ResponsiveTwoColumn extends StatelessWidget {
  final Widget left;
  final Widget right;
  final double spacing;
  
  const ResponsiveTwoColumn({
    super.key,
    required this.left,
    required this.right,
    this.spacing = 16.0,
  });
  
  @override
  Widget build(BuildContext context) {
    if (context.isMobile) {
      return Column(
        children: [
          left,
          SizedBox(height: spacing),
          right,
        ],
      );
    }
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        SizedBox(width: spacing),
        Expanded(child: right),
      ],
    );
  }
}

// ============================================================================
// 11. ADAPTIVE SCAFFOLD
// ============================================================================

class AdaptiveScaffold extends StatelessWidget {
  final String? title;
  final Widget body;
  final List<Widget>? actions;
  final FloatingActionButton? floatingActionButton;
  final Widget? bottomNavigationBar;
  final int? currentNavigationIndex;
  final ValueChanged<int>? onNavigationChanged;
  final bool showNavigationRail;
  
  const AdaptiveScaffold({
    super.key,
    this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.currentNavigationIndex,
    this.onNavigationChanged,
    this.showNavigationRail = true,
  });
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: title != null ? Text(title!) : null,
        actions: actions,
        elevation: 0,
      ),
      body: ResponsiveWrapper(
        showNavigationRail: showNavigationRail,
        currentIndex: currentNavigationIndex,
        onNavigationChanged: onNavigationChanged,
        child: body,
      ),
      floatingActionButton: floatingActionButton,
      // Only show bottom nav on mobile/tablet
      bottomNavigationBar: context.isDesktop ? null : bottomNavigationBar,
    );
  }
}
