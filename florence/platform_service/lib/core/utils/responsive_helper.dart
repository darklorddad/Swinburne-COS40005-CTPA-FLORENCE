import 'package:flutter/material.dart';

/// Responsive Helper Utility
/// Provides methods and constants for responsive design across mobile, tablet, and desktop
class ResponsiveHelper {
  // ============================================
  // BREAKPOINT CONSTANTS
  // ============================================

  /// Mobile breakpoint (screens less than 600px width)
  static const double mobileBreakpoint = 600;

  /// Tablet breakpoint (screens between 600px and 1024px width)
  static const double tabletBreakpoint = 1024;

  /// Desktop breakpoint (screens greater than 1024px width)
  static const double desktopBreakpoint = 1024;

  // ============================================
  // DEVICE TYPE DETECTION
  // ============================================

  /// Check if current screen is mobile size
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  /// Check if current screen is tablet size
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  /// Check if current screen is desktop size
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }

  /// Get device type as string
  static String getDeviceType(BuildContext context) {
    if (isMobile(context)) return 'mobile';
    if (isTablet(context)) return 'tablet';
    return 'desktop';
  }

  // ============================================
  // RESPONSIVE SIZING
  // ============================================

  /// Get responsive padding based on device type
  /// - Mobile: 16px
  /// - Tablet: 24px
  /// - Desktop: 32px
  static double getResponsivePadding(BuildContext context) {
    if (isMobile(context)) return 16.0;
    if (isTablet(context)) return 24.0;
    return 32.0;
  }

  /// Get responsive horizontal padding
  static double getResponsiveHorizontalPadding(BuildContext context) {
    if (isMobile(context)) return 16.0;
    if (isTablet(context)) return 32.0;
    return 48.0;
  }

  /// Get responsive vertical padding
  static double getResponsiveVerticalPadding(BuildContext context) {
    if (isMobile(context)) return 16.0;
    if (isTablet(context)) return 24.0;
    return 32.0;
  }

  /// Get responsive chart height
  /// - Mobile: 300px
  /// - Tablet: 400px
  /// - Desktop: 500px
  static double getResponsiveChartHeight(BuildContext context) {
    if (isMobile(context)) return 300.0;
    if (isTablet(context)) return 400.0;
    return 500.0;
  }

  /// Get responsive card chart height (smaller charts in cards)
  /// - Mobile: 200px
  /// - Tablet: 250px
  /// - Desktop: 300px
  static double getResponsiveCardChartHeight(BuildContext context) {
    if (isMobile(context)) return 200.0;
    if (isTablet(context)) return 250.0;
    return 300.0;
  }

  /// Get responsive font size multiplier
  /// - Mobile: 1.0
  /// - Tablet: 1.1
  /// - Desktop: 1.2
  static double getFontSizeMultiplier(BuildContext context) {
    if (isMobile(context)) return 1.0;
    if (isTablet(context)) return 1.1;
    return 1.2;
  }

  /// Get responsive icon size
  /// - Mobile: 24px
  /// - Tablet: 28px
  /// - Desktop: 32px
  static double getResponsiveIconSize(BuildContext context) {
    if (isMobile(context)) return 24.0;
    if (isTablet(context)) return 28.0;
    return 32.0;
  }

  // ============================================
  // RESPONSIVE GRID
  // ============================================

  /// Get responsive grid column count
  /// - Mobile: 2 columns
  /// - Tablet: 3 columns
  /// - Desktop: 4 columns
  static int getResponsiveGridColumns(BuildContext context) {
    if (isMobile(context)) return 2;
    if (isTablet(context)) return 3;
    return 4;
  }

  /// Get responsive grid spacing
  /// - Mobile: 12px
  /// - Tablet: 16px
  /// - Desktop: 20px
  static double getResponsiveGridSpacing(BuildContext context) {
    if (isMobile(context)) return 12.0;
    if (isTablet(context)) return 16.0;
    return 20.0;
  }

  // ============================================
  // RESPONSIVE LAYOUT
  // ============================================

  /// Get responsive max content width (for centering content on large screens)
  /// - Mobile: Full width
  /// - Tablet: 800px
  /// - Desktop: 1200px
  static double getResponsiveMaxWidth(BuildContext context) {
    if (isMobile(context)) return double.infinity;
    if (isTablet(context)) return 800.0;
    return 1200.0;
  }

  /// Build responsive layout with different widgets for different screen sizes
  static Widget buildResponsiveLayout({
    required BuildContext context,
    required Widget mobile,
    Widget? tablet,
    Widget? desktop,
  }) {
    if (isDesktop(context) && desktop != null) {
      return desktop;
    }
    if (isTablet(context) && tablet != null) {
      return tablet;
    }
    return mobile;
  }

  /// Get responsive card elevation
  /// - Mobile: 0 (flat design)
  /// - Tablet: 2
  /// - Desktop: 4
  static double getResponsiveCardElevation(BuildContext context) {
    if (isMobile(context)) return 0.0;
    if (isTablet(context)) return 2.0;
    return 4.0;
  }

  /// Get responsive border radius
  /// - Mobile: 12px
  /// - Tablet: 16px
  /// - Desktop: 20px
  static double getResponsiveBorderRadius(BuildContext context) {
    if (isMobile(context)) return 12.0;
    if (isTablet(context)) return 16.0;
    return 20.0;
  }

  // ============================================
  // RESPONSIVE WIDGETS
  // ============================================

  /// Wrap content with responsive padding
  static Widget withResponsivePadding(BuildContext context, Widget child) {
    return Padding(
      padding: EdgeInsets.all(getResponsivePadding(context)),
      child: child,
    );
  }

  /// Wrap content with responsive horizontal padding
  static Widget withResponsiveHorizontalPadding(
    BuildContext context,
    Widget child,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: getResponsiveHorizontalPadding(context),
      ),
      child: child,
    );
  }

  /// Center content with max width on large screens
  static Widget centerWithMaxWidth(BuildContext context, Widget child) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: getResponsiveMaxWidth(context),
        ),
        child: child,
      ),
    );
  }

  // ============================================
  // ORIENTATION DETECTION
  // ============================================

  /// Check if device is in landscape orientation
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// Check if device is in portrait orientation
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  /// Get responsive columns based on orientation
  /// - Portrait: Use device-based columns
  /// - Landscape: Add 1 extra column
  static int getResponsiveColumnsWithOrientation(BuildContext context) {
    final baseColumns = getResponsiveGridColumns(context);
    return isLandscape(context) ? baseColumns + 1 : baseColumns;
  }

  // ============================================
  // SCREEN SIZE INFO
  // ============================================

  /// Get screen width
  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Get screen height
  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Get screen size as Size object
  static Size getScreenSize(BuildContext context) {
    return MediaQuery.of(context).size;
  }

  /// Get screen pixel ratio
  static double getPixelRatio(BuildContext context) {
    return MediaQuery.of(context).devicePixelRatio;
  }

  // ============================================
  // SAFE AREA
  // ============================================

  /// Get safe area padding
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }

  /// Get top safe area padding (for status bar)
  static double getTopSafeArea(BuildContext context) {
    return MediaQuery.of(context).padding.top;
  }

  /// Get bottom safe area padding (for navigation bar)
  static double getBottomSafeArea(BuildContext context) {
    return MediaQuery.of(context).padding.bottom;
  }

  // ============================================
  // UTILITY METHODS
  // ============================================

  /// Calculate responsive value based on screen width
  /// Linearly interpolates between mobile and desktop values
  static double responsiveValue(
    BuildContext context, {
    required double mobile,
    required double tablet,
    required double desktop,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  /// Scale a value based on screen width
  /// Useful for custom sizing that should grow with screen size
  static double scaleValue(BuildContext context, double baseValue) {
    final screenWidth = getScreenWidth(context);
    final scaleFactor = screenWidth / 375; // 375 is iPhone X width (base)
    return baseValue * scaleFactor;
  }

  /// Get responsive spacing between elements
  /// - Mobile: 8px
  /// - Tablet: 12px
  /// - Desktop: 16px
  static double getResponsiveSpacing(BuildContext context) {
    if (isMobile(context)) return 8.0;
    if (isTablet(context)) return 12.0;
    return 16.0;
  }

  /// Get responsive large spacing between sections
  /// - Mobile: 16px
  /// - Tablet: 24px
  /// - Desktop: 32px
  static double getResponsiveLargeSpacing(BuildContext context) {
    if (isMobile(context)) return 16.0;
    if (isTablet(context)) return 24.0;
    return 32.0;
  }
}
