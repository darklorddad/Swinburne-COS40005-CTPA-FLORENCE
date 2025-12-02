import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Added
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../shared/widgets/card_widgets.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/notification_bell.dart';
import '../../../../config/theme.dart';
import '../../../../config/routes.dart';
import '../../../../main.dart';
import '../widgets/biometrics_section.dart';
import '../widgets/quick_actions_grid.dart';
import '../widgets/ai_insight_card.dart';
import '../providers/dashboard_providers.dart'; // Added
import '../../profile/providers/user_profile_provider.dart'; // Ensure this is imported
import '../../core/models/health_data_models.dart';
import '../../core/providers/monitor_data_providers.dart' as core_data;

/// Home Dashboard Screen
/// Main hub showing health summary, quick actions, and insights
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  // Local state for welcome message only
  bool _hasShownWelcomeMessage = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Handle refresh
  Future<void> _handleRefresh() async {
    // Refresh BOTH providers in parallel for maximum efficiency
    await Future.wait([
      ref.refresh(core_data.monitorDataProvider.future),
      ref.refresh(userProfileProvider.future),
    ]);
  }

  /// Show quick log modal
  void _showQuickLogModal() {
    Helpers.showBottomSheet(context, child: _QuickLogModal());
  }

  @override
  Widget build(BuildContext context) {
    // 1. WATCH PROVIDERS (Triggers parallel fetch immediately on build)
    final healthDataState = ref.watch(core_data.monitorDataProvider).asData?.value;
    final userProfileAsync = ref.watch(userProfileProvider);
    
    // Derived values (will update automatically as healthDataState arrives)
    final activity = ref.watch(latestActivityProvider).asData?.value;
    final thresholds = ref.watch(patientThresholdsProvider).asData?.value ?? [];
    final mealLogs = ref.watch(dailyPatientLogsProvider).asData?.value ?? [];

    // Monitor Data now already includes meal glucose readings from the repository
    final combinedMonitorData = healthDataState?.allMonitorData ?? [];

    // Determine latest meal
    DailyPatientLog? latestMeal;
    if (mealLogs.isNotEmpty) {
      final sortedMeals = List<DailyPatientLog>.from(mealLogs);
      sortedMeals.sort((a, b) {
        final dateComp = a.logDate.compareTo(b.logDate);
        if (dateComp != 0) return dateComp;
        return _getMealTimePriority(a.mealTime).compareTo(_getMealTimePriority(b.mealTime));
      });
      latestMeal = sortedMeals.last;
    }
    
    // Define consistent spacing
    const double spacing = 20.0;

    return Scaffold(
      // Pass the profile provider to the AppBar
      appBar: _buildAppBar(context, userProfileAsync),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        edgeOffset: 0,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(spacing),
          children: [
            // AI Insight (Main Card)
            AIInsightCard(
              insight: 'Your glucose levels are most stable after morning walks. Consider a 15-minute walk after breakfast!',
              onTap: () => AppRoutes.push(context, AppRoutes.recommendations),
            ),
            const SizedBox(height: spacing),

            // Quick actions
            QuickActionsGrid(
              onLogGlucose: () => AppRoutes.push(context, AppRoutes.logGlucose),
              onLogBloodPressure: () => AppRoutes.push(context, AppRoutes.logBloodPressure),
              onLogMeal: () => AppRoutes.push(context, AppRoutes.logMeal),
              onLogActivity: () => AppRoutes.push(context, AppRoutes.logActivity),
            ),
            const SizedBox(height: spacing),

            // Biometrics Section (Loaded via Riverpod)
            BiometricsSection(
              monitorData: combinedMonitorData,
              latestActivity: activity,
              latestMeal: latestMeal,
              thresholds: thresholds,
            ),
            const SizedBox(height: spacing),
          ],
        ),
      ),
    );
  }


  /// Build app bar
  AppBar _buildAppBar(BuildContext context, AsyncValue<Map<String, dynamic>> userProfile) {
    final monitorDataAsync = ref.watch(monitorDataProvider);
    final isLoading = monitorDataAsync.isLoading || userProfile.isLoading;
    final borderColor = AppTheme.getBorderColor(context);

    // Safely extract name from profile provider
    final userName = userProfile.when(
      data: (data) => data['name'] ?? 'Florence',
      loading: () => '...',
      error: (_, __) => 'Florence',
    );

    return AppBar(
      title: InkWell(
        onTap: _handleRefresh,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userName == 'Florence' || userName == '...' ? 'Florence' : 'Hello, $userName',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (userName != 'Florence' && userName != '...')
                Text(
                  'Florence',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    letterSpacing: 0.5,
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: _showQuickLogModal,
          tooltip: 'Quick Log',
        ),
        const NotificationBell(),
        IconButton(
          icon: const Icon(Icons.chat_bubble_outline),
          onPressed: () => AppRoutes.push(context, AppRoutes.chat),
          tooltip: 'AI Health Assistant',
        ),
        IconButton(
          icon: const Icon(Icons.person_outline),
          onPressed: () => AppRoutes.push(context, AppRoutes.profile),
          tooltip: 'Profile',
        ),
      ],
      elevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(2.0),
        child: isLoading
            ? const LinearProgressIndicator(minHeight: 2.0)
            : Container(
                color: borderColor,
                height: 1.0,
              ),
      ),
    );
  }

  /// Build section header
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  int _getMealTimePriority(String time) {
    switch (time.toUpperCase()) {
      case 'BREAKFAST': return 1;
      case 'LUNCH': return 2;
      case 'DINNER': return 3;
      default: return 0;
    }
  }
}


/// Quick log modal
class _QuickLogModal extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            'Quick Log',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // Action buttons
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 3,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.9,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _QuickLogButton(
                icon: Icons.water_drop,
                label: 'Glucose',
                color: AppTheme.primaryRed,
                onTap: () {
                  Navigator.pop(context);
                  AppRoutes.push(context, AppRoutes.logGlucose);
                },
              ),
              _QuickLogButton(
                icon: Icons.restaurant,
                label: 'Meal',
                color: AppTheme.mealColor,
                onTap: () {
                  Navigator.pop(context);
                  AppRoutes.push(context, AppRoutes.logMeal);
                },
              ),
              _QuickLogButton(
                icon: Icons.percent,
                label: 'HbA1c',
                color: Colors.deepOrange, 
                onTap: () {
                  Navigator.pop(context);
                  // Make sure to add this route to your AppRoutes class
                  AppRoutes.push(context, AppRoutes.logHba1c); 
                },
              ),
              _QuickLogButton(
                icon: Icons.monitor_heart,
                label: 'Blood Pressure',
                color: AppTheme.primaryRed,
                onTap: () {
                  Navigator.pop(context);
                  AppRoutes.push(context, AppRoutes.logBloodPressure);
                },
              ),
              _QuickLogButton(
                icon: Icons.height,
                label: 'BMI',
                color: AppTheme.primaryGreen,
                onTap: () {
                  Navigator.pop(context);
                  AppRoutes.push(context, AppRoutes.logBmi);
                },
              ),
              _QuickLogButton(
                icon: Icons.directions_run,
                label: 'Activity',
                color: AppTheme.activityColor,
                onTap: () {
                  Navigator.pop(context);
                  AppRoutes.push(context, AppRoutes.logActivity);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Quick log button widget
class _QuickLogButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickLogButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}


